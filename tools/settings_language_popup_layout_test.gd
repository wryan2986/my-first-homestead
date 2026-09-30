extends SceneTree

const SETTINGS_PANEL_SCENE := "res://scenes/settings_panel.tscn"
const LANGUAGE_TAB := "language"

var _failures: Array[String] = []
var _panel: Control


func _initialize() -> void:
	root.size = Vector2i(1280, 800)
	await process_frame
	_spawn_settings_panel()
	await _settle_layout()
	_force_test_panel_bounds()
	await _settle_layout()
	await _check_language_popup_position()
	await _report_and_quit()


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
	_panel.call("_set_active_settings_tab", LANGUAGE_TAB)


func _force_test_panel_bounds() -> void:
	if _panel == null:
		return
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	_panel.position = Vector2.ZERO
	_panel.size = Vector2(1280.0, 760.0)
	_panel.call("_set_active_settings_tab", LANGUAGE_TAB)
	_panel.call("_ensure_scroll_layout")


func _settle_layout() -> void:
	for i in range(5):
		await process_frame


func _check_language_popup_position() -> void:
	if _panel == null:
		return
	_panel.call("_on_language_dropdown_pressed")
	await _settle_layout()
	var popup := _panel.get_node_or_null("LanguageDropdownPopup") as Control
	if popup == null:
		_fail("Missing LanguageDropdownPopup.")
		return
	if not popup.visible:
		_fail("Language dropdown popup did not open.")
	var center_error := absf(popup.position.x + popup.size.x * 0.5 - _panel.size.x * 0.5)
	if center_error > 2.0:
		_fail("Language popup is not centered. Center error: %.2f." % center_error)
	if popup.position.x < 12.0 or popup.position.x + popup.size.x > _panel.size.x - 12.0:
		_fail("Language popup is outside notebook bounds.")


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report_and_quit() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.queue_free()
	for _i in 3:
		await process_frame
	if _failures.is_empty():
		print("SETTINGS_LANGUAGE_POPUP_LAYOUT_TEST_OK")
		quit(0)
	else:
		print("SETTINGS_LANGUAGE_POPUP_LAYOUT_TEST_FAILED")
		for failure in _failures:
			print(" - %s" % failure)
		quit(1)
