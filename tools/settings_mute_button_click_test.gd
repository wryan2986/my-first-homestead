extends SceneTree

const SETTINGS_PANEL_SCENE := "res://scenes/settings_panel.tscn"
const SOUND_TAB := "sound"

var _failures: Array[String] = []
var _panel: Control
var _music_manager: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 800)
	await process_frame
	_music_manager = root.get_node_or_null("MusicManager")
	if _music_manager == null:
		_fail("Missing MusicManager autoload.")
		_report_and_quit()
		return
	_configure_audio_start_state()
	_spawn_settings_panel()
	await _settle_layout()
	_force_test_panel_bounds()
	await _settle_layout()
	_check_mute_button_hitboxes()
	await _check_button("MasterMuteButton", "MasterVolumeSlider", "MasterVolumeSliderTouchProxy", "is_master_muted", "get_master_volume", false, false)
	await _check_button("MusicMuteButton", "MusicVolumeSlider", "MusicVolumeSliderTouchProxy", "is_music_muted", "get_music_volume", false, false)
	await _check_button("SfxMuteButton", "SfxVolumeSlider", "SfxVolumeSliderTouchProxy", "is_sfx_muted", "get_sfx_volume", false, false)
	await _check_button("VoiceOverMuteButton", "VoiceOverVolumeSlider", "VoiceOverVolumeSliderTouchProxy", "is_voice_over_muted", "get_voice_over_volume", false, false)
	await _check_button("MasterMuteButton", "MasterVolumeSlider", "MasterVolumeSliderTouchProxy", "is_master_muted", "get_master_volume", true, false)
	await _check_button("MusicMuteButton", "MusicVolumeSlider", "MusicVolumeSliderTouchProxy", "is_music_muted", "get_music_volume", true, false)
	await _check_button("SfxMuteButton", "SfxVolumeSlider", "SfxVolumeSliderTouchProxy", "is_sfx_muted", "get_sfx_volume", true, false)
	await _check_button("VoiceOverMuteButton", "VoiceOverVolumeSlider", "VoiceOverVolumeSliderTouchProxy", "is_voice_over_muted", "get_voice_over_volume", true, false)
	await _check_button("MasterMuteButton", "MasterVolumeSlider", "MasterVolumeSliderTouchProxy", "is_master_muted", "get_master_volume", false, true)
	await _check_button("MusicMuteButton", "MusicVolumeSlider", "MusicVolumeSliderTouchProxy", "is_music_muted", "get_music_volume", false, true)
	await _check_button("SfxMuteButton", "SfxVolumeSlider", "SfxVolumeSliderTouchProxy", "is_sfx_muted", "get_sfx_volume", false, true)
	await _check_button("VoiceOverMuteButton", "VoiceOverVolumeSlider", "VoiceOverVolumeSliderTouchProxy", "is_voice_over_muted", "get_voice_over_volume", false, true)
	await _check_button("MasterMuteButton", "MasterVolumeSlider", "MasterVolumeSliderTouchProxy", "is_master_muted", "get_master_volume", true, true)
	await _check_button("MusicMuteButton", "MusicVolumeSlider", "MusicVolumeSliderTouchProxy", "is_music_muted", "get_music_volume", true, true)
	await _check_button("SfxMuteButton", "SfxVolumeSlider", "SfxVolumeSliderTouchProxy", "is_sfx_muted", "get_sfx_volume", true, true)
	await _check_button("VoiceOverMuteButton", "VoiceOverVolumeSlider", "VoiceOverVolumeSliderTouchProxy", "is_voice_over_muted", "get_voice_over_volume", true, true)
	_report_and_quit()


func _configure_audio_start_state() -> void:
	_music_manager.call("set_master_volume", 0.8)
	_music_manager.call("set_music_volume", 0.7)
	_music_manager.call("set_sfx_volume", 0.6)
	_music_manager.call("set_voice_over_volume", 0.9)


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
	_panel.call("_set_active_settings_tab", SOUND_TAB)


func _force_test_panel_bounds() -> void:
	if _panel == null:
		return
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	_panel.position = Vector2.ZERO
	_panel.size = Vector2(1280.0, 760.0)
	_panel.call("_set_active_settings_tab", SOUND_TAB)
	_panel.call("_ensure_scroll_layout")


func _settle_layout() -> void:
	for i in range(5):
		await process_frame


