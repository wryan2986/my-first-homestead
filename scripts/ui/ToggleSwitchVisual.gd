class_name ToggleSwitchVisual
extends Control

@export var on_color := Color("78c86d")
@export var off_color := Color("b5b8b9")
@export var border_color := Color("4d3524")
@export var knob_color := Color("fff7df")
@export var knob_shadow_color := Color(0.28, 0.19, 0.12, 0.22)

var target_toggle: CheckButton


func configure(toggle: CheckButton) -> void:
	if target_toggle != null and is_instance_valid(target_toggle):
		var old_callable := Callable(self, "_on_target_toggled")
		if target_toggle.toggled.is_connected(old_callable):
			target_toggle.toggled.disconnect(old_callable)
	target_toggle = toggle
	# Keep this overlay visual-only so the underlying CheckButton owns input.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	if target_toggle != null and is_instance_valid(target_toggle):
		var new_callable := Callable(self, "_on_target_toggled")
		if not target_toggle.toggled.is_connected(new_callable):
			target_toggle.toggled.connect(new_callable)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var radius := rect.size.y * 0.5
	var track_rect := Rect2(Vector2(radius, 0.0), Vector2(maxf(0.0, rect.size.x - radius * 2.0), rect.size.y))
	var enabled := target_toggle != null and is_instance_valid(target_toggle) and target_toggle.button_pressed
	var track_color := on_color if enabled else off_color
	_draw_capsule(track_rect, radius, track_color)
	_draw_capsule(track_rect, radius, Color(border_color.r, border_color.g, border_color.b, 0.86), 5.0)

	var knob_radius := maxf(8.0, rect.size.y * 0.36)
	var knob_x := rect.size.x - radius if enabled else radius
	var knob_center := Vector2(knob_x, rect.size.y * 0.5)
	draw_circle(knob_center + Vector2(0.0, rect.size.y * 0.045), knob_radius, knob_shadow_color)
	draw_circle(knob_center, knob_radius, knob_color)
	draw_arc(knob_center, knob_radius, 0.0, TAU, 36, border_color, 4.0, true)


func _draw_capsule(center_rect: Rect2, radius: float, color: Color, width := -1.0) -> void:
	var left_center := Vector2(center_rect.position.x, center_rect.position.y + radius)
	var right_center := Vector2(center_rect.position.x + center_rect.size.x, center_rect.position.y + radius)
	if width < 0.0:
		draw_rect(Rect2(Vector2(left_center.x, 0.0), Vector2(maxf(0.0, right_center.x - left_center.x), radius * 2.0)), color)
		draw_circle(left_center, radius, color)
		draw_circle(right_center, radius, color)
		return
	draw_arc(left_center, radius - width * 0.5, PI * 0.5, PI * 1.5, 24, color, width, true)
	draw_arc(right_center, radius - width * 0.5, -PI * 0.5, PI * 0.5, 24, color, width, true)
	draw_line(Vector2(left_center.x, width * 0.5), Vector2(right_center.x, width * 0.5), color, width, true)
	draw_line(Vector2(left_center.x, radius * 2.0 - width * 0.5), Vector2(right_center.x, radius * 2.0 - width * 0.5), color, width, true)


func _on_target_toggled(_enabled: bool) -> void:
	queue_redraw()
