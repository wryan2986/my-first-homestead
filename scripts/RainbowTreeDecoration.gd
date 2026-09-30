extends Sprite2D

@export var spring_drop_paths: Array[String] = ["res://art/effects/rainbow_tree_blossom_drop.png"]
@export var summer_drop_paths: Array[String] = ["res://art/effects/rainbow_tree_green_apple_drop.png"]
@export var fall_drop_paths: Array[String] = ["res://art/effects/fall_leaf.png", "res://art/effects/rainbow_tree_acorn_drop.png"]
@export var winter_drop_paths: Array[String] = ["res://art/effects/rainbow_tree_snow_puff_drop.png", "res://art/effects/large_snowflake.png"]
@export var shake_duration := 0.52
@export var drop_count := 4
@export var drop_anchor_path := NodePath("DropAnchor")
@export var drop_spawn_local_center := Vector2(-72.0, -82.0)
@export var drop_spawn_local_radius := Vector2(108.0, 68.0)
@export var drop_fall_distance := Vector2(42.0, 190.0)
@export var drop_scale := Vector2(0.18, 0.18)
@export var drop_z_offset := 4

var _shake_tween: Tween
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func handle_tap() -> void:
	if not is_visible_in_tree():
		return
	get_viewport().set_input_as_handled()
	_play_shake()
	_drop_seasonal_items()


func _play_shake() -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	rotation_degrees = 0.0
	FarmFeedback.flash(self, Color(1.12, 1.1, 1.0, 1.0), 0.08)
	_shake_tween = create_tween()
	_shake_tween.tween_property(self, "rotation_degrees", -4.5, shake_duration * 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(self, "rotation_degrees", 4.0, shake_duration * 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shake_tween.tween_property(self, "rotation_degrees", -2.5, shake_duration * 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shake_tween.tween_property(self, "rotation_degrees", 1.5, shake_duration * 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shake_tween.tween_property(self, "rotation_degrees", 0.0, shake_duration * 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _drop_seasonal_items() -> void:
	for index in drop_count:
		var texture := _get_drop_texture()
		if texture == null:
			continue
		_spawn_drop(texture, index)


func _spawn_drop(texture: Texture2D, index: int) -> void:
	var drop := Sprite2D.new()
	drop.texture = texture
	drop.centered = true
	drop.z_index = z_index + drop_z_offset
	drop.scale = drop_scale * _rng.randf_range(0.86, 1.18)
	drop.rotation_degrees = _rng.randf_range(-22.0, 22.0)
	# Parent the drop before assigning global coordinates. On responsive/mobile
	# viewports, setting global_position while the node is unparented lets the
	# later parent/canvas transform shift the item away from the canopy.
	get_parent().add_child(drop)
	var start := _random_drop_spawn_position()
	drop.global_position = start
	var end := start + Vector2(
		_rng.randf_range(-drop_fall_distance.x, drop_fall_distance.x),
		_rng.randf_range(drop_fall_distance.y * 0.72, drop_fall_distance.y)
	)

	var tween := drop.create_tween()
	tween.set_parallel(true)
	tween.tween_property(drop, "global_position", end, 0.92 + float(index) * 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(drop, "rotation_degrees", drop.rotation_degrees + _rng.randf_range(-160.0, 160.0), 0.92)
	tween.tween_property(drop, "modulate:a", 0.0, 0.28).set_delay(0.76 + float(index) * 0.04)
	tween.set_parallel(false)
	tween.tween_callback(drop.queue_free)


func _random_drop_spawn_position() -> Vector2:
	var local_offset := Vector2(
		_rng.randf_range(-drop_spawn_local_radius.x, drop_spawn_local_radius.x),
		_rng.randf_range(-drop_spawn_local_radius.y, drop_spawn_local_radius.y)
	)
	return to_global(_get_drop_anchor_local_position() + local_offset)


func get_drop_spawn_local_rect() -> Rect2:
	var center := _get_drop_anchor_local_position()
	return Rect2(center - drop_spawn_local_radius, drop_spawn_local_radius * 2.0)


func _get_drop_anchor_local_position() -> Vector2:
	var anchor := get_node_or_null(drop_anchor_path) as Node2D
	if anchor != null:
		return anchor.position
	return drop_spawn_local_center


func _get_drop_texture() -> Texture2D:
	var path := _choose_drop_path()
	if path.is_empty():
		return null
	return load(path) as Texture2D


func _choose_drop_path() -> String:
	var paths := get_drop_paths_for_season(_get_current_season())
	if paths.is_empty():
		return ""
	return paths[_rng.randi_range(0, paths.size() - 1)]


func get_drop_paths_for_season(season: String) -> Array[String]:
	match season:
		"summer":
			return summer_drop_paths
		"fall":
			return fall_drop_paths
		"winter":
			return winter_drop_paths
		_:
			return spring_drop_paths


func _get_current_season() -> String:
	var farm_state := get_node_or_null("/root/FarmState")
	if farm_state != null:
		return String(farm_state.current_season)
	return "spring"
