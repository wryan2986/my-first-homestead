extends Node2D

@export_file("*.tscn") var farmyard_scene_path := "res://scenes/FarmyardScene.tscn"
@export var background_sprite: NodePath
@export var back_button: NodePath
@export var feedback_label: NodePath
@export var duck_nodes: Array[NodePath] = []
@export var lily_pad_nodes: Array[NodePath] = []
@export var note_effect_texture: Texture2D
@export var lily_pad_note_colors: Array[Color] = []
@export var food_texture: Texture2D
@export var fish_texture: Texture2D
@export var feed_sound: AudioStream
@export var quack_sound: AudioStream
@export var spring_background_texture: Texture2D
@export var summer_background_texture: Texture2D
@export var fall_background_texture: Texture2D
@export var winter_background_texture: Texture2D
@export var tap_goal := 6
@export var time_limit_seconds := 120.0
@export var fish_steal_chance := 0.35
@export var fish_steal_guarantee_after_feeds := 5
@export var water_bounds := Rect2(220.0, 420.0, 1480.0, 520.0)
@export var water_food_margin := 70.0

@onready var _background_sprite: Sprite2D = get_node_or_null(background_sprite) as Sprite2D
@onready var _back_button: Button = get_node_or_null(back_button) as Button
@onready var _feedback_label: Label = get_node_or_null(feedback_label) as Label

var _ducks: Array[Sprite2D] = []
var _lily_pads: Array[Area2D] = []
var _tap_count := 0
var _current_duck_target := 0
var _busy := false
var _rng := RandomNumberGenerator.new()
var _timeout_timer: SceneTreeTimer
var _feeds_since_fish_steal := 0
var _time_limit_run_id := 0
var _farm_state: Node
var _game_settings: Node


func _ready() -> void:
	if _is_scene_navigator_cache_prepare():
		return
	_farm_state = get_node_or_null("/root/FarmState")
	_game_settings = get_node_or_null("/root/GameSettings")
	_tap_count = 0
	_busy = false
	_feeds_since_fish_steal = 0
	if _farm_state != null:
		_farm_state.call("mark_duck_pond_visited_today")
	_rng.seed = int(Time.get_ticks_usec()) + get_instance_id()
	_apply_seasonal_background()
	if _back_button != null and not _back_button.pressed.is_connected(_return_to_farmyard):
		_back_button.pressed.connect(_return_to_farmyard)
	_cache_ducks()
	_cache_lily_pads()
	_start_time_limit_if_enabled()
	FarmFeedback.hide_play_scene_text(self)


func prepare_for_cached_scene() -> void:
	pass


func activate_from_cache() -> void:
	_ready()


func deactivate_for_cache_or_free() -> void:
	_time_limit_run_id += 1
	_timeout_timer = null


func _is_scene_navigator_cache_prepare() -> bool:
	return has_meta("_scene_navigator_cache_prepare")


func _apply_seasonal_background() -> void:
	if _background_sprite == null:
		return
	var texture := _get_seasonal_background_texture()
	if texture != null:
		_background_sprite.texture = texture
	if _background_sprite.has_method("apply_cover"):
		_background_sprite.call("apply_cover")


func _get_seasonal_background_texture() -> Texture2D:
	var current_season := String(_farm_state.get("current_season")) if _farm_state != null else "summer"
	match current_season:
		"spring":
			return spring_background_texture
		"summer":
			return summer_background_texture
		"fall":
			return fall_background_texture
		"winter":
			return winter_background_texture
		_:
			return summer_background_texture


func _unhandled_input(event: InputEvent) -> void:
	if not _is_press_event(event):
		return
	var tap_position := _event_position(event)
	if tap_position == Vector2.INF:
		return
	var lily_pad := _get_lily_pad_at_position(tap_position)
	if lily_pad != null:
		get_viewport().set_input_as_handled()
		_play_pad(lily_pad)
		return
	var duck := _get_duck_at_position(tap_position)
	if duck != null:
		get_viewport().set_input_as_handled()
		_play_duck_quack(duck)
		return
	if water_bounds.has_point(tap_position):
		get_viewport().set_input_as_handled()
		_drop_food_at(tap_position)


func _cache_ducks() -> void:
	_ducks.clear()
	for path in duck_nodes:
		var duck := get_node_or_null(path) as Sprite2D
		if duck != null:
			_ducks.append(duck)


