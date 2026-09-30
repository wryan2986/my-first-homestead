class_name MilkBucketFill
extends Node2D

@export var body_node: NodePath
@export var surface_node: NodePath
@export var shine_node: NodePath
@export var splash_texture: Texture2D
@export var empty_surface_y := -52.0
@export var full_surface_y := -82.0
@export var empty_half_width := 38.0
@export var full_half_width := 86.0
@export var surface_half_height := 11.0
@export var body_bottom_y := -34.0
@export var body_bottom_half_width := 58.0
@export var milk_body_color := Color("e4f1ff")
@export var milk_surface_color := Color("fbfdff")
@export var milk_shine_color := Color(1.0, 1.0, 1.0, 0.72)
@export var max_visible_body_depth := 32.0
@export var splash_burst_count := 4
@export var splash_burst_radius := 24.0
@export var splash_burst_duration := 0.4
@export var splash_burst_scale := Vector2(0.09, 0.09)

var _ratio := 0.0
var _display_ratio := 0.0
var _splash_tween: Tween
var _fill_tween: Tween
var _splash_root: Node2D
@onready var _body: Polygon2D = get_node_or_null(body_node) as Polygon2D
@onready var _surface: Polygon2D = get_node_or_null(surface_node) as Polygon2D
@onready var _shine: Polygon2D = get_node_or_null(shine_node) as Polygon2D


func _ready() -> void:
	set_fill_ratio(_ratio)


func set_fill_ratio(value: float) -> void:
	var target_ratio := clampf(value, 0.0, 1.0)
	if is_inside_tree() and visible and not is_equal_approx(target_ratio, _display_ratio):
		if is_instance_valid(_fill_tween):
			_fill_tween.kill()
		_fill_tween = create_tween()
		_fill_tween.tween_method(_draw_fill, _display_ratio, target_ratio, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		_draw_fill(target_ratio)


func _draw_fill(value: float) -> void:
	_ratio = clampf(value, 0.0, 1.0)
	_display_ratio = _ratio
	visible = _ratio > 0.0
	if not visible:
		return

	var surface_y := lerpf(empty_surface_y, full_surface_y, _ratio)
	var half_width := lerpf(empty_half_width, full_half_width, _ratio)
	var body_depth := lerpf(10.0, max_visible_body_depth, _ratio)
	var lower_y := minf(body_bottom_y, surface_y + body_depth)
	var lower_half_width := minf(body_bottom_half_width, half_width * 0.72)

	if _body != null:
		_body.color = milk_body_color
		_body.polygon = PackedVector2Array([
			Vector2(-half_width * 0.72, surface_y + surface_half_height * 0.36),
			Vector2(half_width * 0.72, surface_y + surface_half_height * 0.36),
			Vector2(lower_half_width, lower_y),
			Vector2(-lower_half_width, lower_y),
		])

	if _surface != null:
		_surface.color = milk_surface_color
		_surface.position = Vector2.ZERO
		_surface.polygon = _make_ellipse_points(Vector2(0.0, surface_y), half_width, surface_half_height, 18)

	if _shine != null:
		_shine.color = milk_shine_color
		_shine.polygon = _make_ellipse_points(
			Vector2(-half_width * 0.32, surface_y - 2.0),
			maxf(10.0, half_width * 0.26),
			maxf(3.0, surface_half_height * 0.32),
			12
		)


func play_splash() -> void:
	if _surface == null or not visible:
		return
	if is_instance_valid(_splash_tween):
		_splash_tween.kill()
	if is_instance_valid(_splash_root):
		_splash_root.queue_free()
		_splash_root = null
	_surface.scale = Vector2.ONE
	if _shine != null:
		_shine.scale = Vector2.ONE
		var shine_modulate := _shine.modulate
		shine_modulate.a = 0.9
		_shine.modulate = shine_modulate
	_splash_tween = create_tween()
	_splash_tween.tween_property(_surface, "scale", Vector2(1.08, 0.9), 0.07)
	if _shine != null:
		_splash_tween.parallel().tween_property(_shine, "scale", Vector2(1.12, 1.02), 0.07)
	_splash_tween.tween_property(_surface, "scale", Vector2.ONE, 0.14)
	if _shine != null:
		_splash_tween.parallel().tween_property(_shine, "scale", Vector2.ONE, 0.14)
		_splash_tween.parallel().tween_property(_shine, "modulate:a", 0.72, 0.14)
	_spawn_splash_burst()


func _spawn_splash_burst() -> void:
	if splash_texture == null:
		return

	var splash_root := Node2D.new()
	splash_root.name = "MilkSplashBurst"
	splash_root.global_position = _surface.global_position
	add_child(splash_root)
	_splash_root = splash_root

	var burst_count: int = maxi(1, splash_burst_count)
	for index in range(burst_count):
		var splash := Sprite2D.new()
		splash.texture = splash_texture
		splash.modulate = Color(1.0, 1.0, 1.0, 0.74)
		splash.scale = splash_burst_scale * (1.0 + float(index % 3) * 0.16)
		splash.rotation_degrees = float(index) * 22.0
		var angle := TAU * float(index) / float(burst_count)
		var start_offset := Vector2(cos(angle), sin(angle)) * 4.0
		splash.position = start_offset
		_splash_root.add_child(splash)

		var target_offset := Vector2(cos(angle), sin(angle)) * splash_burst_radius
		target_offset.y -= 12.0
		var tween := splash.create_tween()
		tween.tween_property(splash, "position", target_offset, splash_burst_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(splash, "scale", splash.scale * 0.55, splash_burst_duration)
		tween.parallel().tween_property(splash, "modulate:a", 0.0, splash_burst_duration)

	var cleanup_timer := get_tree().create_timer(splash_burst_duration + 0.12)
	cleanup_timer.timeout.connect(func() -> void:
		if is_instance_valid(splash_root):
			splash_root.queue_free()
		if _splash_root == splash_root:
			_splash_root = null
	)


func _make_ellipse_points(center: Vector2, half_width: float, half_height: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(center + Vector2(cos(angle) * half_width, sin(angle) * half_height))
	return points
