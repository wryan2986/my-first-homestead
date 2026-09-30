class_name DuckPondPlay
extends Node2D

@export var tap_area: NodePath
@export var pond_visual: NodePath
@export var food_visual: NodePath
@export var feedback_label: NodePath
@export var duck_nodes: Array[NodePath] = []
@export var idle_texture: Texture2D
@export var eating_texture: Texture2D
@export var feed_sound: AudioStream
@export var pond_bounds := Rect2(-100.0, -44.0, 200.0, 88.0)
@export var food_target_bounds := Rect2(-70.0, -18.0, 140.0, 48.0)
@export var duck_bounds_inset := Vector2(22.0, 17.0)
@export var swim_duration := 1.1
@export var eat_duration := 0.8
@export var idle_swim_speed := 16.0
@export var idle_pause_range := Vector2(0.7, 1.8)
@export var tap_margin := 16.0
@export var snack_goal := 3

@onready var _tap_area: Area2D = get_node_or_null(tap_area) as Area2D
@onready var _pond_visual: CanvasItem = get_node_or_null(pond_visual) as CanvasItem
@onready var _food_visual: Node2D = get_node_or_null(food_visual) as Node2D
@onready var _feedback_label: Label = get_node_or_null(feedback_label) as Label

var _duck_sprites: Array[Sprite2D] = []
var _home_positions: Array[Vector2] = []
var _idle_targets: Array[Vector2] = []
var _idle_pauses: Array[float] = []
var _rng := RandomNumberGenerator.new()
var _busy := false
var _enabled := false
var _winter_resting := false
var _snacks_given := 0


func _ready() -> void:
	_rng.seed = int(Time.get_ticks_usec()) + get_instance_id()
	_cache_ducks()
	FarmFeedback.hide_play_scene_text(self)
	if _tap_area != null:
		_tap_area.input_pickable = false
		_tap_area.input_event.connect(_on_tap_area_input_event)
	if _food_visual != null:
		_food_visual.visible = false
	_apply_visibility()
	set_process(false)


func _process(delta: float) -> void:
	if not _enabled or _winter_resting or _busy:
		return
	_update_idle_swim(delta)


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled:
		_reset_ducks()
	_apply_visibility()


func set_winter_resting(resting: bool) -> void:
	_winter_resting = resting
	if resting:
		_reset_ducks()
	_apply_visibility()


func try_handle_tap(event: InputEvent) -> bool:
	if not _enabled or not _is_press_event(event):
		return false
	var local_target := _event_to_local_position(event)
	if not _expanded_pond_bounds().has_point(local_target):
		return false
	get_viewport().set_input_as_handled()
	if _winter_resting:
		FarmFeedback.flash_label(_feedback_label, "The ducks are cozy today.", Color("e1f6ff"), 0.9)
		return true
	if _busy:
		return true
	_feed_at_local_position(_clamp_to_food_target(local_target))
	return true


func _on_tap_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	try_handle_tap(event)


func _feed_at_local_position(local_target: Vector2) -> void:
	_busy = true
	_snacks_given += 1
	if _food_visual != null:
		_food_visual.position = local_target
		_food_visual.visible = true
		FarmFeedback.pulse(_food_visual, 1.22, 0.1)
	FarmFeedback.play_one_shot(self, feed_sound, -9.0)
	if _snacks_given >= snack_goal:
		FarmFeedback.flash_label(_feedback_label, "The ducks loved their snack!", Color("e8ffd1"), 1.0)
		_snacks_given = 0
	_swim_ducks_to_food(local_target)