func _cache_lily_pads() -> void:
	_lily_pads.clear()
	for path in lily_pad_nodes:
		var pad := get_node_or_null(path) as Area2D
		if pad == null:
			continue
		_lily_pads.append(pad)
		var callable := _on_lily_pad_input_event.bind(pad)
		if not pad.input_event.is_connected(callable):
			pad.input_event.connect(callable)


func _on_lily_pad_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, pad: Area2D) -> void:
	if not _is_press_event(event):
		return
	get_viewport().set_input_as_handled()
	_play_pad(pad)


func _play_pad(pad: Area2D) -> void:
	if _busy:
		return
	_tap_count += 1
	var lily_pad_index := _get_lily_pad_index(pad)
	var pad_sprite := pad.get_node_or_null("Sprite") as Sprite2D
	if pad_sprite != null:
		FarmFeedback.pulse(pad_sprite, 1.08, 0.12)
	FarmFeedback.spawn_note_shape(self, note_effect_texture, pad.global_position + Vector2(0.0, -58.0), lily_pad_index, _get_lily_pad_note_color(lily_pad_index), Vector2(1.68, 1.68), Vector2(0.0, -76.0), 25, 0.9)
	_play_pad_sound(pad)
	_move_ducks_to_pad(pad.global_position)
	if _tap_count >= tap_goal:
		_tap_count = 0
		FarmFeedback.flash_label(_feedback_label, "Duck pond music!", Color("fff2b3"), 1.2)
		FarmFeedback.celebrate(self, pad.global_position + Vector2(0.0, -64.0), 10)
	else:
		FarmFeedback.flash_label(_feedback_label, "Soft music!", Color("e8ffd1"), 0.65)


func _play_pad_sound(pad: Area2D) -> void:
	var player := pad.get_node_or_null("NoteSound") as AudioStreamPlayer
	if player == null:
		return
	player.stop()
	player.play()


func _get_lily_pad_index(pad: Area2D) -> int:
	for index in _lily_pads.size():
		if _lily_pads[index] == pad:
			return index
	return 0


func _get_lily_pad_note_color(lily_pad_index: int) -> Color:
	if lily_pad_index >= 0 and lily_pad_index < lily_pad_note_colors.size():
		return lily_pad_note_colors[lily_pad_index]
	return Color.WHITE


