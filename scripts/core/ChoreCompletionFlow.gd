class_name ChoreCompletionFlow
extends RefCounted

const _RETURN_TIMER_ID_META := "_farm_chore_return_timer_id"
const _RETURN_UNLOCK_TIME_META := "_farm_chore_return_unlock_msec"
const _RETURNING_META := "_farm_chore_returning_to_farmyard"
const _KEEP_COMPLETION_BACKGROUND_META := "keep_flat_completion_background"
const _COMPLETION_VISUAL_ROOT := "CompletionVisualRoot"

static var _farmyard_input_locked_until_msec := 0


static func is_tap_event(event: InputEvent) -> bool:
	return (
		(event is InputEventScreenTouch and event.pressed)
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	)


static func get_event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	return Vector2.INF


static func get_event_world_position(event: InputEvent, canvas_item: CanvasItem = null) -> Vector2:
	var event_position := get_event_position(event)
	if event_position == Vector2.INF:
		return Vector2.INF
	if canvas_item == null or not is_instance_valid(canvas_item):
		return event_position
	return canvas_item.get_canvas_transform().affine_inverse() * event_position


static func is_event_near_node(event: InputEvent, node: Node2D, radius: float) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	var event_position := get_event_world_position(event, node)
	if event_position == Vector2.INF:
		return false
	return event_position.distance_to(node.global_position) <= radius


static func is_event_inside_area(event: InputEvent, area: Area2D, canvas_item: CanvasItem = null, margin: float = 0.0) -> bool:
	if area == null or not is_instance_valid(area):
		return false
	var event_position := get_event_world_position(event, canvas_item if canvas_item != null else area)
	if event_position == Vector2.INF:
		return false
	return area_contains_world_position(area, event_position, margin)


static func area_contains_world_position(area: Area2D, world_position: Vector2, margin: float = 0.0) -> bool:
	if area == null or not is_instance_valid(area):
		return false
	if not area.input_pickable or not area.is_visible_in_tree():
		return false

	for child in area.get_children():
		var collision_shape := child as CollisionShape2D
		if collision_shape == null or collision_shape.disabled or collision_shape.shape == null:
			continue
		if _shape_contains_world_position(collision_shape, world_position, margin):
			return true
	return false


static func _shape_contains_world_position(collision_shape: CollisionShape2D, world_position: Vector2, margin: float) -> bool:
	var local_position := collision_shape.to_local(world_position)
	var shape := collision_shape.shape
	if shape is RectangleShape2D:
		var rectangle := shape as RectangleShape2D
		var half_size := rectangle.size * 0.5 + Vector2.ONE * margin
		return absf(local_position.x) <= half_size.x and absf(local_position.y) <= half_size.y
	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		return local_position.length() <= circle.radius + margin
	return false


static func start_auto_return(host: Node, farmyard_scene_path: String, delay_seconds: float, input_lock_seconds: float = 1.0) -> void:
	if host == null or farmyard_scene_path.is_empty() or delay_seconds <= 0.0:
		return

	var timer_id := 1
	if host.has_meta(_RETURN_TIMER_ID_META):
		timer_id = int(host.get_meta(_RETURN_TIMER_ID_META)) + 1
	host.set_meta(_RETURN_TIMER_ID_META, timer_id)
	host.set_meta(_RETURN_UNLOCK_TIME_META, Time.get_ticks_msec() + int(max(0.0, input_lock_seconds) * 1000.0))

	var timer := host.get_tree().create_timer(delay_seconds)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(host):
			return
		if bool(host.get_meta(_RETURNING_META, false)):
			return
		if not host.has_meta(_RETURN_TIMER_ID_META) or int(host.get_meta(_RETURN_TIMER_ID_META)) != timer_id:
			return
		return_to_farmyard(host, farmyard_scene_path)
	)


static func prepare_chore_scene(host: Node, back_button: Button = null) -> void:
	set_back_button_visible(back_button, false)


