class_name ButtonTouchProxy
extends Control

@export var tap_slop := 12.0
@export var scroll_slop := 10.0

var target_button: Button
var _pending_touch := false
var _press_position := Vector2.ZERO


func configure(button: Button) -> void:
	target_button = button
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE


func _gui_input(event: InputEvent) -> void:
	if target_button == null or not is_instance_valid(target_button) or target_button.disabled:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var button_event := event as InputEventMouseButton
		if button_event.pressed:
			_pending_touch = true
			_press_position = button_event.position
			accept_event()
			return
		if _pending_touch and button_event.position.distance_to(_press_position) <= tap_slop:
			_press_target()
			accept_event()
		_pending_touch = false
	elif event is InputEventMouseMotion and _pending_touch:
		var motion := event as InputEventMouseMotion
		if motion.position.distance_to(_press_position) > tap_slop:
			_pending_touch = false
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_pending_touch = true
			_press_position = touch.position
			accept_event()
			return
		if _pending_touch and touch.position.distance_to(_press_position) <= tap_slop:
			_press_target()
			accept_event()
		_pending_touch = false
	elif event is InputEventScreenDrag and _pending_touch:
		var drag := event as InputEventScreenDrag
		var delta := drag.position - _press_position
		if absf(delta.y) > scroll_slop and absf(delta.y) >= absf(delta.x):
			_pending_touch = false
			return
		if delta.length() > tap_slop:
			_pending_touch = false


func _press_target() -> void:
	target_button.emit_signal("pressed")
