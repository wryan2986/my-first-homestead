extends SceneTree

const SETTINGS_PANEL_SCENE := "res://scenes/settings_panel.tscn"
const LANGUAGE_TAB := "language"

var _failures: Array[String] = []
var _panel: Control
var _game_settings: Node
var _original_locale := ""
var _original_translation_locale := ""


func _initialize() -> void:
	root.size = Vector2i(1280, 800)
	await process_frame
	_game_settings = root.get_node_or_null("GameSettings")
	if _game_settings == null:
		_fail("Missing GameSettings autoload.")
		_report_and_quit()
		return
	_original_locale = String(_game_settings.get("active_locale"))
	_original_translation_locale = TranslationServer.get_locale()
	_spawn_settings_panel()
	await _settle_layout()
	_force_test_panel_bounds()
	await _settle_layout()
	await _check_scrollable_policy()
	await _check_live_locale_change()
	_restore_locale()
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
	for i in range(6):
		await process_frame


func _check_scrollable_policy() -> void:
	if _panel == null:
		return
	_panel.call("_on_privacy_policy_pressed")
	await _settle_layout()
	var overlay := _panel.get_node_or_null("PrivacyPolicyOverlay") as Control
	var scroll := _panel.get_node_or_null("PrivacyPolicyOverlay/Scroll") as ScrollContainer
	var text := _panel.get_node_or_null("PrivacyPolicyOverlay/Scroll/Text") as RichTextLabel
	if overlay == null or scroll == null or text == null:
		_fail("Privacy policy overlay is missing its scroll controls.")
		return
	if not overlay.visible:
		_fail("Privacy policy overlay did not open.")
	if not text.fit_content:
		_fail("Privacy policy text must grow to its full content height.")
	if text.mouse_filter == Control.MOUSE_FILTER_STOP:
		_fail("Privacy policy text blocks swipe input from reaching the ScrollContainer.")
	if text.size.y <= scroll.size.y:
		_fail("Privacy policy content does not extend beyond the visible scroll area.")
		return
	scroll.scroll_vertical = 300
	await _settle_layout()
	if scroll.scroll_vertical <= 0:
		_fail("Privacy policy ScrollContainer did not accept a vertical scroll offset.")


func _check_live_locale_change() -> void:
	if _panel == null or _game_settings == null:
		return
	_game_settings.set("active_locale", "es")
	TranslationServer.set_locale("es")
	_panel.call("_on_locale_changed", "es")
	await _settle_layout()
	var title := _panel.get_node_or_null("PrivacyPolicyOverlay/Title") as Label
	var done_button := _panel.get_node_or_null("PrivacyPolicyOverlay/CloseButton") as Button
	var text := _panel.get_node_or_null("PrivacyPolicyOverlay/Scroll/Text") as RichTextLabel
	if title == null or title.text != "Política de privacidad":
		_fail("Privacy policy title did not update to Spanish.")
	if done_button == null or done_button.text != "Listo":
		_fail("Privacy policy close button did not update to Spanish.")
	if text == null or not text.text.begins_with("POLÍTICA DE PRIVACIDAD"):
		_fail("Privacy policy body did not reload in Spanish.")


func _restore_locale() -> void:
	if _game_settings != null:
		_game_settings.set("active_locale", _original_locale)
	TranslationServer.set_locale(_original_translation_locale)


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report_and_quit() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.queue_free()
	if _failures.is_empty():
		print("SETTINGS_PRIVACY_POLICY_TEST_OK")
		quit(0)
	else:
		print("SETTINGS_PRIVACY_POLICY_TEST_FAILED")
		for failure in _failures:
			print(" - %s" % failure)
		quit(1)