static func show_chore_complete(host: Node, back_button: Button = null) -> void:
	set_back_button_visible(back_button, true)
	# Chore completion text stays unobstructed. Farmyard hotspots show check badges instead.


static func show_completion_feedback(
	host: Node,
	completion_panel: Control,
	completion_label: Label,
	back_button: Button,
	message: String,
	play_sound: bool,
	completion_sound: AudioStream,
	voice_prompt_key: String,
	celebration_origin: Vector2,
	celebration_count: int,
	farmyard_scene_path: String,
	auto_return_delay: float,
	return_lock_seconds: float
) -> void:
	if completion_panel != null and is_instance_valid(completion_panel):
		_prepare_completion_panel(completion_panel)
		completion_panel.visible = true
		_show_completion_visuals(completion_panel, voice_prompt_key)
	if completion_label != null and is_instance_valid(completion_label):
		completion_label.text = ""
		completion_label.visible = false
	show_chore_complete(host, back_button)
	if play_sound:
		FarmFeedback.play_one_shot(host, completion_sound, -2.0)
		_speak_completion(message, voice_prompt_key)
	if celebration_count > 0:
		FarmFeedback.celebrate(host, celebration_origin, celebration_count)
	start_auto_return(host, farmyard_scene_path, auto_return_delay, return_lock_seconds)


static func set_back_button_visible(back_button: Button, visible: bool) -> void:
	if back_button == null or not is_instance_valid(back_button):
		return
	back_button.visible = visible
	back_button.disabled = not visible


static func can_return_after_completion(host: Node) -> bool:
	if host == null or not is_instance_valid(host):
		return false
	if not host.has_meta(_RETURN_UNLOCK_TIME_META):
		return true
	return Time.get_ticks_msec() >= int(host.get_meta(_RETURN_UNLOCK_TIME_META))


static func handle_completion_return_input(host: Node, event: InputEvent, farmyard_scene_path: String) -> bool:
	if not is_tap_event(event):
		return false
	if host == null or not is_instance_valid(host):
		return false
	if not _is_tap_anywhere_return_enabled():
		return false
	host.get_viewport().set_input_as_handled()
	return try_return_to_farmyard(host, farmyard_scene_path)


static func try_return_to_farmyard(host: Node, farmyard_scene_path: String) -> bool:
	if host == null or not is_instance_valid(host):
		return false
	if bool(host.get_meta(_RETURNING_META, false)):
		return false
	if not can_return_after_completion(host):
		return false
	return_to_farmyard(host, farmyard_scene_path)
	return true


static func return_to_farmyard(host: Node, farmyard_scene_path: String) -> void:
	if host == null or not is_instance_valid(host) or farmyard_scene_path.is_empty():
		return
	if bool(host.get_meta(_RETURNING_META, false)):
		return
	host.set_meta(_RETURNING_META, true)
	lock_farmyard_input(0.75)
	var tree := host.get_tree()
	if tree != null:
		var navigator := tree.root.get_node_or_null("SceneNavigator")
		if navigator != null and navigator.has_method("return_to_farmyard"):
			if bool(navigator.call("return_to_farmyard")):
				return
	host.get_tree().change_scene_to_file(farmyard_scene_path)


static func lock_farmyard_input(seconds: float) -> void:
	_farmyard_input_locked_until_msec = maxi(
		_farmyard_input_locked_until_msec,
		Time.get_ticks_msec() + int(maxf(0.0, seconds) * 1000.0)
	)


static func is_farmyard_input_locked(extra_seconds: float = 0.0) -> bool:
	if extra_seconds > 0.0:
		lock_farmyard_input(extra_seconds)
	return Time.get_ticks_msec() < _farmyard_input_locked_until_msec


