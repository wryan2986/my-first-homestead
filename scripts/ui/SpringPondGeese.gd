class_name SpringPondGeese
extends Node2D

@export var tap_area: NodePath
@export var pond_visual: NodePath
@export var food_visual: NodePath
@export var goose_nodes: Array[NodePath] = []
@export var idle_texture: Texture2D
@export var eating_texture: Texture2D
@export var feed_sound: AudioStream
@export var pond_bounds := Rect2(-155.0, -65.0, 310.0, 130.0)
@export var food_target_bounds := Rect2(-125.0, 24.0, 250.0, 78.0)
@export var goose_bounds_inset := Vector2(28.0, 18.0)
@export var swim_duration := 1.35
@export var eat_duration := 1.0
@export var idle_swim_speed := 18.0
@export var idle_pause_range := Vector2(0.8, 2.2)
@export var tap_margin := 34.0

@onready var _tap_area: Area2D = get_node_or_null(tap_area) as Area2D
@onready var _pond_visual: CanvasItem = get_node_or_null(pond_visual) as CanvasItem
@onready var _food_visual: Node2D = get_node_or_null(food_visual) as Node2D

var _goose_sprites: Array[Sprite2D] = []
var _home_positions: Array[Vector2] = []
var _idle_targets: Array[Vector2] = []
var _idle_pauses: Array[float] = []
var _rng := RandomNumberGenerator.new()
var _busy := false
var _enabled := false
var _pond_visible := true


func _ready() -> void:
	_rng.seed = int(Time.get_ticks_usec()) + get_instance_id()
	_cache_geese()
	if _tap_area != null:
		_tap_area.input_pickable = visible
		_tap_area.input_event.connect(_on_tap_area_input_event)
	if _food_visual != null:
		_food_visual.visible = false
	_apply_visibility()


func _process(delta: float) -> void:
	if not _enabled or _busy:
		return
	_update_idle_swim(delta)


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	set_process(enabled)
	if _tap_area != null:
		_tap_area.input_pickable = enabled
	if not enabled:
		_reset_geese()
	_apply_visibility()


func set_pond_visible(pond_should_show: bool) -> void:
	_pond_visible = pond_should_show
	_apply_visibility()


func try_handle_tap(event: InputEvent) -> bool:
	if not _enabled or not _is_press_event(event):
		return false
	var local_target := _event_to_local_position(event)
	if not _expanded_pond_bounds().has_point(local_target):
		return false
	get_viewport().set_input_as_handled()
	if _busy:
		return true
	_feed_at_local_position(_clamp_to_food_target(local_target))
	return true


func _on_tap_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not _enabled:
		return
	if event is InputEventScreenTouch and event.pressed:
		if _busy:
			get_viewport().set_input_as_handled()
			return
		_feed_at_event(event)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _busy:
			get_viewport().set_input_as_handled()
			return
		_feed_at_event(event)


func _feed_at_event(event: InputEvent) -> void:
	_feed_at_local_position(_clamp_to_food_target(_event_to_local_position(event)))


func _feed_at_local_position(local_target: Vector2) -> void:
	get_viewport().set_input_as_handled()
	_busy = true
	if _food_visual != null:
		_food_visual.position = local_target
		_food_visual.visible = true
		FarmFeedback.pulse(_food_visual, 1.18, 0.1)
	FarmFeedback.play_one_shot(self, feed_sound, -8.0)
	_swim_geese_to_food(local_target)


