extends SceneTree

const SETTINGS_PANEL_SCENE := "res://scenes/settings_panel.tscn"
const GAMEPLAY_TAB := "gameplay"

var _failures: Array[String] = []
var _panel: Control
var _game_settings: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 800)
	await process_frame
	_game_settings = root.get_node_or_null("GameSettings")
	if _game_settings == null:
		_fail("Missing GameSettings autoload.")
		_report_and_quit()
		return
	_spawn_settings_panel()
	await _settle_layout()
	_force_test_panel_bounds()
	await _settle_layout()
	await _check_timer("duck_pond")
	await _check_timer("mole_garden")
	_report_and_quit()


func _spawn_settings_panel() -> void:
	var packed := load(SETTINGS_PANEL_SCENE) as PackedScene
	if packed == null:
		_fail("Could not load %s" % SETTINGS_PANEL_SCENE)
		return
	_panel = packed.instantiate() as Control
	if _panel == null:
		_fail("Could not instantiate settings panel as Control.")
		return
	root.add_child(_panel)
	_panel.call("open")
	_panel.call("_set_active_settings_tab", GAMEPLAY_TAB)


func _force_test_panel_bounds() -> void:
	if _panel == null:
		return
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	_panel.position = Vector2.ZERO
	_panel.size = Vector2(1280.0, 760.0)
	_panel.call("_set_active_settings_tab", GAMEPLAY_TAB)
	_panel.call("_ensure_scroll_layout")


func _settle_layout() -> void:
	for i in range(5):
		await process_frame


func _check_timer(timer_id: String) -> void:
	var prefix := timer_id.capitalize().replace(" ", "")
	var custom_chip := _find_control("%sTimerCustomChip" % prefix) as Button
	var minus_button := _find_control("%sTimerCustomMinus" % prefix) as Button
	var value_label := _find_control("%sTimerCustomValue" % prefix) as Label
	var plus_button := _find_control("%sTimerCustomPlus" % prefix) as Button
	var timeout_toggle := _find_control("%sTimeoutToggle" % prefix) as CheckButton
	if custom_chip == null or minus_button == null or value_label == null or plus_button == null or timeout_toggle == null:
		_fail("Missing custom stepper controls for %s." % timer_id)
		return

	_set_timer_seconds(timer_id, 300.0)
	_set_timer_enabled(timer_id, false)
	_panel.call("refresh")
	await _settle_layout()
	if custom_chip.visible:
		_fail("%s timer chips should be hidden while the timer is off." % timer_id)
	if minus_button.visible or value_label.visible or plus_button.visible:
		_fail("%s custom stepper should be hidden while the timer is off." % timer_id)
	if timeout_toggle.text.find("minutes") >= 0:
		_fail("%s off label should not include the saved duration: %s." % [timer_id, timeout_toggle.text])

	await _click_control(timeout_toggle)
	if not bool(_get_timer_enabled(timer_id)):
		_fail("%s toggle click did not enable the timer." % timer_id)
	if not custom_chip.visible:
		_fail("%s timer chips did not reappear after enabling the timer." % timer_id)
	if timeout_toggle.text.find("5 minutes") < 0:
		_fail("%s on label did not restore the saved duration: %s." % [timer_id, timeout_toggle.text])
	if minus_button.visible or value_label.visible or plus_button.visible:
		_fail("%s custom stepper should be hidden before Custom is pressed." % timer_id)

	await _click_control(custom_chip)
	if not (minus_button.visible and value_label.visible and plus_button.visible):
		_fail("%s custom stepper did not appear after Custom was pressed." % timer_id)
	if value_label.text != "5 minutes":
		_fail("%s custom stepper value label was %s, expected 5 minutes." % [timer_id, value_label.text])

	await _click_control(plus_button)
	if _get_timer_minutes(timer_id) != 6:
		_fail("%s plus button did not increment to 6 minutes." % timer_id)
	if value_label.text != "6 minutes":
		_fail("%s value label did not update after plus: %s." % [timer_id, value_label.text])

	await _click_control(minus_button)
	if _get_timer_minutes(timer_id) != 5:
		_fail("%s minus button did not decrement to 5 minutes." % timer_id)
	if value_label.text != "5 minutes":
		_fail("%s value label did not update after minus: %s." % [timer_id, value_label.text])

	await _click_control(plus_button)
	await _click_control(timeout_toggle)
	await _click_control(timeout_toggle)
	if _get_timer_minutes(timer_id) != 6:
		_fail("%s custom duration was not preserved across off/on." % timer_id)
	if value_label.text != "6 minutes":
		_fail("%s custom stepper label did not restore after off/on: %s." % [timer_id, value_label.text])


func _set_timer_seconds(timer_id: String, seconds: float) -> void:
	if timer_id == "duck_pond":
		_game_settings.call("set_duck_pond_time_limit_seconds", seconds)
	elif timer_id == "mole_garden":
		_game_settings.call("set_mole_garden_time_limit_seconds", seconds)


func _set_timer_enabled(timer_id: String, enabled: bool) -> void:
	if timer_id == "duck_pond":
		_game_settings.call("set_duck_pond_time_limit_enabled", enabled)
	elif timer_id == "mole_garden":
		_game_settings.call("set_mole_garden_time_limit_enabled", enabled)


func _get_timer_enabled(timer_id: String) -> bool:
	if timer_id == "duck_pond":
		return bool(_game_settings.call("is_duck_pond_time_limit_enabled"))
	if timer_id == "mole_garden":
		return bool(_game_settings.call("is_mole_garden_time_limit_enabled"))
	return false


func _get_timer_minutes(timer_id: String) -> int:
	if timer_id == "duck_pond":
		return roundi(float(_game_settings.call("get_duck_pond_time_limit_seconds")) / 60.0)
	if timer_id == "mole_garden":
		return roundi(float(_game_settings.call("get_mole_garden_time_limit_seconds")) / 60.0)
	return 0


func _click_control(control: Control) -> void:
	_scroll_to_control(control)
	await _settle_layout()
	var center := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	motion.global_position = center
	root.push_input(motion, true)
	await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = center
	press.global_position = center
	root.push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = center
	release.global_position = center
	root.push_input(release, true)
	await _settle_layout()


func _scroll_to_control(control: Control) -> void:
	var scroll := _panel.get_node_or_null("SettingsScroll") as ScrollContainer
	if scroll == null or control == null:
		return
	scroll.scroll_vertical = max(0, roundi(control.position.y - 42.0))


func _find_control(node_name: String) -> Control:
	if _panel == null:
		return null
	return _find_control_recursive(_panel, node_name)


func _find_control_recursive(node: Node, node_name: String) -> Control:
	if node.name == node_name and node is Control:
		return node as Control
	for child in node.get_children():
		var found := _find_control_recursive(child, node_name)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report_and_quit() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.queue_free()
	if _failures.is_empty():
		print("SETTINGS_TIMER_STEPPER_TEST_OK")
		quit(0)
	else:
		print("SETTINGS_TIMER_STEPPER_TEST_FAILED")
		for failure in _failures:
			print(" - %s" % failure)
		quit(1)
