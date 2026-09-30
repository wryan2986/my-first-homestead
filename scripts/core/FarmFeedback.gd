class_name FarmFeedback
extends RefCounted

const _PULSE_BASE_SCALE_META := "_farm_feedback_pulse_base_scale"
const _PULSE_TWEEN_META := "_farm_feedback_pulse_tween"
const _PULSE_ID_META := "_farm_feedback_pulse_id"
const CELEBRATION_COLORS: Array[Color] = [
	Color("fff275"),
	Color("ff8fab"),
	Color("8ee6a8"),
	Color("8bd3ff"),
	Color("f7b267"),
	Color("d8b4ff"),
]


static func pulse(item: CanvasItem, scale_multiplier: float = 1.08, duration: float = 0.12) -> void:
	if item == null or not is_instance_valid(item):
		return

	if item is Node2D:
		_pulse_scale(item as Node2D, scale_multiplier, duration)
	elif item is Control:
		_pulse_scale(item as Control, scale_multiplier, duration)


static func _pulse_scale(node: Node, scale_multiplier: float, duration: float) -> void:
	var base_scale: Vector2 = node.get("scale")
	if node.has_meta(_PULSE_BASE_SCALE_META):
		base_scale = node.get_meta(_PULSE_BASE_SCALE_META)
	else:
		node.set_meta(_PULSE_BASE_SCALE_META, base_scale)

	if node.has_meta(_PULSE_TWEEN_META):
		var previous_tween = node.get_meta(_PULSE_TWEEN_META)
		if previous_tween is Tween and previous_tween.is_valid():
			previous_tween.kill()

	var pulse_id := 1
	if node.has_meta(_PULSE_ID_META):
		pulse_id = int(node.get_meta(_PULSE_ID_META)) + 1
	node.set_meta(_PULSE_ID_META, pulse_id)

	node.set("scale", base_scale)
	var tween := node.create_tween()
	node.set_meta(_PULSE_TWEEN_META, tween)
	tween.tween_property(node, "scale", base_scale * scale_multiplier, duration)
	tween.tween_property(node, "scale", base_scale, duration)
	tween.finished.connect(func() -> void:
		if not is_instance_valid(node):
			return
		if not node.has_meta(_PULSE_ID_META) or int(node.get_meta(_PULSE_ID_META)) != pulse_id:
			return
		node.set("scale", base_scale)
		if node.has_meta(_PULSE_TWEEN_META):
			node.remove_meta(_PULSE_TWEEN_META)
		if node.has_meta(_PULSE_BASE_SCALE_META):
			node.remove_meta(_PULSE_BASE_SCALE_META)
		if node.has_meta(_PULSE_ID_META):
			node.remove_meta(_PULSE_ID_META)
	)


static func bounce(node: Node2D, hop_height: float = 22.0, duration: float = 0.1) -> void:
	if node == null or not is_instance_valid(node):
		return

	var original_y := node.position.y
	var tween := node.create_tween()
	tween.tween_property(node, "position:y", original_y - hop_height, duration)
	tween.tween_property(node, "position:y", original_y, duration)


static func flash(item: CanvasItem, flash_color: Color = Color(1.15, 1.15, 1.15, 1.0), duration: float = 0.12) -> void:
	if item == null or not is_instance_valid(item):
		return

	var original := item.modulate
	var tween := item.create_tween()
	tween.tween_property(item, "modulate", flash_color, duration)
	tween.tween_property(item, "modulate", original, duration)


static func assist_hint(item: CanvasItem, strong: bool = false) -> void:
	if item == null or not is_instance_valid(item):
		return

	if strong:
		pulse(item, 1.14, 0.14)
		flash(item, Color(1.22, 1.18, 0.72, 1.0), 0.1)
		if item is Node2D:
			bounce(item as Node2D, 14.0, 0.08)
	else:
		pulse(item, 1.07, 0.16)
		flash(item, Color(1.12, 1.18, 0.96, 1.0), 0.12)


