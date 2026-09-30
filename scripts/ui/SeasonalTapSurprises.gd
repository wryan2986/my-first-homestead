class_name SeasonalTapSurprises
extends Node2D

@export var feedback_label: NodePath
@export var leaf_texture: Texture2D
@export var snowflake_texture: Texture2D
@export var sparkle_texture: Texture2D
@export var spawn_interval_range := Vector2(6.0, 11.0)
@export var fall_leaf_area := Rect2(600.0, 270.0, 780.0, 420.0)
@export var winter_snow_area := Rect2(120.0, 90.0, 1680.0, 620.0)
@export var spring_flutter_area := Rect2(650.0, 580.0, 500.0, 260.0)

@onready var _feedback_label: Label = get_node_or_null(feedback_label) as Label

var _rng := RandomNumberGenerator.new()
var _season := "spring"
var _time_until_spawn := 2.0


func _ready() -> void:
	_rng.seed = int(Time.get_ticks_usec()) + get_instance_id()
	set_process(true)


func _process(delta: float) -> void:
	if _season != "spring" and _season != "fall" and _season != "winter":
		return
	_time_until_spawn -= delta
	if _time_until_spawn > 0.0:
		return
	_time_until_spawn = _random_range(spawn_interval_range)
	match _season:
		"spring":
			_spawn_spring_flutter()
		"fall":
			_spawn_fall_leaf_swirl()
		"winter":
			_spawn_winter_snowflake()


func set_season(season: String) -> void:
	_season = season
	_time_until_spawn = _rng.randf_range(1.2, 3.0)
	visible = _season != "summer"


func _spawn_fall_leaf_swirl(origin := Vector2.INF) -> void:
	var center := origin if origin != Vector2.INF else _random_point(fall_leaf_area)
	for index in 6:
		var leaf := _make_sprite(leaf_texture, center + Vector2(_rng.randf_range(-24.0, 24.0), _rng.randf_range(-16.0, 16.0)), 0.18, 18)
		if leaf == null:
			return
		var angle := _rng.randf_range(0.0, TAU)
		var target := center + Vector2(cos(angle), sin(angle)) * _rng.randf_range(42.0, 86.0)
		var tween := leaf.create_tween()
		tween.tween_property(leaf, "position", target + Vector2(24.0, 54.0), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(leaf, "rotation", leaf.rotation + _rng.randf_range(1.8, 3.4), 1.4)
		tween.parallel().tween_property(leaf, "modulate:a", 0.0, 1.4)
		tween.tween_callback(leaf.queue_free)


func _spawn_winter_snowflake(origin := Vector2.INF) -> void:
	var start := origin if origin != Vector2.INF else _random_point(winter_snow_area)
	var flake := _make_sprite(snowflake_texture, start, 0.16, 19)
	if flake == null:
		return
	flake.modulate = Color(0.9, 0.98, 1.0, 0.9)
	var tween := flake.create_tween()
	tween.tween_property(flake, "position", start + Vector2(_rng.randf_range(-28.0, 28.0), _rng.randf_range(90.0, 150.0)), 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(flake, "rotation", _rng.randf_range(-1.1, 1.1), 2.2)
	tween.parallel().tween_property(flake, "modulate:a", 0.0, 2.2)
	tween.tween_callback(flake.queue_free)


func _spawn_spring_flutter(origin := Vector2.INF) -> void:
	var start := origin if origin != Vector2.INF else _random_point(spring_flutter_area)
	var sparkle := _make_sprite(sparkle_texture, start, 0.16, 18)
	if sparkle == null:
		return
	sparkle.modulate = Color(1.0, 0.9, 0.55, 0.85)
	var tween := sparkle.create_tween()
	tween.tween_property(sparkle, "position", start + Vector2(_rng.randf_range(-70.0, 70.0), _rng.randf_range(-52.0, 8.0)), 1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sparkle, "scale", sparkle.scale * 0.45, 1.7)
	tween.parallel().tween_property(sparkle, "modulate:a", 0.0, 1.7)
	tween.tween_callback(sparkle.queue_free)


func _make_sprite(texture: Texture2D, world_position: Vector2, scale_amount: float, z: int) -> Sprite2D:
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = to_local(world_position)
	sprite.z_index = z
	sprite.scale = Vector2.ONE * _rng.randf_range(scale_amount * 0.72, scale_amount * 1.18)
	sprite.rotation = _rng.randf_range(-0.6, 0.6)
	add_child(sprite)
	return sprite


func _random_point(area: Rect2) -> Vector2:
	return Vector2(
		_rng.randf_range(area.position.x, area.position.x + area.size.x),
		_rng.randf_range(area.position.y, area.position.y + area.size.y)
	)


func _random_range(range: Vector2) -> float:
	return _rng.randf_range(minf(range.x, range.y), maxf(range.x, range.y))


func _is_press_event(event: InputEvent) -> bool:
	return (
		(event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	)


func _event_to_world_position(event: InputEvent) -> Vector2:
	var viewport_position := Vector2.INF
	if event is InputEventMouseButton:
		viewport_position = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch:
		viewport_position = (event as InputEventScreenTouch).position
	if viewport_position == Vector2.INF:
		return Vector2.INF
	return get_canvas_transform().affine_inverse() * viewport_position