func _move_ducks_to_pad(target: Vector2) -> void:
	if _ducks.is_empty():
		return
	var offsets: Array[Vector2] = [
		Vector2(-76.0, 40.0),
		Vector2(0.0, 66.0),
		Vector2(76.0, 40.0),
	]
	for index in _ducks.size():
		var duck := _ducks[index]
		if duck == null or not is_instance_valid(duck):
			continue
		var target_position := target + offsets[index % offsets.size()]
		duck.flip_h = target_position.x < duck.global_position.x
		var tween := duck.create_tween()
		tween.tween_property(duck, "global_position", target_position, 0.8 + float(index) * 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(duck, "rotation", 0.08 if index % 2 == 0 else -0.08, 0.25)
		tween.tween_property(duck, "rotation", 0.0, 0.25)


func _play_duck_quack(duck: Sprite2D) -> void:
	FarmFeedback.play_one_shot(self, quack_sound, -7.0)
	FarmFeedback.pulse(duck, 1.12, 0.1)
	var start_y := duck.global_position.y
	var tween := duck.create_tween()
	tween.tween_property(duck, "global_position:y", start_y - 18.0, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(duck, "global_position:y", start_y, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _drop_food_at(position: Vector2) -> void:
	if _busy or food_texture == null:
		return
	_busy = true
	var food_position := _clamp_food_position(position)
	var food := Sprite2D.new()
	food.texture = food_texture
	food.global_position = food_position
	food.scale = Vector2(0.34, 0.34)
	food.z_index = 12
	add_child(food)
	FarmFeedback.pulse(food, 1.2, 0.1)
	FarmFeedback.play_one_shot(self, feed_sound, -9.0)
	var guarantee_count := maxi(1, fish_steal_guarantee_after_feeds)
	var should_steal := _feeds_since_fish_steal >= guarantee_count or _rng.randf() < clampf(fish_steal_chance, 0.0, 1.0)
	if should_steal:
		_feeds_since_fish_steal = 0
		_play_fish_steal(food, food_position)
	else:
		_feeds_since_fish_steal += 1
		_swim_ducks_to_food(food, food_position)


func _play_fish_steal(food: Sprite2D, food_position: Vector2) -> void:
	if fish_texture == null:
		_swim_ducks_to_food(food, food_position)
		return
	var fish := Sprite2D.new()
	fish.texture = fish_texture
	fish.global_position = food_position + Vector2(-70.0, 36.0)
	fish.scale = Vector2(0.22, 0.22)
	fish.modulate.a = 0.0
	fish.z_index = 11
	add_child(fish)
	var end_position := food_position + Vector2(76.0, 34.0)
	fish.flip_h = end_position.x < fish.global_position.x
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fish, "modulate:a", 1.0, 0.14)
	tween.tween_property(fish, "global_position", food_position + Vector2(-8.0, 14.0), 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(food, "scale", Vector2(0.22, 0.22), 0.34)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		if is_instance_valid(food):
			food.visible = false
		FarmFeedback.pulse(fish, 1.14, 0.08)
	)
	tween.set_parallel(true)
	tween.tween_property(fish, "global_position", end_position, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(fish, "modulate:a", 0.0, 0.4)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		if is_instance_valid(food):
			food.queue_free()
		if is_instance_valid(fish):
			fish.queue_free()
		_busy = false
	)


func _swim_ducks_to_food(food: Sprite2D, food_position: Vector2) -> void:
	var offsets: Array[Vector2] = [
		Vector2(-82.0, 52.0),
		Vector2(0.0, 70.0),
		Vector2(82.0, 52.0),
	]
	for index in _ducks.size():
		var duck := _ducks[index]
		if duck == null or not is_instance_valid(duck):
			continue
		var target_position := _clamp_food_position(food_position + offsets[index % offsets.size()])
		duck.flip_h = target_position.x < duck.global_position.x
		var tween := duck.create_tween()
		tween.tween_property(duck, "global_position", target_position, 0.85 + float(index) * 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(duck, "rotation", 0.07 if index % 2 == 0 else -0.07, 0.22)
		tween.tween_property(duck, "rotation", 0.0, 0.22)
	var timer := get_tree().create_timer(1.1)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(food):
			var fade := food.create_tween()
			fade.tween_property(food, "modulate:a", 0.0, 0.22)
			fade.tween_callback(food.queue_free)
		_busy = false
	)


func _start_time_limit_if_enabled() -> void:
	if _game_settings == null or not bool(_game_settings.call("is_duck_pond_time_limit_enabled")):
		return
	_time_limit_run_id += 1
	var run_id := _time_limit_run_id
	var time_limit_seconds := float(_game_settings.call("get_duck_pond_time_limit_seconds"))
	_timeout_timer = get_tree().create_timer(maxf(1.0, time_limit_seconds), false)
	_timeout_timer.timeout.connect(func() -> void:
		if run_id == _time_limit_run_id and is_inside_tree() and visible:
			if _farm_state != null:
				_farm_state.call("mark_duck_pond_visited_today")
			_return_to_farmyard()
	)


func _return_to_farmyard() -> void:
	if _farm_state != null:
		_farm_state.call("mark_duck_pond_visited_today")
	ChoreCompletionFlow.return_to_farmyard(self, farmyard_scene_path)


func _is_press_event(event: InputEvent) -> bool:
	return (
		(event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	)


func _event_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	return Vector2.INF


func _get_duck_at_position(position: Vector2) -> Sprite2D:
	for duck in _ducks:
		if duck == null or not is_instance_valid(duck) or not duck.visible:
			continue
		if duck.global_position.distance_to(position) <= 92.0:
			return duck
	return null


func _get_lily_pad_at_position(position: Vector2) -> Area2D:
	for pad in _lily_pads:
		if pad == null or not is_instance_valid(pad) or not pad.visible:
			continue
		var shape := pad.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape != null and shape.shape is CircleShape2D:
			var radius := (shape.shape as CircleShape2D).radius * maxf(absf(pad.global_scale.x), absf(pad.global_scale.y))
			if pad.global_position.distance_to(position) <= radius:
				return pad
		elif pad.global_position.distance_to(position) <= 94.0:
			return pad
	return null


func _clamp_food_position(position: Vector2) -> Vector2:
	var min_position := water_bounds.position + Vector2(water_food_margin, water_food_margin)
	var max_position := water_bounds.position + water_bounds.size - Vector2(water_food_margin, water_food_margin)
	return Vector2(
		clampf(position.x, min_position.x, max_position.x),
		clampf(position.y, min_position.y, max_position.y)
	)
