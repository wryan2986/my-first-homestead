class_name BouncyCritter
extends Area2D

signal tapped(critter: BouncyCritter)

@export var critter_id := ""
@export var critter_name := ""
@export var icon_sprite: NodePath
@export var name_label: NodePath
@export var happy_glow: NodePath
@export var idle_texture: Texture2D
@export var happy_texture: Texture2D
@export var sprite_faces_left := false
@export var autonomous_movement_enabled := true
@export var random_clucks_enabled := true
@export var movement_bounds := Rect2(160.0, 790.0, 1320.0, 190.0)
@export var move_speed := 70.0
@export var idle_duration_range := Vector2(0.9, 2.3)
@export var waddle_distance_range := Vector2(70.0, 170.0)
@export var cluck_sounds: Array[AudioStream] = []
@export var cluck_interval_range := Vector2(4.5, 9.5)
@export var cluck_volume_db := -7.0

@onready var _icon_sprite: Sprite2D = get_node_or_null(icon_sprite) as Sprite2D
@onready var _name_label: Label = get_node_or_null(name_label) as Label
@onready var _happy_glow: CanvasItem = get_node_or_null(happy_glow) as CanvasItem

var _rng := RandomNumberGenerator.new()
var _idle_time_left := 0.0
var _cluck_time_left := 0.0
var _waddle_hop_time_left := 0.0
var _target_position := Vector2.ZERO
var _is_moving := false
var _hop_feedback_active := false


func _ready() -> void:
	input_pickable = true
	_rng.seed = int(Time.get_ticks_usec()) + get_instance_id()
	if _icon_sprite != null and idle_texture != null:
		_icon_sprite.texture = idle_texture
	if _name_label != null:
		_name_label.text = critter_name
		_name_label.visible = not critter_name.strip_edges().is_empty()
	if _happy_glow != null:
		_happy_glow.visible = false
	if autonomous_movement_enabled:
		position = _clamp_to_bounds(position)
		_idle_time_left = _random_range(idle_duration_range)
	if random_clucks_enabled:
		_cluck_time_left = _random_range(cluck_interval_range) + _rng.randf_range(0.0, 2.0)


func _process(delta: float) -> void:
	if autonomous_movement_enabled:
		_update_autonomous_movement(delta)
	if random_clucks_enabled:
		_update_random_clucks(delta)


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		handle_tap()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_tap()


func handle_tap() -> void:
	get_viewport().set_input_as_handled()
	emit_signal("tapped", self)


func hop() -> void:
	_play_visual_hop(26.0, 0.11)
	var pulse_target: CanvasItem = _icon_sprite if _icon_sprite != null else self
	FarmFeedback.pulse(pulse_target, 1.12)
	if not cluck_sounds.is_empty():
		var sound := cluck_sounds[_rng.randi_range(0, cluck_sounds.size() - 1)]
		FarmFeedback.play_one_shot(self, sound, cluck_volume_db)
	if _icon_sprite != null and happy_texture != null:
		_icon_sprite.texture = happy_texture
	if _happy_glow != null:
		_happy_glow.visible = true

	var timer := get_tree().create_timer(0.5)
	timer.timeout.connect(func() -> void:
		if _icon_sprite != null and idle_texture != null:
			_icon_sprite.texture = idle_texture
		if _happy_glow != null:
			_happy_glow.visible = false
	)


func _update_autonomous_movement(delta: float) -> void:
	if _is_moving:
		var distance_this_frame := move_speed * delta
		position = position.move_toward(_target_position, distance_this_frame)
		_waddle_hop_time_left -= delta
		if _waddle_hop_time_left <= 0.0:
			_play_visual_hop(10.0, 0.08)
			_waddle_hop_time_left = _rng.randf_range(0.28, 0.46)
		if position.distance_to(_target_position) <= 1.0:
			position = _target_position
			_is_moving = false
			_idle_time_left = _random_range(idle_duration_range)
		return

	_idle_time_left -= delta
	if _idle_time_left <= 0.0:
		_choose_new_waddle_target()


func _choose_new_waddle_target() -> void:
	var distance := _random_range(waddle_distance_range)
	var x_direction := -1.0 if _rng.randf() < 0.5 else 1.0
	var offset := Vector2(
		x_direction * distance,
		_rng.randf_range(-distance * 0.22, distance * 0.22)
	)
	_target_position = _clamp_to_bounds(position + offset)

	if position.distance_to(_target_position) < waddle_distance_range.x * 0.45:
		_target_position = _random_point_in_bounds()

	if _icon_sprite != null:
		var moving_left := _target_position.x < position.x
		_icon_sprite.flip_h = moving_left != sprite_faces_left
	_is_moving = true
	_waddle_hop_time_left = _rng.randf_range(0.12, 0.28)


func _update_random_clucks(delta: float) -> void:
	if cluck_sounds.is_empty():
		return

	_cluck_time_left -= delta
	if _cluck_time_left > 0.0:
		return

	var sound := cluck_sounds[_rng.randi_range(0, cluck_sounds.size() - 1)]
	FarmFeedback.play_one_shot(self, sound, cluck_volume_db)
	_cluck_time_left = _random_range(cluck_interval_range)


func _play_visual_hop(hop_height: float, duration: float) -> void:
	var visual: Node2D = _icon_sprite if _icon_sprite != null else self
	if visual == null or not is_instance_valid(visual) or _hop_feedback_active:
		return

	_hop_feedback_active = true
	var original_y := visual.position.y
	var tween := visual.create_tween()
	tween.tween_property(visual, "position:y", original_y - hop_height, duration)
	tween.tween_property(visual, "position:y", original_y, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(visual):
			visual.position.y = original_y
		_hop_feedback_active = false
	)


func _clamp_to_bounds(point: Vector2) -> Vector2:
	var bounds_end := movement_bounds.position + movement_bounds.size
	return Vector2(
		clamp(point.x, movement_bounds.position.x, bounds_end.x),
		clamp(point.y, movement_bounds.position.y, bounds_end.y)
	)


func _random_point_in_bounds() -> Vector2:
	var bounds_end := movement_bounds.position + movement_bounds.size
	return Vector2(
		_rng.randf_range(movement_bounds.position.x, bounds_end.x),
		_rng.randf_range(movement_bounds.position.y, bounds_end.y)
	)


func _random_range(range: Vector2) -> float:
	var minimum: float = min(range.x, range.y)
	var maximum: float = max(range.x, range.y)
	return _rng.randf_range(minimum, maximum)
