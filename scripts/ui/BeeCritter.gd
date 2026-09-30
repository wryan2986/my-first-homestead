class_name BeeCritter
extends Area2D

@export var icon_sprite: NodePath
@export var sprite_faces_left := true
@export var movement_bounds := Rect2(0.0, 0.0, 160.0, 90.0)
@export var move_speed := 38.0
@export var idle_duration_range := Vector2(0.3, 1.0)
@export var foreground_enabled := false
@export var foreground_position := Vector2(920.0, 720.0)
@export var foreground_interval_range := Vector2(8.0, 15.0)
@export var foreground_stay_duration := 2.2
@export var foreground_scale_multiplier := 1.6
@export var buzz_sound: AudioStream
@export var buzz_volume_db := -9.0

@onready var _icon_sprite: Sprite2D = get_node_or_null(icon_sprite) as Sprite2D

var _rng := RandomNumberGenerator.new()
var _target_position := Vector2.ZERO
var _idle_time_left := 0.0
var _home_scale := Vector2.ONE
var _target_scale := Vector2.ONE
var _foreground_time_left := 0.0
var _foreground_stay_left := 0.0
var _foreground_state := 0


func _ready() -> void:
	input_pickable = true
	_rng.seed = int(Time.get_ticks_usec()) + get_instance_id()
	_home_scale = scale
	_target_scale = _home_scale
	position = _clamp_to_bounds(position)
	_target_position = _random_point_in_bounds()
	_idle_time_left = _random_range(idle_duration_range)
	_foreground_time_left = _random_range(foreground_interval_range)


func _process(delta: float) -> void:
	_update_foreground_visit(delta)
	_update_wander(delta)
	_update_visual_buzz(delta)


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		handle_tap()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_tap()


func handle_tap() -> void:
	get_viewport().set_input_as_handled()
	FarmFeedback.play_one_shot(self, buzz_sound, buzz_volume_db)
	FarmFeedback.pulse(self, 1.16, 0.1)
	FarmFeedback.bounce(self, 18.0, 0.09)


func _update_wander(delta: float) -> void:
	if _foreground_state == 2:
		scale = scale.lerp(_target_scale, minf(1.0, delta * 2.8))
		return

	if _idle_time_left > 0.0:
		_idle_time_left -= delta
		return

	var distance_this_frame := move_speed * delta
	position = position.move_toward(_target_position, distance_this_frame)
	scale = scale.lerp(_target_scale, minf(1.0, delta * 2.8))
	if _icon_sprite != null:
		var moving_left := _target_position.x < position.x
		_icon_sprite.flip_h = moving_left != sprite_faces_left

	if position.distance_to(_target_position) <= 2.0:
		_on_target_reached()


func _update_foreground_visit(delta: float) -> void:
	if not foreground_enabled:
		return

	if _foreground_state == 0:
		_foreground_time_left -= delta
		if _foreground_time_left <= 0.0:
			_foreground_state = 1
			_target_position = foreground_position
			_target_scale = _home_scale * foreground_scale_multiplier
			_idle_time_left = 0.0
	elif _foreground_state == 2:
		_foreground_stay_left -= delta
		if _foreground_stay_left <= 0.0:
			_foreground_state = 3
			_target_position = _random_point_in_bounds()
			_target_scale = _home_scale
			_idle_time_left = 0.0


func _on_target_reached() -> void:
	if _foreground_state == 1:
		_foreground_state = 2
		_foreground_stay_left = foreground_stay_duration
		_idle_time_left = 0.0
		return
	if _foreground_state == 3:
		_foreground_state = 0
		_foreground_time_left = _random_range(foreground_interval_range)

	_target_position = _random_point_in_bounds()
	_idle_time_left = _random_range(idle_duration_range)


func _update_visual_buzz(_delta: float) -> void:
	if _icon_sprite == null:
		return
	var bob := sin(float(Time.get_ticks_msec()) / 115.0 + float(get_instance_id() % 23)) * 3.0
	_icon_sprite.position.y = bob
	_icon_sprite.rotation = sin(float(Time.get_ticks_msec()) / 180.0 + float(get_instance_id() % 19)) * 0.08


func _clamp_to_bounds(point: Vector2) -> Vector2:
	var bounds_end := movement_bounds.position + movement_bounds.size
	return Vector2(
		clampf(point.x, movement_bounds.position.x, bounds_end.x),
		clampf(point.y, movement_bounds.position.y, bounds_end.y)
	)


func _random_point_in_bounds() -> Vector2:
	var bounds_end := movement_bounds.position + movement_bounds.size
	return Vector2(
		_rng.randf_range(movement_bounds.position.x, bounds_end.x),
		_rng.randf_range(movement_bounds.position.y, bounds_end.y)
	)


func _random_range(range: Vector2) -> float:
	var minimum: float = minf(range.x, range.y)
	var maximum: float = maxf(range.x, range.y)
	return _rng.randf_range(minimum, maximum)
