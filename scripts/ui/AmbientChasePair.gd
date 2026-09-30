class_name AmbientChasePair
extends Node2D

@export var cat_sprite: NodePath
@export var mouse_sprite: NodePath
@export var lane_y := 795.0
@export var left_start_x := -180.0
@export var right_end_x := 2100.0
@export var cat_spacing := 135.0
@export var chase_duration_range := Vector2(8.5, 11.5)
@export var interval_range := Vector2(18.0, 32.0)
@export var scale_during_chase := Vector2(0.22, 0.22)
@export var lane_y_variation := 46.0
@export var path_point_count_range := Vector2i(7, 9)
@export var segment_pause_range := Vector2(0.12, 0.28)
@export var mouse_dodge_strength := 86.0
@export var chase_y_span := 190.0
@export var near_miss_spacing := 72.0
@export var cat_follow_softness := 0.62
@export var bounce_amount := 0.08

@onready var _cat: Sprite2D = get_node_or_null(cat_sprite) as Sprite2D
@onready var _mouse: Sprite2D = get_node_or_null(mouse_sprite) as Sprite2D

var _rng := RandomNumberGenerator.new()
var _time_until_chase := 0.0
var _active_tween: Tween


func _ready() -> void:
	_rng.seed = int(Time.get_ticks_usec()) + get_instance_id()
	_hide_pair()
	_time_until_chase = _random_range(interval_range)


func _process(delta: float) -> void:
	if _active_tween != null and _active_tween.is_valid():
		return
	_time_until_chase -= delta
	if _time_until_chase <= 0.0:
		_start_chase()


func get_runtime_state() -> Dictionary:
	return {
		"time_until_chase": maxf(0.0, _time_until_chase),
		"active": _active_tween != null and _active_tween.is_valid(),
		"cat": _get_sprite_state(_cat),
		"mouse": _get_sprite_state(_mouse),
	}


func apply_runtime_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
	_time_until_chase = maxf(0.0, float(state.get("time_until_chase", _time_until_chase)))
	_apply_sprite_state(_cat, state.get("cat", {}))
	_apply_sprite_state(_mouse, state.get("mouse", {}))
	if bool(state.get("active", false)) and _cat != null and _mouse != null and _cat.visible and _mouse.visible:
		_resume_chase_from_restored_positions()


