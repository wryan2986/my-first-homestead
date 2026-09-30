extends Sprite2D

@export var movement_bounds := Rect2(-110.0, -50.0, 220.0, 100.0)
@export var move_speed := 22.0
@export var idle_duration_range := Vector2(1.2, 2.8)
@export var bounce_height := 4.0

var _target_position := Vector2.ZERO
var _idle_time := 0.0
var _base_y := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_base_y = position.y
	_target_position = _random_point_in_bounds()
	_idle_time = _random_idle_duration()


func _process(delta: float) -> void:
	if not visible:
		return

	if _idle_time > 0.0:
		_idle_time -= delta
		position.y = _base_y + sin(Time.get_ticks_msec() / 220.0) * bounce_height
		return

	var direction := _target_position - position
	if direction.length() <= 3.0:
		_base_y = position.y
		_target_position = _random_point_in_bounds()
		_idle_time = _random_idle_duration()
		return

	position += direction.normalized() * move_speed * delta
	position.x = clampf(position.x, movement_bounds.position.x, movement_bounds.end.x)
	position.y = clampf(position.y, movement_bounds.position.y, movement_bounds.end.y)
	_base_y = position.y


func _random_point_in_bounds() -> Vector2:
	return Vector2(
		_rng.randf_range(movement_bounds.position.x, movement_bounds.end.x),
		_rng.randf_range(movement_bounds.position.y, movement_bounds.end.y)
	)


func _random_idle_duration() -> float:
	return _rng.randf_range(idle_duration_range.x, idle_duration_range.y)