func _check_mute_button_hitboxes() -> void:
	for button_name in ["MasterMuteButton", "MusicMuteButton", "SfxMuteButton", "VoiceOverMuteButton"]:
		var button := _find_control(button_name) as Button
		if button == null:
			_fail("Missing mute button: %s" % button_name)
			continue
		if not button.visible:
			_fail("%s is not visible on the Sound tab." % button_name)
		if button.disabled:
			_fail("%s is disabled on the Sound tab." % button_name)
		if button.mouse_filter != Control.MOUSE_FILTER_STOP:
			_fail("%s does not stop mouse input." % button_name)
		var button_proxy := _find_control("%sTouchProxy" % button_name)
		if button_proxy == null:
			_fail("%sTouchProxy is missing." % button_name)
		elif button_proxy.get_global_rect() != button.get_global_rect():
			_fail("%sTouchProxy is not aligned. button=%s proxy=%s" % [button_name, str(button.get_global_rect()), str(button_proxy.get_global_rect())])

	for pair in [
		["MasterMuteButton", "MasterVolumeSliderTouchProxy"],
		["MusicMuteButton", "MusicVolumeSliderTouchProxy"],
		["SfxMuteButton", "SfxVolumeSliderTouchProxy"],
		["VoiceOverMuteButton", "VoiceOverVolumeSliderTouchProxy"],
	]:
		var button := _find_control(pair[0])
		var proxy := _find_control(pair[1])
		if button == null or proxy == null:
			continue
		var button_rect := button.get_global_rect()
		var proxy_rect := proxy.get_global_rect()
		if proxy_rect.intersects(button_rect):
			_fail("%s overlaps %s. button=%s proxy=%s path=%s" % [pair[1], pair[0], str(button_rect), str(proxy_rect), str(proxy.get_path())])
		if proxy_rect.has_point(button_rect.get_center()):
			_fail("%s contains the click center for %s." % [pair[1], pair[0]])


func _check_button(button_name: String, slider_name: String, proxy_name: String, muted_getter: String, volume_getter: String, use_upper_left: bool, use_screen_touch: bool) -> void:
	var button := _find_control(button_name) as Button
	var slider := _find_control(slider_name) as HSlider
	var proxy := _find_control(proxy_name)
	if button == null or slider == null or proxy == null:
		_fail("Missing controls for %s." % button_name)
		return

	var unrelated_before := _read_unrelated_slider_values(slider_name)
	if bool(_music_manager.call(muted_getter)):
		_fail("%s started muted before the click test." % button_name)
		return

	_scroll_to_control(button)
	await _settle_layout()
	await _click_control(button, use_upper_left, use_screen_touch)
	if not bool(_music_manager.call(muted_getter)):
		_fail("%s did not mute from a real viewport %s %s." % [button_name, _click_label(use_upper_left), _event_label(use_screen_touch)])
	if absf(float(_music_manager.call(volume_getter)) - float(slider.value)) > 0.001:
		_fail("%s slider value did not match MusicManager after muting." % slider_name)
	_check_unrelated_slider_values(slider_name, unrelated_before, "muting %s" % button_name)

	_scroll_to_control(button)
	await _settle_layout()
	await _click_control(button, use_upper_left, use_screen_touch)
	if bool(_music_manager.call(muted_getter)):
		_fail("%s did not unmute from a second real viewport %s %s." % [button_name, _click_label(use_upper_left), _event_label(use_screen_touch)])
	if absf(float(_music_manager.call(volume_getter)) - float(slider.value)) > 0.001:
		_fail("%s slider value did not match MusicManager after unmuting." % slider_name)
	_check_unrelated_slider_values(slider_name, unrelated_before, "unmuting %s" % button_name)


func _click_control(control: Control, use_upper_left: bool, use_screen_touch: bool) -> void:
	var rect := control.get_global_rect()
	var center := rect.position + Vector2(24.0, 24.0) if use_upper_left else rect.get_center()
	if use_screen_touch:
		await _touch_position(center)
		return
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
	release.button_mask = 0
	release.pressed = false
	release.position = center
	release.global_position = center
	root.push_input(release, true)
	await _settle_layout()


func _touch_position(position: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = position
	root.push_input(press, true)
	await process_frame

	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = position
	root.push_input(release, true)
	await _settle_layout()


func _click_label(use_upper_left: bool) -> String:
	return "upper-left" if use_upper_left else "center"


func _event_label(use_screen_touch: bool) -> String:
	return "screen touch" if use_screen_touch else "mouse click"


func _read_unrelated_slider_values(skip_slider_name: String) -> Dictionary:
	var values := {}
	for slider_name in ["MasterVolumeSlider", "MusicVolumeSlider", "SfxVolumeSlider", "VoiceOverVolumeSlider"]:
		if slider_name == skip_slider_name:
			continue
		var slider := _find_control(slider_name) as HSlider
		if slider != null:
			values[slider_name] = slider.value
	return values


func _check_unrelated_slider_values(skip_slider_name: String, before: Dictionary, label: String) -> void:
	for slider_name in before.keys():
		var slider := _find_control(String(slider_name)) as HSlider
		if slider == null:
			_fail("Missing unrelated slider %s after %s." % [slider_name, label])
			continue
		if absf(float(slider.value) - float(before[slider_name])) > 0.001:
			_fail("%s changed unexpectedly while %s. before=%s after=%s" % [slider_name, label, str(before[slider_name]), str(slider.value)])


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
		print("SETTINGS_MUTE_BUTTON_CLICK_TEST_OK")
		quit(0)
	else:
		print("SETTINGS_MUTE_BUTTON_CLICK_TEST_FAILED")
		for failure in _failures:
			print(" - %s" % failure)
		quit(1)