func _swim_geese_to_food(local_target: Vector2) -> void:
	var offsets: Array[Vector2] = [
		Vector2(-42.0, 18.0),
		Vector2(0.0, -18.0),
		Vector2(42.0, 18.0),
	]
	var longest_delay := 0.0
	for index in _goose_sprites.size():
		var goose := _goose_sprites[index]
		if goose == null or not is_instance_valid(goose):
			continue
		var target := _clamp_to_goose_feeding_target(local_target + offsets[index % offsets.size()])
		goose.flip_h = target.x < goose.position.x
		var tween := goose.create_tween()
		tween.tween_property(goose, "position", target, swim_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(func() -> void:
			if is_instance_valid(goose) and eating_texture != null:
				goose.texture = eating_texture
		)
		longest_delay = maxf(longest_delay, swim_duration)

	var timer := get_tree().create_timer(longest_delay + eat_duration)
	timer.timeout.connect(_return_geese_home)


func _return_geese_home() -> void:
	if _food_visual != null:
		_food_visual.visible = false
	for index in _goose_sprites.size():
		var goose := _goose_sprites[index]
		if goose == null or not is_instance_valid(goose):
			continue
		if idle_texture != null:
			goose.texture = idle_texture
		var home_position := _clamp_goose_to_pond(_home_positions[index])
		goose.flip_h = home_position.x < goose.position.x
		var tween := goose.create_tween()
		tween.tween_property(goose, "position", home_position, swim_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var timer := get_tree().create_timer(swim_duration)
	timer.timeout.connect(func() -> void:
		_reset_idle_targets()
		_busy = false
	)


func _reset_geese() -> void:
	_busy = false
	if _food_visual != null:
		_food_visual.visible = false
	for index in _goose_sprites.size():
		var goose := _goose_sprites[index]
		if goose == null or not is_instance_valid(goose):
			continue
		goose.position = _home_positions[index]
		if idle_texture != null:
			goose.texture = idle_texture
	_reset_idle_targets()
	_apply_visibility()


func _cache_geese() -> void:
	_goose_sprites.clear()
	_home_positions.clear()
	_idle_targets.clear()
	_idle_pauses.clear()
	for path in goose_nodes:
		var goose := get_node_or_null(path) as Sprite2D
		if goose == null:
			continue
		goose.position = _clamp_goose_to_pond(goose.position)
		_goose_sprites.append(goose)
		_home_positions.append(goose.position)
		_idle_targets.append(_random_point_near(goose.position))
		_idle_pauses.append(_random_pause())
		if idle_texture != null:
			goose.texture = idle_texture


func _apply_visibility() -> void:
	visible = _enabled or _pond_visible
	if _pond_visual != null:
		_pond_visual.visible = _pond_visible
	for goose in _goose_sprites:
		if goose != null and is_instance_valid(goose):
			goose.visible = _enabled


func _update_idle_swim(delta: float) -> void:
	for index in _goose_sprites.size():
		var goose := _goose_sprites[index]
		if goose == null or not is_instance_valid(goose):
			continue

		var bob := sin(float(Time.get_ticks_msec()) / 430.0 + float(index) * 1.7) * 2.2
		goose.position.y += bob * delta

		if _idle_pauses[index] > 0.0:
			_idle_pauses[index] -= delta
			goose.position = _clamp_goose_to_pond(goose.position)
			continue

		var target := _idle_targets[index]
		goose.flip_h = target.x < goose.position.x
		goose.position = _clamp_goose_to_pond(goose.position.move_toward(target, idle_swim_speed * delta))
		if goose.position.distance_to(target) <= 2.0:
			_idle_pauses[index] = _random_pause()
			_idle_targets[index] = _random_point_near(_home_positions[index])


func _reset_idle_targets() -> void:
	for index in _goose_sprites.size():
		if index < _idle_targets.size():
			_idle_targets[index] = _random_point_near(_home_positions[index])
		if index < _idle_pauses.size():
			_idle_pauses[index] = _random_pause()


func _random_point_near(anchor: Vector2) -> Vector2:
	var offset := Vector2(
		_rng.randf_range(-48.0, 48.0),
		_rng.randf_range(-22.0, 22.0)
	)
	return _clamp_goose_to_pond(anchor + offset)


func _random_pause() -> float:
	return _rng.randf_range(minf(idle_pause_range.x, idle_pause_range.y), maxf(idle_pause_range.x, idle_pause_range.y))


func _random_point_in_pond() -> Vector2:
	var bounds := _goose_swim_bounds()
	var bounds_end := bounds.position + bounds.size
	return Vector2(
		_rng.randf_range(bounds.position.x, bounds_end.x),
		_rng.randf_range(bounds.position.y, bounds_end.y)
	)


func _clamp_to_food_target(point: Vector2) -> Vector2:
	var bounds_end := food_target_bounds.position + food_target_bounds.size
	return Vector2(
		clampf(point.x, food_target_bounds.position.x, bounds_end.x),
		clampf(point.y, food_target_bounds.position.y, bounds_end.y)
	)


func _clamp_to_goose_feeding_target(point: Vector2) -> Vector2:
	var bounds := food_target_bounds.grow(34.0)
	var bounds_end := bounds.position + bounds.size
	return _clamp_goose_to_pond(Vector2(
		clampf(point.x, bounds.position.x, bounds_end.x),
		clampf(point.y, bounds.position.y, bounds_end.y)
	))


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


func _clamp_to_pond(point: Vector2) -> Vector2:
	var bounds_end := pond_bounds.position + pond_bounds.size
	return Vector2(
		clampf(point.x, pond_bounds.position.x, bounds_end.x),
		clampf(point.y, pond_bounds.position.y, bounds_end.y)
	)


func _clamp_goose_to_pond(point: Vector2) -> Vector2:
	var bounds := _goose_swim_bounds()
	var bounds_end := bounds.position + bounds.size
	return Vector2(
		clampf(point.x, bounds.position.x, bounds_end.x - 0.001),
		clampf(point.y, bounds.position.y, bounds_end.y - 0.001)
	)


func _goose_swim_bounds() -> Rect2:
	var inset_x := minf(goose_bounds_inset.x, pond_bounds.size.x * 0.45)
	var inset_y := minf(goose_bounds_inset.y, pond_bounds.size.y * 0.45)
	return Rect2(
		pond_bounds.position + Vector2(inset_x, inset_y),
		pond_bounds.size - Vector2(inset_x * 2.0, inset_y * 2.0)
	)