func _start_chase() -> void:
	if _cat == null or _mouse == null:
		return

	var left_to_right := _rng.randf() < 0.5
	var mouse_start_x := left_start_x if left_to_right else right_end_x
	var mouse_end_x := right_end_x if left_to_right else left_start_x
	var cat_start_x := mouse_start_x - cat_spacing if left_to_right else mouse_start_x + cat_spacing
	var direction_scale := 1.0 if left_to_right else -1.0
	var duration := _random_range(chase_duration_range)
	var y_offset := _rng.randf_range(-18.0, 18.0)
	var chase_center_y := lane_y + y_offset
	var point_count := _rng.randi_range(
		maxi(3, path_point_count_range.x),
		maxi(3, path_point_count_range.y)
	)
	var mouse_points := _build_mouse_chase_path(mouse_start_x, mouse_end_x, chase_center_y + 10.0, point_count)
	var cat_points := _build_cat_chase_path(mouse_points, cat_start_x, mouse_end_x - cat_spacing if left_to_right else mouse_end_x + cat_spacing, chase_center_y, left_to_right)
	var pause_indices := _choose_pause_indices(point_count)

	_cat.visible = true
	_mouse.visible = true
	var cat_base_scale := Vector2(scale_during_chase.x * direction_scale, scale_during_chase.y)
	var mouse_base_scale := Vector2(scale_during_chase.x * 0.72 * direction_scale, scale_during_chase.y * 0.72)
	_cat.scale = cat_base_scale
	_mouse.scale = mouse_base_scale
	_cat.position = cat_points[0]
	_mouse.position = mouse_points[0]
	_cat.modulate.a = 1.0
	_mouse.modulate.a = 1.0

	_active_tween = create_tween()
	var segment_duration := duration / float(point_count - 1)
	for index in range(1, point_count):
		var mouse_target: Vector2 = mouse_points[index]
		var cat_target: Vector2 = cat_points[index]
		var dart_multiplier := 0.72 if pause_indices.has(index - 1) else 1.0
		var current_segment_duration := segment_duration * _rng.randf_range(0.82, 1.12) * dart_multiplier
		var rotation_amount := 0.07 * direction_scale * (-1.0 if index % 2 == 0 else 1.0)
		var bounce_scale := 1.0 + bounce_amount * (1.25 if pause_indices.has(index - 1) else 1.0)

		_tween_runner_motion(_mouse, mouse_target, mouse_base_scale, rotation_amount, current_segment_duration, bounce_scale)
		_active_tween.parallel().tween_property(_cat, "position", cat_target, current_segment_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_active_tween.parallel().tween_property(_cat, "rotation", -rotation_amount * 0.65, minf(0.42, current_segment_duration * 0.55)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_bounce_scale(_cat, cat_base_scale, bounce_scale * 1.08, current_segment_duration)

		if pause_indices.has(index) and index < point_count - 1:
			_add_pause_and_near_miss(mouse_points[index], direction_scale, cat_base_scale, mouse_base_scale)
	_active_tween.tween_callback(_finish_chase)


func _finish_chase() -> void:
	_hide_pair()
	_time_until_chase = _random_range(interval_range)
	_active_tween = null


func _hide_pair() -> void:
	if _cat != null:
		_cat.visible = false
		_cat.rotation = 0.0
	if _mouse != null:
		_mouse.visible = false
		_mouse.rotation = 0.0


func _resume_chase_from_restored_positions() -> void:
	var direction_scale := 1.0 if _cat.scale.x >= 0.0 else -1.0
	var mouse_end_x := right_end_x if direction_scale > 0.0 else left_start_x
	var cat_end_x := mouse_end_x - cat_spacing if direction_scale > 0.0 else mouse_end_x + cat_spacing
	var duration := _get_remaining_chase_duration(mouse_end_x)
	_active_tween = create_tween()
	_active_tween.tween_property(_mouse, "position", Vector2(mouse_end_x, _mouse.position.y), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tween.parallel().tween_property(_cat, "position", Vector2(cat_end_x, _cat.position.y), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tween.parallel().tween_property(_mouse, "modulate:a", 0.0, 0.35).set_delay(maxf(0.0, duration - 0.35))
	_active_tween.parallel().tween_property(_cat, "modulate:a", 0.0, 0.35).set_delay(maxf(0.0, duration - 0.35))
	_active_tween.tween_callback(_finish_chase)


func _get_remaining_chase_duration(mouse_end_x: float) -> float:
	var full_distance := absf(right_end_x - left_start_x)
	if full_distance <= 0.0 or _mouse == null:
		return _random_range(chase_duration_range)
	var average_duration := (minf(chase_duration_range.x, chase_duration_range.y) + maxf(chase_duration_range.x, chase_duration_range.y)) * 0.5
	var remaining_ratio := clampf(absf(mouse_end_x - _mouse.position.x) / full_distance, 0.0, 1.0)
	return clampf(average_duration * remaining_ratio, 0.45, average_duration)


func _get_sprite_state(sprite: Sprite2D) -> Dictionary:
	if sprite == null:
		return {}
	return {
		"visible": sprite.visible,
		"position": _vector_to_dict(sprite.position),
		"scale": _vector_to_dict(sprite.scale),
		"rotation": sprite.rotation,
		"alpha": sprite.modulate.a,
	}


func _apply_sprite_state(sprite: Sprite2D, raw_state: Variant) -> void:
	if sprite == null or not (raw_state is Dictionary):
		return
	var state := raw_state as Dictionary
	sprite.visible = bool(state.get("visible", sprite.visible))
	sprite.position = _dict_to_vector(state.get("position", {}), sprite.position)
	sprite.scale = _dict_to_vector(state.get("scale", {}), sprite.scale)
	sprite.rotation = float(state.get("rotation", sprite.rotation))
	var modulate := sprite.modulate
	modulate.a = clampf(float(state.get("alpha", modulate.a)), 0.0, 1.0)
	sprite.modulate = modulate


func _vector_to_dict(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}


func _dict_to_vector(raw_value: Variant, fallback: Vector2) -> Vector2:
	if not (raw_value is Dictionary):
		return fallback
	var value := raw_value as Dictionary
	return Vector2(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)))


func _random_range(range: Vector2) -> float:
	var minimum := minf(range.x, range.y)
	var maximum := maxf(range.x, range.y)
	return _rng.randf_range(minimum, maximum)


func _build_mouse_chase_path(start_x: float, end_x: float, base_y: float, point_count: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var safe_count := maxi(3, point_count)
	var direction := 1.0 if end_x >= start_x else -1.0
	var min_y := base_y - chase_y_span * 0.5
	var max_y := base_y + chase_y_span * 0.5
	var last_y := base_y
	for index in range(safe_count):
		var t := float(index) / float(safe_count - 1)
		var x := lerpf(start_x, end_x, t)
		var y := base_y
		if index == 0 or index == safe_count - 1:
			y = base_y
		elif index % 3 == 1:
			x -= direction * _rng.randf_range(18.0, 42.0)
			y = _pick_vertical_dodge_y(last_y, min_y, max_y, -1.0)
		elif index % 3 == 2:
			x += direction * _rng.randf_range(20.0, 58.0)
			y = _pick_vertical_dodge_y(last_y, min_y, max_y, 1.0)
		else:
			y = _rng.randf_range(min_y, max_y)
		last_y = y
		points.append(Vector2(x, y))
	return points


func _build_cat_chase_path(mouse_points: Array[Vector2], start_x: float, end_x: float, base_y: float, left_to_right: bool) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var direction := 1.0 if left_to_right else -1.0
	for index in range(mouse_points.size()):
		if index == 0:
			points.append(Vector2(start_x, base_y))
			continue
		if index == mouse_points.size() - 1:
			points.append(Vector2(end_x, base_y))
			continue
		var leader: Vector2 = mouse_points[maxi(0, index - 1)]
		var current_mouse: Vector2 = mouse_points[index]
		var spacing := cat_spacing
		if index == mouse_points.size() - 2:
			spacing = maxf(near_miss_spacing, cat_spacing * 0.55)
		var x := lerpf(leader.x - direction * spacing, current_mouse.x - direction * spacing, cat_follow_softness)
		var delayed_y := lerpf(leader.y, current_mouse.y - 10.0, cat_follow_softness)
		var y := lerpf(base_y, delayed_y, 0.86)
		y += _rng.randf_range(-lane_y_variation * 0.24, lane_y_variation * 0.24)
		points.append(Vector2(x, y))
	return points


func _pick_vertical_dodge_y(previous_y: float, min_y: float, max_y: float, preferred_sign: float) -> float:
	var jump := _rng.randf_range(chase_y_span * 0.28, chase_y_span * 0.48)
	var candidate := previous_y + jump * preferred_sign
	if candidate < min_y or candidate > max_y:
		candidate = previous_y - jump * preferred_sign
	return clampf(candidate, min_y, max_y)


func _choose_pause_indices(point_count: int) -> Array[int]:
	var pauses: Array[int] = []
	if point_count <= 4:
		return pauses
	var midpoint := floori(float(point_count) * 0.5)
	pauses.append(_rng.randi_range(2, maxi(2, midpoint)))
	if point_count >= 7:
		var late_pause := _rng.randi_range(maxi(3, midpoint), point_count - 2)
		if not pauses.has(late_pause):
			pauses.append(late_pause)
	return pauses


func _add_pause_and_near_miss(mouse_position: Vector2, direction_scale: float, cat_base_scale: Vector2, mouse_base_scale: Vector2) -> void:
	var pause_duration := _random_range(segment_pause_range)
	var near_miss_position := Vector2(mouse_position.x - direction_scale * near_miss_spacing, mouse_position.y - 10.0)
	_active_tween.tween_property(_mouse, "scale", _bounced_scale(mouse_base_scale, 0.92), pause_duration * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_active_tween.parallel().tween_property(_mouse, "rotation", -0.06 * direction_scale, pause_duration * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_active_tween.parallel().tween_property(_cat, "position", near_miss_position, pause_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_active_tween.parallel().tween_property(_cat, "scale", _bounced_scale(cat_base_scale, 1.12), pause_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(_mouse, "scale", mouse_base_scale, pause_duration * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_active_tween.parallel().tween_property(_cat, "scale", cat_base_scale, pause_duration * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _tween_runner_motion(sprite: Sprite2D, target: Vector2, base_scale: Vector2, rotation_amount: float, duration: float, bounce_scale: float) -> void:
	_active_tween.tween_property(sprite, "position", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tween.parallel().tween_property(sprite, "rotation", rotation_amount, minf(0.42, duration * 0.55)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_bounce_scale(sprite, base_scale, bounce_scale, duration)


func _tween_bounce_scale(sprite: Sprite2D, base_scale: Vector2, multiplier: float, duration: float) -> void:
	_active_tween.parallel().tween_method(
		func(progress: float) -> void:
			sprite.scale = _running_bounce_scale(base_scale, multiplier, progress),
		0.0,
		1.0,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _bounced_scale(base_scale: Vector2, multiplier: float) -> Vector2:
	return Vector2(base_scale.x * multiplier, base_scale.y * (2.0 - multiplier))


func _running_bounce_scale(base_scale: Vector2, multiplier: float, progress: float) -> Vector2:
	var wave := sin(progress * PI)
	return _bounced_scale(base_scale, lerpf(1.0, multiplier, wave))