static func _speak_completion(message: String, voice_prompt_key: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var voice_over_manager := tree.root.get_node_or_null("VoiceOverManager")
	if voice_over_manager != null and voice_over_manager.has_method("speak_completion"):
		voice_over_manager.call("speak_completion", message, voice_prompt_key)


static func _is_tap_anywhere_return_enabled() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return true
	var settings := tree.root.get_node_or_null("GameSettings")
	if settings != null and settings.has_method("is_tap_anywhere_chore_return_enabled"):
		return bool(settings.call("is_tap_anywhere_chore_return_enabled"))
	return true


static func _prepare_completion_panel(panel: Control) -> void:
	if bool(panel.get_meta(_KEEP_COMPLETION_BACKGROUND_META, false)):
		return
	if panel is Panel:
		(panel as Panel).add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.self_modulate = Color(1.0, 1.0, 1.0, 1.0)


static func _show_completion_visuals(panel: Control, voice_prompt_key: String) -> void:
	_clear_completion_visuals(panel)
	var root := Control.new()
	root.name = _COMPLETION_VISUAL_ROOT
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(root)

	var paths := _get_completion_visual_paths(voice_prompt_key)
	var count := paths.size()
	if count <= 0:
		return
	var center_x := panel.size.x * 0.5
	if center_x <= 0.0:
		center_x = 400.0
	var center_y := panel.size.y * 0.5
	if center_y <= 0.0:
		center_y = 128.0
	center_y += _get_completion_visual_y_offset(voice_prompt_key)
	var spacing := _get_completion_visual_spacing(voice_prompt_key)
	for index in count:
		var texture := load(paths[index]) as Texture2D
		if texture == null:
			continue
		var visual := TextureRect.new()
		visual.name = "CompletionVisual%d" % (index + 1)
		visual.texture = texture
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var visual_size := _get_completion_visual_size(voice_prompt_key, count)
		if count == 1:
			visual_size = Vector2(172.0, 172.0)
		visual.size = visual_size
		visual.pivot_offset = visual_size * 0.5
		visual.position = Vector2(center_x - visual_size.x * 0.5 + (float(index) - float(count - 1) * 0.5) * spacing, center_y - visual_size.y * 0.5)
		root.add_child(visual)
		var tween := visual.create_tween()
		visual.scale = Vector2.ONE * 0.72
		tween.tween_property(visual, "scale", Vector2.ONE * 1.08, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual, "scale", Vector2.ONE, 0.1)


static func _clear_completion_visuals(panel: Control) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	var existing := panel.get_node_or_null(_COMPLETION_VISUAL_ROOT)
	if existing != null:
		existing.queue_free()


static func _get_completion_visual_y_offset(voice_prompt_key: String) -> float:
	var key := voice_prompt_key.to_lower()
	if key.contains("milk"):
		return -200.0
	return 0.0


static func _get_completion_visual_spacing(voice_prompt_key: String) -> float:
	var key := voice_prompt_key.to_lower()
	if key.contains("milk"):
		return 140.0
	return 168.0


static func _get_completion_visual_size(voice_prompt_key: String, count: int) -> Vector2:
	var key := voice_prompt_key.to_lower()
	if key.contains("milk"):
		return Vector2(118.0, 118.0)
	if count == 1:
		return Vector2(172.0, 172.0)
	return Vector2(142.0, 142.0)


static func _get_completion_visual_paths(voice_prompt_key: String) -> Array[String]:
	var key := voice_prompt_key.to_lower()
	if key.contains("egg"):
		return ["res://art/animals/chicken_celebrating.png", "res://art/props/egg_basket.png"]
	if key.contains("milk"):
		return ["res://art/animals/cow_celebrating.png", "res://art/props/milk_bucket.png"]
	if key.contains("feed"):
		return ["res://art/animals/pig_celebrating.png", "res://art/animals/goat_celebrating.png", "res://art/animals/sheep_celebrating.png"]
	if key.contains("brush") or key.contains("groom"):
		return ["res://art/animals/pony_celebrating.png"]
	if key.contains("garden") or key.contains("water") or key.contains("harvest"):
		return ["res://art/props/harvest_basket.png", "res://art/garden/harvest_ready.png"]
	return ["res://art/effects/success_glow.png"]