func _swim_ducks_to_food(local_target: Vector2) -> void:
	var offsets: Array[Vector2] = [
		Vector2(-32.0, 12.0),
		Vector2(0.0, -13.0),
		Vector2(32.0, 12.0),
	]
	for index in _duck_sprites.size():
		var duck := _duck_sprites[index]
		if duck == null or not is_instance_valid(duck):
			continue
		var target := _clamp_duck_to_pond(local_target + offsets[index % offsets.size()])
		duck.flip_h = target.x < duck.position.x
		var tween := duck.create_tween()
		tween.tween_property(duck, "position", target, swim_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(func() -> void:
			if is_instance_valid(duck) and eating_texture != null:
				duck.texture = eating_texture
		)

	get_tree().create_timer(swim_duration + eat_duration).timeout.connect(_return_ducks_home)


func _return_ducks_home() -> void:
	if _food_visual != null:
		_food_visual.visible = false
	for index in _duck_sprites.size():
		var duck := _duck_sprites[index]
		if duck == null or not is_instance_valid(duck):
			continue
		if idle_texture != null:
			duck.texture = idle_texture
		var home_position := _clamp_duck_to_pond(_home_positions[index])
		duck.flip_h = home_position.x < duck.position.x
		var tween := duck.create_tween()
		tween.tween_property(duck, "position", home_position, swim_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	get_tree().create_timer(swim_duration).timeout.connect(func() -> void:
		_reset_idle_targets()
		_busy = false
	)


func _cache_ducks() -> void:
	_duck_sprites.clear()
	_home_positions.clear()
	_idle_targets.clear()
	_idle_pauses.clear()
	for path in duck_nodes:
		var duck := get_node_or_null(path) as Sprite2D
		if duck == null:
			continue
		duck.position = _clamp_duck_to_pond(duck.position)
		if idle_texture != null:
			duck.texture = idle_texture
		_duck_sprites.append(duck)
		_home_positions.append(duck.position)
		_idle_targets.append(_random_point_near(duck.position))
		_idle_pauses.append(_random_pause())


func _reset_ducks() -> void:
	_busy = false
	if _food_visual != null:
		_food_visual.visible = false
	for index in _duck_sprites.size():
		var duck := _duck_sprites[index]
		if duck == null or not is_instance_valid(duck):
			continue
		duck.position = _home_positions[index]
		if idle_texture != null:
			duck.texture = idle_texture
	_reset_idle_targets()


func _apply_visibility() -> void:
	visible = _enabled
	set_process(_enabled and not _winter_resting)
	if _tap_area != null:
		_tap_area.input_pickable = _enabled
	if _pond_visual != null:
		_pond_visual.visible = _enabled
	for duck in _duck_sprites:
		if duck != null and is_instance_valid(duck):
			duck.visible = _enabled


func _update_idle_swim(delta: float) -> void:
	for index in _duck_sprites.size():
		var duck := _duck_sprites[index]
		if duck == null or not is_instance_valid(duck):
			continue
		var bob := sin(float(Time.get_ticks_msec()) / 390.0 + float(index) * 1.3) * 1.9
		duck.position.y += bob * delta
		if _idle_pauses[index] > 0.0:
			_idle_pauses[index] -= delta
			duck.position = _clamp_duck_to_pond(duck.position)
			continue
		var target := _idle_targets[index]
		duck.flip_h = target.x < duck.position.x
		duck.position = _clamp_duck_to_pond(duck.position.move_toward(target, idle_swim_speed * delta))
		if duck.position.distance_to(target) <= 2.0:
			_idle_pauses[index] = _random_pause()
			_idle_targets[index] = _random_point_near(_home_positions[index])


func _reset_idle_targets() -> void:
	for index in _duck_sprites.size():
		if index < _idle_targets.size():
			_idle_targets[index] = _random_point_near(_home_positions[index])
		if index < _idle_pauses.size():
			_idle_pauses[index] = _random_pause()


func _random_point_near(anchor: Vector2) -> Vector2:
	return _clamp_duck_to_pond(anchor + Vector2(_rng.randf_range(-38.0, 38.0), _rng.randf_range(-15.0, 15.0)))


func _random_pause() -> float:
	return _rng.randf_range(minf(idle_pause_range.x, idle_pause_range.y), maxf(idle_pause_range.x, idle_pause_range.y))


func _clamp_to_food_target(point: Vector2) -> Vector2:
	var bounds_end := food_target_bounds.position + food_target_bounds.size
	return Vector2(
		clampf(point.x, food_target_bounds.position.x, bounds_end.x),
		clampf(point.y, food_target_bounds.position.y, bounds_end.y)
	)


func _expanded_pond_bounds() -> Rect2:
	return pond_bounds.grow(tap_margin)


func _is_press_event(event: InputEvent) -> bool:
	return (
		(event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	)


func _event_to_local_position(event: InputEvent) -> Vector2:
	var viewport_position := Vector2.INF
	if event is InputEventMouseButton:
		viewport_position = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch:
		viewport_position = (event as InputEventScreenTouch).position
	if viewport_position == Vector2.INF:
		return Vector2.ZERO
	var world_position := get_canvas_transform().affine_inverse() * viewport_position
	return to_local(world_position)


func _clamp_duck_to_pond(point: Vector2) -> Vector2:
	var inset_x := minf(duck_bounds_inset.x, pond_bounds.size.x * 0.45)
	var inset_y := minf(duck_bounds_inset.y, pond_bounds.size.y * 0.45)
	var bounds := Rect2(pond_bounds.position + Vector2(inset_x, inset_y), pond_bounds.size - Vector2(inset_x * 2.0, inset_y * 2.0))
	var bounds_end := bounds.position + bounds.size
	return Vector2(
		clampf(point.x, bounds.position.x, bounds_end.x - 0.001),
		clampf(point.y, bounds.position.y, bounds_end.y - 0.001)
	)