static func play_one_shot(host: Node, stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if host == null or stream == null or not is_instance_valid(host):
		return

	var player := AudioStreamPlayer.new()
	host.add_child(player)
	player.stream = stream
	player.bus = _get_sfx_bus_name()
	player.volume_db = volume_db
	player.pitch_scale = maxf(0.01, pitch_scale)
	player.finished.connect(player.queue_free)
	player.play()


static func get_visual_global_scale(visual: Node2D, fallback: Vector2 = Vector2.ONE) -> Vector2:
	if visual == null or not is_instance_valid(visual):
		return fallback
	return visual.global_scale


static func make_feedback_sprite(parent: Node, texture: Texture2D, sprite_scale: Vector2, z_index: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = sprite_scale
	sprite.z_index = z_index
	if parent != null and is_instance_valid(parent):
		parent.add_child(sprite)
	return sprite


static func spawn_note_sprite(
		host: Node,
		texture: Texture2D,
		position: Vector2,
		modulate_color: Color = Color.WHITE,
		sprite_scale: Vector2 = Vector2(0.36, 0.36),
		rise_offset: Vector2 = Vector2(0.0, -68.0),
		z_index: int = 24,
		duration: float = 0.85
) -> void:
	if host == null or texture == null or not is_instance_valid(host):
		return

	var note := Sprite2D.new()
	note.texture = texture
	note.modulate = modulate_color
	note.global_position = position
	note.scale = sprite_scale
	note.z_index = z_index
	host.add_child(note)

	var tween := note.create_tween()
	tween.set_parallel(true)
	tween.tween_property(note, "global_position", position + rise_offset, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(note, "modulate:a", 0.0, duration)
	tween.tween_property(note, "scale", sprite_scale * 0.72, duration)
	tween.set_parallel(false)
	tween.tween_callback(note.queue_free)


static func spawn_note_shape(
		host: Node,
		texture: Texture2D,
		position: Vector2,
		variant_index: int,
		modulate_color: Color = Color.WHITE,
		sprite_scale: Vector2 = Vector2(0.36, 0.36),
		rise_offset: Vector2 = Vector2(0.0, -68.0),
		z_index: int = 24,
		duration: float = 0.85
) -> void:
	if host == null or not is_instance_valid(host):
		return

	var note := Node2D.new()
	note.global_position = position
	note.scale = sprite_scale
	note.z_index = z_index
	var tint := modulate_color
	tint.a = 1.0
	note.modulate = tint
	host.add_child(note)

	_build_note_variant(note, texture, variant_index)

	var tween := note.create_tween()
	tween.set_parallel(true)
	tween.tween_property(note, "global_position", position + rise_offset, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(note, "modulate:a", 0.0, duration)
	tween.tween_property(note, "scale", sprite_scale * 0.72, duration)
	tween.set_parallel(false)
	tween.tween_callback(note.queue_free)


static func _get_sfx_bus_name() -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return "Master"
	var music_manager := tree.root.get_node_or_null("MusicManager")
	if music_manager != null and music_manager.has_method("get_sfx_bus_name"):
		return String(music_manager.call("get_sfx_bus_name"))
	return "Master"


static func celebrate(host: Node, origin: Vector2 = Vector2.INF, count: int = 22) -> void:
	if host == null or not is_instance_valid(host):
		return

	var root := Node2D.new()
	root.name = "CelebrationBurst"
	host.add_child(root)
	if origin == Vector2.INF:
		origin = _get_default_celebration_origin(host)
	root.global_position = origin

	for index in count:
		_spawn_confetti_piece(root, index, count)

	var cleanup_timer := host.get_tree().create_timer(1.45)
	cleanup_timer.timeout.connect(func() -> void:
		if is_instance_valid(root):
			root.queue_free()
	)


static func soft_sparkle_burst(host: Node, texture: Texture2D, origin: Vector2, count: int = 5, base_scale: float = 0.12) -> void:
	if host == null or texture == null or not is_instance_valid(host):
		return

	var root := Node2D.new()
	root.name = "SoftSparkleBurst"
	root.global_position = origin
	host.add_child(root)

	for index in count:
		var sparkle := Sprite2D.new()
		sparkle.texture = texture
		sparkle.z_index = 110
		sparkle.modulate = Color(1.0, 0.94, 0.62, 0.82)
		sparkle.scale = Vector2.ONE * (base_scale + float(index % 3) * 0.025)
		var angle := TAU * float(index) / maxf(1.0, float(count))
		var start := Vector2(cos(angle), sin(angle)) * (18.0 + float(index % 2) * 8.0)
		var target := start + Vector2(cos(angle), sin(angle)) * 42.0 + Vector2(0.0, -18.0)
		sparkle.position = start
		root.add_child(sparkle)

		var tween := sparkle.create_tween()
		tween.set_parallel(true)
		tween.tween_property(sparkle, "position", target, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(sparkle, "scale", sparkle.scale * 0.55, 0.48)
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.48)

	var cleanup_timer := host.get_tree().create_timer(0.55)
	cleanup_timer.timeout.connect(func() -> void:
		if is_instance_valid(root):
			root.queue_free()
	)


static func _spawn_confetti_piece(root: Node2D, index: int, total_count: int) -> void:
	var piece := Polygon2D.new()
	var size := 8.0 + float(index % 4) * 2.0
	piece.polygon = PackedVector2Array([
		Vector2(-size, -size * 0.45),
		Vector2(size, -size * 0.45),
		Vector2(size, size * 0.45),
		Vector2(-size, size * 0.45),
	])
	piece.color = CELEBRATION_COLORS[index % CELEBRATION_COLORS.size()]
	piece.rotation = float(index) * 0.73
	piece.z_index = 100
	root.add_child(piece)

	var angle: float = -PI * 0.92 + (PI * 0.84 * float(index) / max(1.0, float(total_count - 1)))
	var distance: float = 80.0 + float((index * 37) % 90)
	var target := Vector2(cos(angle), sin(angle)) * distance + Vector2(0.0, 64.0 + float((index * 19) % 36))
	var tween := piece.create_tween()
	tween.set_parallel(true)
	tween.tween_property(piece, "position", target, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "rotation", piece.rotation + PI * 1.35, 0.75)
	tween.tween_property(piece, "modulate:a", 0.0, 0.75).set_delay(0.35)


static func _build_note_variant(parent: Node2D, texture: Texture2D, variant_index: int) -> void:
	if texture == null:
		return
	match posmod(variant_index, 5):
		0:
			_add_note_sprite(parent, texture, Vector2(-12.0, 16.0), 0.48, -14.0)
		1:
			_add_note_sprite(parent, texture, Vector2(-14.0, 14.0), 0.46, -16.0)
			_add_note_sprite(parent, texture, Vector2(14.0, 4.0), 0.28, 16.0)
		2:
			_add_note_sprite(parent, texture, Vector2(-10.0, 18.0), 0.5, -10.0)
			_add_note_sprite(parent, texture, Vector2(10.0, -10.0), 0.26, 18.0)
		3:
			_add_note_sprite(parent, texture, Vector2(-6.0, 18.0), 0.46, 10.0)
			_add_note_sprite(parent, texture, Vector2(18.0, -2.0), 0.24, 22.0)
			_add_sparkle(parent, Vector2(20.0, -18.0), 8.0)
			_add_sparkle(parent, Vector2(-14.0, -24.0), 5.0)
		_:
			_add_note_sprite(parent, texture, Vector2(-18.0, 16.0), 0.42, -18.0)
			_add_note_sprite(parent, texture, Vector2(2.0, 0.0), 0.34, 0.0)
			_add_note_sprite(parent, texture, Vector2(22.0, -10.0), 0.24, 18.0)


static func _add_sparkle(parent: Node2D, center: Vector2, size: float) -> void:
	var outline_color := Color(0.35, 0.21, 0.1, 1.0)
	var points := PackedVector2Array([
		center + Vector2(0.0, -size),
		center + Vector2(size * 0.35, -size * 0.35),
		center + Vector2(size, 0.0),
		center + Vector2(size * 0.35, size * 0.35),
		center + Vector2(0.0, size),
		center + Vector2(-size * 0.35, size * 0.35),
		center + Vector2(-size, 0.0),
		center + Vector2(-size * 0.35, -size * 0.35),
	])
	_add_polygon(parent, points, outline_color)
	_add_polygon(parent, _scale_points(points, center, 0.75), Color(1.0, 0.95, 0.82, 1.0))


static func _add_note_sprite(parent: Node2D, texture: Texture2D, position: Vector2, scale_value: float, rotation_degrees: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = position
	sprite.scale = Vector2.ONE * scale_value
	sprite.rotation_degrees = rotation_degrees
	sprite.z_index = 1
	parent.add_child(sprite)


static func _add_polygon(parent: Node2D, points: PackedVector2Array, color: Color) -> void:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	polygon.z_index = 0
	parent.add_child(polygon)


static func _scale_points(points: PackedVector2Array, center: Vector2, scale_factor: float) -> PackedVector2Array:
	var scaled := PackedVector2Array()
	for point in points:
		scaled.append(center + (point - center) * scale_factor)
	return scaled


static func _get_default_celebration_origin(host: Node) -> Vector2:
	if host is CanvasItem:
		var canvas_item := host as CanvasItem
		return canvas_item.get_viewport_rect().size * 0.5
	return Vector2(960.0, 540.0)


static func flash_label(label: Label, text: String, color: Color, duration: float = 1.0) -> void:
	if label == null or not is_instance_valid(label):
		return
	if not is_play_scene_text_enabled():
		hide_label(label)
		return

	label.text = text
	label.modulate = Color(color.r, color.g, color.b, 1.0)
	label.visible = true

	var tween := label.create_tween()
	tween.tween_interval(duration)
	tween.tween_property(label, "modulate:a", 0.0, 0.35)
	tween.finished.connect(func() -> void:
		if is_instance_valid(label):
			label.visible = false
			label.modulate = Color(color.r, color.g, color.b, 1.0)
		)


static func is_play_scene_text_enabled() -> bool:
	return false


static func hide_label(label: Label) -> void:
	if label == null or not is_instance_valid(label):
		return
	label.text = ""
	label.visible = false
	label.modulate.a = 1.0


static func show_counter_label(label: Label, current: int, total: int) -> void:
	if label == null or not is_instance_valid(label):
		return
	var safe_total: int = maxi(0, total)
	var safe_current: int = clampi(current, 0, safe_total) if safe_total > 0 else maxi(0, current)
	label.text = "%d / %d" % [safe_current, safe_total]
	label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	label.visible = safe_total > 0


static func hide_play_scene_text(root: Node) -> void:
	if root == null or not is_instance_valid(root):
		return
	for child in root.get_children():
		if child is Label:
			hide_label(child as Label)
		hide_play_scene_text(child)


static func move_node_to(node: Node2D, target_position: Vector2, duration: float = 0.4) -> Tween:
	var tween := node.create_tween()
	tween.tween_property(node, "global_position", target_position, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	return tween
