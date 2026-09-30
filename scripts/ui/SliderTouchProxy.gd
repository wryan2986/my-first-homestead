class_name SliderTouchProxy
extends Control

@export var horizontal_padding := 24.0
@export var track_color := Color("c6c2ad")
@export var fill_color := Color("7fc66e")
@export var border_color := Color("5b4129")
@export var knob_color := Color("fff7df")
@export var knob_shadow_color := Color(0.28, 0.19, 0.12, 0.22)
@export var track_height := 26.0
@export var knob_radius := 32.0

var target_slider: HSlider
var _dragging := false
var _pending_touch := false
var _press_position := Vector2.ZERO


func configure(slider: HSlider, padding: float = 24.0) -> void:
	if target_slider != null and is_instance_valid(target_slider):
		var old_callable := Callable(self, "_on_target_value_changed")
		if target_slider.value_changed.is_connected(old_callable):
			target_slider.value_changed.disconnect(old_callable)
	target_slider = slider
	horizontal_padding = padding
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE
	if target_slider != null and is_instance_valid(target_slider):
		var new_callable := Callable(self, "_on_target_value_changed")
		if not target_slider.value_changed.is_connected(new_callable):
			target_slider.value_changed.connect(new_callable)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if target_slider == null or not is_instance_valid(target_slider) or not target_slider.editable:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			_apply_pointer_position(event.position)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_apply_pointer_position(event.position)
		accept_event()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_pending_touch = true
			_dragging = false
			_press_position = touch.position
			return
		if _dragging:
			_apply_pointer_position(touch.position)
			accept_event()
		elif _pending_touch and touch.position.distance_to(_press_position) <= 8.0:
			_apply_pointer_position(touch.position)
			accept_event()
		_pending_touch = false
		_dragging = false
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _pending_touch and not _dragging:
			var delta := drag.position - _press_position
			if absf(delta.y) > 6.0 and absf(delta.y) >= absf(delta.x) * 0.6:
				_pending_touch = false
				return
			if absf(delta.x) > 24.0 and absf(delta.x) > absf(delta.y) * 2.0:
				_dragging = true
				_pending_touch = false
		if _dragging:
			_apply_pointer_position(drag.position)
			accept_event()


func _apply_pointer_position(local_position: Vector2) -> void:
	var track_width := maxf(1.0, size.x - horizontal_padding * 2.0)
	var ratio := clampf((local_position.x - horizontal_padding) / track_width, 0.0, 1.0)
	var value := lerpf(float(target_slider.min_value), float(target_slider.max_value), ratio)
	if target_slider.step > 0.0:
		value = snappedf(value, float(target_slider.step))
	target_slider.value = clampf(value, float(target_slider.min_value), float(target_slider.max_value))


func _draw() -> void:
	if target_slider == null or not is_instance_valid(target_slider):
		return
	var center_y := size.y * 0.5
	var left_x := horizontal_padding
	var right_x := maxf(left_x + 1.0, size.x - horizontal_padding)
	var slider_range := maxf(0.0001, float(target_slider.max_value - target_slider.min_value))
	var ratio := clampf(float(target_slider.value - target_slider.min_value) / slider_range, 0.0, 1.0)
	var knob_x := lerpf(left_x, right_x, ratio)
	var radius := track_height * 0.5

	_draw_track(left_x, right_x, center_y, radius, track_color)
	if knob_x > left_x + 0.5:
		_draw_track(left_x, knob_x, center_y, radius, fill_color)
	draw_line(Vector2(left_x, center_y), Vector2(right_x, center_y), border_color, 4.0, true)
	draw_circle(Vector2(knob_x, center_y + 4.0), knob_radius, knob_shadow_color)
	draw_circle(Vector2(knob_x, center_y), knob_radius, knob_color)
	draw_arc(Vector2(knob_x, center_y), knob_radius, 0.0, TAU, 40, border_color, 5.0, true)


func _draw_track(left_x: float, right_x: float, center_y: float, radius: float, color: Color) -> void:
	draw_line(Vector2(left_x, center_y), Vector2(right_x, center_y), color, radius * 2.0, true)
	draw_circle(Vector2(left_x, center_y), radius, color)
	draw_circle(Vector2(right_x, center_y), radius, color)


func _on_target_value_changed(_value: float) -> void:
	queue_redraw()
