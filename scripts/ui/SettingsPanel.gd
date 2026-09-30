class_name AudioSettingsPanel
extends Panel

const SliderTouchProxyScript := preload("res://scripts/ui/SliderTouchProxy.gd")
const ToggleTouchProxyScript := preload("res://scripts/ui/SettingsToggleTouchProxy.gd")
const ButtonTouchProxyScript := preload("res://scripts/ui/ButtonTouchProxy.gd")
const ToggleSwitchVisualScript := preload("res://scripts/ui/ToggleSwitchVisual.gd")
const SoundTabIcon := preload("res://art/effects/music_note_soft.png")
const GameplayTabIcon := preload("res://art/garden/sprout.png")
const PRIVACY_POLICY_PATH := "res://resources/privacy_policy.txt"
const PRIVACY_POLICY_URL := "https://github.com/wryan2986/my-first-homestead-privacy"
const PRIVACY_POLICY_PATHS := {
	"ar": "res://resources/privacy_policy_ar.txt",
	"de": "res://resources/privacy_policy_de.txt",
	"es": "res://resources/privacy_policy_es.txt",
	"fr": "res://resources/privacy_policy_fr.txt",
	"hi": "res://resources/privacy_policy_hi.txt",
	"it": "res://resources/privacy_policy_it.txt",
	"ja": "res://resources/privacy_policy_ja.txt",
	"ko": "res://resources/privacy_policy_ko.txt",
	"pt-BR": "res://resources/privacy_policy_pt_br.txt",
	"zh-CN": "res://resources/privacy_policy_zh_cn.txt",
}
const SETTINGS_TAB_LANGUAGE := "language"
const SETTINGS_TAB_SOUND := "sound"
const SETTINGS_TAB_GAMEPLAY := "gameplay"
const SETTINGS_SOUND_CONTENT_HEIGHT := 940.0
const SETTINGS_GAMEPLAY_CONTENT_HEIGHT := 850.0
const SETTINGS_LANGUAGE_CONTENT_HEIGHT := 520.0
const SETTINGS_CONTENT_BOTTOM_PADDING := 180.0
const SETTINGS_PANEL_MIN_SIZE := Vector2(1060.0, 760.0)
const SETTINGS_PANEL_MAX_SIZE := Vector2(1900.0, 1040.0)
const SETTINGS_PANEL_MARGIN := Vector2(12.0, 12.0)
const SETTINGS_TABS_POSITION := Vector2(36.0, 146.0)
const SETTINGS_TABS_HEIGHT := 96.0
const SETTINGS_SCROLL_POSITION := Vector2(36.0, 266.0)
const SETTINGS_SCROLL_MIN_SIZE := Vector2(920.0, 420.0)
const SETTINGS_CONTENT_SIDE_GUTTER := 96.0
const SETTINGS_CONTENT_MAX_WIDTH := 1180.0
const SETTINGS_TOGGLE_ROW_HEIGHT := 126.0
const SETTINGS_TOGGLE_FONT_SIZE := 48
const SETTINGS_CARD_TOP := 0.0
const SETTINGS_CARD_HEIGHT := 204.0
const SETTINGS_CARD_GAP := 24.0
const SETTINGS_TIMER_CARD_HEIGHT := 252.0
const SETTINGS_TIMER_CHIP_SIZE := Vector2(150.0, 68.0)
const SETTINGS_TIMER_CUSTOM_CHIP_SIZE := Vector2(198.0, 68.0)
const SETTINGS_TIMER_STEPPER_BUTTON_SIZE := Vector2(72.0, 68.0)
const SETTINGS_TIMER_STEPPER_LABEL_SIZE := Vector2(154.0, 68.0)
const SETTINGS_TIMER_CHIP_GAP := 14.0
const SETTINGS_TIMER_HEADER_TOUCH_HEIGHT := 118.0
const SETTINGS_TIMER_PRESETS := [60.0, 120.0, 180.0, 300.0]
const SETTINGS_TIMER_OPTIONS_TOP_GAP := 16.0
const SETTINGS_TIMER_BLOCK_GAP := 70.0
const SETTINGS_TIMER_DISABLED_GAP := 24.0
const SETTINGS_TESTER_TO_TIMER_GAP := 20.0
const SETTINGS_LABEL_HEIGHT := 60.0
const SETTINGS_SLIDER_HEIGHT := 116.0
const SETTINGS_SOUND_MUTE_COLUMN_WIDTH := 240.0
const SETTINGS_SLIDER_TOUCH_PADDING := 40.0
const SETTINGS_SLIDER_VERTICAL_PADDING := 6.0
const SETTINGS_SCROLLBAR_THICKNESS := 36.0
const SETTINGS_TOGGLE_MIN_SIZE := Vector2(0.0, SETTINGS_TOGGLE_ROW_HEIGHT)
const SETTINGS_TOGGLE_SWITCH_SIZE := Vector2(170.0, 88.0)
const SETTINGS_TOGGLE_SWITCH_RIGHT_PADDING := 8.0
const NOTEBOOK_TEXT_COLOR := Color("4f3524")
const NOTEBOOK_BORDER_COLOR := Color("b9793a")
const NOTEBOOK_DARK_BORDER_COLOR := Color("6c4427")
const NOTEBOOK_PAPER_COLOR := Color(1.0, 0.965, 0.79, 0.86)
const NOTEBOOK_ROW_COLOR := Color(1.0, 0.975, 0.83, 0.66)
const NOTEBOOK_TAB_ACTIVE_COLOR := Color("f2c96e")
const NOTEBOOK_TAB_INACTIVE_COLOR := Color(0.94, 0.82, 0.55, 0.82)
const NOTEBOOK_GREEN := Color("78c66a")
const NOTEBOOK_SOFT_GREEN := Color("a9dc86")

signal closed
signal tester_action_requested(action: String, payload: Variant)

@export var close_button_path := NodePath("CloseButton")
@export var music_toggle_path := NodePath("MusicToggle")
@export var voice_over_toggle_path := NodePath("VoiceOverToggle")
@export var master_volume_slider_path := NodePath("MasterVolumeSlider")
@export var music_volume_slider_path := NodePath("MusicVolumeSlider")
@export var sfx_volume_slider_path := NodePath("SfxVolumeSlider")
@export var voice_over_volume_slider_path := NodePath("VoiceOverVolumeSlider")
@export var master_volume_label_path := NodePath("MasterVolumeLabel")
@export var music_volume_label_path := NodePath("MusicVolumeLabel")
@export var sfx_volume_label_path := NodePath("SfxVolumeLabel")
@export var voice_over_volume_label_path := NodePath("VoiceOverVolumeLabel")
@export var preview_sound: AudioStream
@export var scroll_view_position := SETTINGS_SCROLL_POSITION
@export var scroll_view_size := Vector2(972.0, 690.0)
@export var slider_touch_size := Vector2(820.0, SETTINGS_SLIDER_HEIGHT)
@export var tester_tools_enabled := false

@onready var _close_button: Button = get_node_or_null(close_button_path) as Button
@onready var _music_toggle: CheckButton = get_node_or_null(music_toggle_path) as CheckButton
@onready var _voice_over_toggle: CheckButton = get_node_or_null(voice_over_toggle_path) as CheckButton
@onready var _master_volume_slider: HSlider = get_node_or_null(master_volume_slider_path) as HSlider
@onready var _music_volume_slider: HSlider = get_node_or_null(music_volume_slider_path) as HSlider
@onready var _sfx_volume_slider: HSlider = get_node_or_null(sfx_volume_slider_path) as HSlider
@onready var _voice_over_volume_slider: HSlider = get_node_or_null(voice_over_volume_slider_path) as HSlider
@onready var _master_volume_label: Label = get_node_or_null(master_volume_label_path) as Label
@onready var _music_volume_label: Label = get_node_or_null(music_volume_label_path) as Label
@onready var _sfx_volume_label: Label = get_node_or_null(sfx_volume_label_path) as Label
@onready var _voice_over_volume_label: Label = get_node_or_null(voice_over_volume_label_path) as Label

var _syncing_settings := false
var _scroll_area: ScrollContainer
var _settings_content: Control
var _duck_pond_timeout_toggle: CheckButton
var _mole_garden_timeout_toggle: CheckButton
var _tap_anywhere_return_toggle: CheckButton
var _tester_tools_root: Control
var _sound_tab_button: Button
var _gameplay_tab_button: Button
var _language_tab_button: Button
var _master_mute_button: Button
var _music_mute_button: Button
var _sfx_mute_button: Button
var _voice_over_mute_button: Button
var _language_dropdown_button: Button
var _language_popup: Panel
var _language_popup_list: VBoxContainer
var _language_choices: Array[Dictionary] = []
var _language_card: Panel
var _privacy_button: Button
var _privacy_overlay: Panel
var _privacy_text: RichTextLabel
var _active_settings_tab := SETTINGS_TAB_SOUND
var _slider_proxies: Dictionary = {}
var _toggle_proxies: Dictionary = {}
var _button_proxies: Dictionary = {}
var _toggle_visuals: Dictionary = {}
var _timer_chip_buttons: Dictionary = {}
var _timer_custom_steppers: Dictionary = {}
var _timer_custom_visible: Dictionary = {}
var _tester_tools_y := 660.0
var _transparent_toggle_icon: Texture2D
var _connected_viewport: Viewport
var _panel_style: StyleBoxFlat
var _header_style: StyleBoxFlat
var _button_style: StyleBoxFlat
var _button_pressed_style: StyleBoxFlat
var _mute_button_style: StyleBoxFlat
var _mute_button_pressed_style: StyleBoxFlat
var _tab_active_style: StyleBoxFlat
var _tab_inactive_style: StyleBoxFlat
var _toggle_row_style: StyleBoxFlat
var _card_style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if GameSettings.has_signal("locale_changed") and not GameSettings.locale_changed.is_connected(_on_locale_changed):
		GameSettings.locale_changed.connect(_on_locale_changed)
	_ensure_notebook_styles()
	_connect_viewport()
	_fit_panel_to_viewport()
	_ensure_scroll_layout()
	if _close_button != null:
		_close_button.pressed.connect(close)
	_ensure_sound_controls()
	_ensure_gameplay_controls()
	_ensure_tester_tools()
	_ensure_privacy_overlay()
	if _duck_pond_timeout_toggle != null:
		_duck_pond_timeout_toggle.toggled.connect(_on_duck_pond_timeout_toggled)
	if _mole_garden_timeout_toggle != null:
		_mole_garden_timeout_toggle.toggled.connect(_on_mole_garden_timeout_toggled)
	if _tap_anywhere_return_toggle != null:
		_tap_anywhere_return_toggle.toggled.connect(_on_tap_anywhere_return_toggled)
	if _master_volume_slider != null:
		_configure_slider(_master_volume_slider)
		_master_volume_slider.value_changed.connect(_on_master_volume_changed)
	if _music_volume_slider != null:
		_configure_slider(_music_volume_slider)
		_music_volume_slider.value_changed.connect(_on_music_volume_changed)
	if _sfx_volume_slider != null:
		_configure_slider(_sfx_volume_slider)
		_sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	if _voice_over_volume_slider != null:
		_configure_slider(_voice_over_volume_slider)
		_voice_over_volume_slider.value_changed.connect(_on_voice_over_volume_changed)
	visible = false
	refresh()
	call_deferred("_refresh_responsive_layout")


func open() -> void:
	_refresh_responsive_layout()
	refresh()
	visible = true
	var header := get_node_or_null("HeaderBoard") as Control
	FarmFeedback.pulse(header if header != null else self, 1.02, 0.12)


func close() -> void:
	visible = false
	emit_signal("closed")


func _connect_viewport() -> void:
	_connected_viewport = get_viewport()
	if _connected_viewport != null and not _connected_viewport.size_changed.is_connected(_refresh_responsive_layout):
		_connected_viewport.size_changed.connect(_refresh_responsive_layout)


func _refresh_responsive_layout() -> void:
	_fit_panel_to_viewport()
	_ensure_scroll_layout()


func _ensure_notebook_styles() -> void:
	_panel_style = _make_stylebox(Color(1.0, 0.93, 0.68, 0.22), Color(0.0, 0.0, 0.0, 0.0), 0, 64)
	_header_style = _make_stylebox(Color(0.95, 0.68, 0.35, 0.0), Color(0.0, 0.0, 0.0, 0.0), 0, 34)
	_button_style = _make_stylebox(NOTEBOOK_GREEN, Color("4e7f37"), 5, 30)
	_button_pressed_style = _make_stylebox(Color("65ae58"), Color("4e7f37"), 5, 30)
	_mute_button_style = _make_stylebox(Color("f7d37a"), NOTEBOOK_DARK_BORDER_COLOR, 5, 24)
	_mute_button_pressed_style = _make_stylebox(Color("e7b95d"), NOTEBOOK_DARK_BORDER_COLOR, 5, 24)
	_tab_active_style = _make_stylebox(NOTEBOOK_TAB_ACTIVE_COLOR, NOTEBOOK_DARK_BORDER_COLOR, 5, 28)
	_tab_inactive_style = _make_stylebox(NOTEBOOK_TAB_INACTIVE_COLOR, Color("8c6b3f"), 4, 28)
	_toggle_row_style = _make_stylebox(NOTEBOOK_ROW_COLOR, Color("d8a65f"), 3, 28)
	_card_style = _make_stylebox(NOTEBOOK_PAPER_COLOR, NOTEBOOK_BORDER_COLOR, 4, 28)


func _make_stylebox(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.shadow_color = Color(0.32, 0.20, 0.11, 0.14)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 4.0)
	return style


func _fit_panel_to_viewport() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var viewport_size := viewport.get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var margin := SETTINGS_PANEL_MARGIN
	var desired_size := Vector2(
		minf(SETTINGS_PANEL_MAX_SIZE.x, maxf(SETTINGS_PANEL_MIN_SIZE.x, viewport_size.x - margin.x * 2.0)),
		minf(SETTINGS_PANEL_MAX_SIZE.y, maxf(SETTINGS_PANEL_MIN_SIZE.y, viewport_size.y - margin.y * 2.0))
	)
	desired_size.x = minf(desired_size.x, maxf(0.0, viewport_size.x - 32.0))
	desired_size.y = minf(desired_size.y, maxf(0.0, viewport_size.y - 24.0))
	var desired_position := (viewport_size - desired_size) * 0.5
	set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	offset_left = desired_position.x
	offset_top = desired_position.y
	offset_right = desired_position.x + desired_size.x
	offset_bottom = desired_position.y + desired_size.y


func _layout_panel_chrome(panel_size: Vector2) -> void:
	add_theme_stylebox_override("panel", _panel_style)
	var backdrop := get_node_or_null("PanelBackdrop") as Control
	if backdrop != null:
		backdrop.position = Vector2.ZERO
		backdrop.size = panel_size
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if backdrop is TextureRect:
			(backdrop as TextureRect).stretch_mode = TextureRect.STRETCH_SCALE
	var close_button := _close_button
	if close_button != null:
		close_button.position = Vector2(panel_size.x - 304.0, 62.0)
		close_button.size = Vector2(236.0, 112.0)
		_apply_notebook_button_style(close_button)
	var header := get_node_or_null("HeaderBoard") as Control
	if header != null:
		header.position = Vector2(250.0, 64.0)
		header.size = Vector2(maxf(500.0, panel_size.x - 620.0), 94.0)
		header.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_theme_stylebox_override("panel", _header_style)
	var title := get_node_or_null("SettingsTitle") as Control
	if title != null:
		title.position = Vector2(292.0, 70.0)
		title.size = Vector2(maxf(360.0, panel_size.x - 720.0), 82.0)
		title.add_theme_color_override("font_color", NOTEBOOK_TEXT_COLOR)
		title.add_theme_color_override("font_shadow_color", Color(1.0, 0.93, 0.66, 0.65))
		title.add_theme_constant_override("shadow_offset_x", 0)
		title.add_theme_constant_override("shadow_offset_y", 3)
	_ensure_tab_controls()
	_layout_tab_controls(panel_size)
	_layout_privacy_overlay(panel_size)


func _ensure_tab_controls() -> void:
	_sound_tab_button = get_node_or_null("SoundTabButton") as Button
	if _sound_tab_button == null:
		_sound_tab_button = Button.new()
		_sound_tab_button.name = "SoundTabButton"
		_sound_tab_button.text = tr("Sound")
		_sound_tab_button.toggle_mode = true
		_sound_tab_button.focus_mode = Control.FOCUS_NONE
		add_child(_sound_tab_button)
	if not _sound_tab_button.pressed.is_connected(_on_sound_tab_pressed):
		_sound_tab_button.pressed.connect(_on_sound_tab_pressed)

	_gameplay_tab_button = get_node_or_null("GameplayTabButton") as Button
	if _gameplay_tab_button == null:
		_gameplay_tab_button = Button.new()
		_gameplay_tab_button.name = "GameplayTabButton"
		_gameplay_tab_button.text = tr("Gameplay")
		_gameplay_tab_button.toggle_mode = true
		_gameplay_tab_button.focus_mode = Control.FOCUS_NONE
		add_child(_gameplay_tab_button)
	if not _gameplay_tab_button.pressed.is_connected(_on_gameplay_tab_pressed):
		_gameplay_tab_button.pressed.connect(_on_gameplay_tab_pressed)

	_language_tab_button = get_node_or_null("LanguageTabButton") as Button
	if _language_tab_button == null:
		_language_tab_button = Button.new()
		_language_tab_button.name = "LanguageTabButton"
		_language_tab_button.text = tr("Language")
		_language_tab_button.toggle_mode = true
		_language_tab_button.focus_mode = Control.FOCUS_NONE
		add_child(_language_tab_button)
	if not _language_tab_button.pressed.is_connected(_on_language_tab_pressed):
		_language_tab_button.pressed.connect(_on_language_tab_pressed)

	for button in [_sound_tab_button, _gameplay_tab_button, _language_tab_button]:
		if button == null:
			continue
		_apply_notebook_tab_style(button, button == _sound_tab_button and _active_settings_tab == SETTINGS_TAB_SOUND or button == _gameplay_tab_button and _active_settings_tab == SETTINGS_TAB_GAMEPLAY or button == _language_tab_button and _active_settings_tab == SETTINGS_TAB_LANGUAGE)
		button.add_theme_font_size_override("font_size", 36)
		button.add_theme_constant_override("h_separation", 14)
		button.add_theme_constant_override("icon_max_width", 52)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
	_sound_tab_button.icon = SoundTabIcon
	_sound_tab_button.expand_icon = true
	_gameplay_tab_button.icon = GameplayTabIcon
	_gameplay_tab_button.expand_icon = true
	_language_tab_button.expand_icon = true


func _layout_tab_controls(panel_size: Vector2) -> void:
	if _sound_tab_button == null or _gameplay_tab_button == null or _language_tab_button == null:
		return
	var tabs_width := minf(1120.0, maxf(760.0, panel_size.x - 320.0))
	var tab_gap := 18.0
	var tab_size := Vector2((tabs_width - tab_gap * 2.0) / 3.0, 88.0)
	var left := maxf(SETTINGS_TABS_POSITION.x + 180.0, (panel_size.x - tabs_width) * 0.5)
	_sound_tab_button.position = Vector2(left, SETTINGS_TABS_POSITION.y)
	_sound_tab_button.size = tab_size
	_sound_tab_button.custom_minimum_size = tab_size
	_gameplay_tab_button.position = Vector2(left + tab_size.x + tab_gap, SETTINGS_TABS_POSITION.y)
	_gameplay_tab_button.size = tab_size
	_gameplay_tab_button.custom_minimum_size = tab_size
	_language_tab_button.position = Vector2(left + (tab_size.x + tab_gap) * 2.0, SETTINGS_TABS_POSITION.y)
	_language_tab_button.size = tab_size
	_language_tab_button.custom_minimum_size = tab_size
	_refresh_tab_buttons()


func _refresh_tab_buttons() -> void:
	if _sound_tab_button != null:
		_sound_tab_button.set_pressed_no_signal(_active_settings_tab == SETTINGS_TAB_SOUND)
		_apply_notebook_tab_style(_sound_tab_button, _active_settings_tab == SETTINGS_TAB_SOUND)
	if _gameplay_tab_button != null:
		_gameplay_tab_button.set_pressed_no_signal(_active_settings_tab == SETTINGS_TAB_GAMEPLAY)
		_apply_notebook_tab_style(_gameplay_tab_button, _active_settings_tab == SETTINGS_TAB_GAMEPLAY)
	if _language_tab_button != null:
		_language_tab_button.set_pressed_no_signal(_active_settings_tab == SETTINGS_TAB_LANGUAGE)
		_apply_notebook_tab_style(_language_tab_button, _active_settings_tab == SETTINGS_TAB_LANGUAGE)


func _apply_notebook_button_style(button: Button) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", _button_style)
	button.add_theme_stylebox_override("pressed", _button_pressed_style)
	button.add_theme_stylebox_override("hover", _button_style)
	button.add_theme_stylebox_override("focus", _button_style)
	button.add_theme_color_override("font_color", Color("28411e"))
	button.add_theme_color_override("font_pressed_color", Color("28411e"))
	button.add_theme_color_override("font_hover_color", Color("28411e"))
	button.add_theme_font_size_override("font_size", 34)


func _apply_mute_button_style(button: Button) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", _mute_button_style)
	button.add_theme_stylebox_override("pressed", _mute_button_pressed_style)
	button.add_theme_stylebox_override("hover", _mute_button_style)
	button.add_theme_stylebox_override("focus", _mute_button_style)
	button.add_theme_color_override("font_color", NOTEBOOK_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", NOTEBOOK_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", NOTEBOOK_TEXT_COLOR)
	button.add_theme_font_size_override("font_size", 38)


func _apply_notebook_tab_style(button: Button, active: bool) -> void:
	if button == null:
		return
	var normal_style := _tab_active_style if active else _tab_inactive_style
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("pressed", _tab_active_style)
	button.add_theme_stylebox_override("hover", normal_style)
	button.add_theme_stylebox_override("focus", normal_style)
	button.add_theme_color_override("font_color", NOTEBOOK_TEXT_COLOR if active else Color("725437"))
	button.add_theme_color_override("font_pressed_color", NOTEBOOK_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", NOTEBOOK_TEXT_COLOR)
	button.modulate = Color(1.0, 1.0, 1.0, 1.0) if active else Color(1.0, 1.0, 1.0, 0.9)


func _ensure_scroll_layout() -> void:
	var panel_size := size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		panel_size = Vector2(maxf(0.0, offset_right - offset_left), maxf(0.0, offset_bottom - offset_top))
	_layout_panel_chrome(panel_size)
	_scroll_area = get_node_or_null("SettingsScroll") as ScrollContainer
	if _scroll_area == null:
		_scroll_area = ScrollContainer.new()
		_scroll_area.name = "SettingsScroll"
		add_child(_scroll_area)
		move_child(_scroll_area, min(4, get_child_count() - 1))

	_scroll_area.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var current_scroll_position := SETTINGS_SCROLL_POSITION
	var current_scroll_size := Vector2(
		maxf(SETTINGS_SCROLL_MIN_SIZE.x, panel_size.x - 88.0),
		maxf(SETTINGS_SCROLL_MIN_SIZE.y, panel_size.y - SETTINGS_SCROLL_POSITION.y - 34.0)
	)
	scroll_view_position = current_scroll_position
	scroll_view_size = current_scroll_size
	_scroll_area.position = current_scroll_position
	_scroll_area.size = current_scroll_size
	_scroll_area.custom_minimum_size = current_scroll_size
	_scroll_area.clip_contents = true
	_scroll_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_scroll_area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll_area.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_style_scrollbars()

	_settings_content = _scroll_area.get_node_or_null("SettingsContent") as Control
	var settings_content_was_created := false
	if _settings_content == null:
		_settings_content = Control.new()
		_settings_content.name = "SettingsContent"
		_scroll_area.add_child(_settings_content)
		settings_content_was_created = true

	if settings_content_was_created:
		_settings_content.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_settings_content.position = Vector2.ZERO
	var content_width := current_scroll_size.x - 32.0
	var control_width := minf(SETTINGS_CONTENT_MAX_WIDTH, maxf(720.0, content_width - SETTINGS_CONTENT_SIDE_GUTTER * 2.0))
	var content_left := maxf(0.0, (content_width - control_width) * 0.5)
	var row_width := control_width - 64.0
	var card_width := control_width - 28.0
	var label_width := control_width - 96.0
	var content_height := _get_current_settings_content_height()
	_settings_content.size = Vector2(content_width, content_height + SETTINGS_CONTENT_BOTTOM_PADDING)
	_settings_content.custom_minimum_size = _settings_content.size
	_settings_content.mouse_filter = Control.MOUSE_FILTER_PASS
	_layout_content_groups()
	_ensure_sound_controls()
	_ensure_gameplay_controls()
	_ensure_language_controls()

	var control_x := content_left + 32.0
	var card_x := content_left + 14.0
	var label_x := content_left + 54.0
	var mute_x := card_x + card_width - 166.0
	var sound_label_width := maxf(180.0, mute_x - label_x - 24.0)
	var slider_width_before_mute := mute_x - label_x - SETTINGS_SLIDER_TOUCH_PADDING * 2.0 - 24.0
	var volume_slider_size := Vector2(maxf(180.0, slider_width_before_mute), SETTINGS_SLIDER_HEIGHT)
	slider_touch_size = volume_slider_size
	_move_control_to_content(_music_toggle, Vector2(control_x, 0.0), Vector2(row_width, SETTINGS_TOGGLE_ROW_HEIGHT))
	_move_control_to_content(_voice_over_toggle, Vector2(control_x, SETTINGS_TOGGLE_ROW_HEIGHT), Vector2(row_width, SETTINGS_TOGGLE_ROW_HEIGHT))
	_move_control_to_content(_tap_anywhere_return_toggle, Vector2(control_x, 0.0), Vector2(row_width, SETTINGS_TOGGLE_ROW_HEIGHT))
	_layout_toggle_visual(_tap_anywhere_return_toggle)
	_ensure_toggle_touch_proxy(_tap_anywhere_return_toggle)

	_layout_language_controls(card_x, label_x, card_width, label_width)

	_move_named_control_to_content("MasterCard", Vector2(card_x, SETTINGS_CARD_TOP), Vector2(card_width, SETTINGS_CARD_HEIGHT))
	_apply_named_panel_style("MasterCard", _card_style)
	_move_control_to_content(_master_volume_label, Vector2(label_x, SETTINGS_CARD_TOP + 18.0), Vector2(sound_label_width, SETTINGS_LABEL_HEIGHT))
	_move_control_to_content(_master_mute_button, Vector2(mute_x, SETTINGS_CARD_TOP + 18.0), Vector2(124.0, 82.0))
	_move_control_to_content(_master_volume_slider, Vector2(label_x, SETTINGS_CARD_TOP + 72.0), volume_slider_size)
	_ensure_slider_touch_proxy(_master_volume_slider)
	_ensure_button_touch_proxy(_master_mute_button)

	_move_named_control_to_content("MusicCard", Vector2(card_x, SETTINGS_CARD_TOP + SETTINGS_CARD_HEIGHT + SETTINGS_CARD_GAP), Vector2(card_width, SETTINGS_CARD_HEIGHT))
	_apply_named_panel_style("MusicCard", _card_style)
	_move_control_to_content(_music_volume_label, Vector2(label_x, SETTINGS_CARD_TOP + SETTINGS_CARD_HEIGHT + SETTINGS_CARD_GAP + 18.0), Vector2(sound_label_width, SETTINGS_LABEL_HEIGHT))
	_move_control_to_content(_music_mute_button, Vector2(mute_x, SETTINGS_CARD_TOP + SETTINGS_CARD_HEIGHT + SETTINGS_CARD_GAP + 18.0), Vector2(124.0, 82.0))
	_move_control_to_content(_music_volume_slider, Vector2(label_x, SETTINGS_CARD_TOP + SETTINGS_CARD_HEIGHT + SETTINGS_CARD_GAP + 72.0), volume_slider_size)
	_ensure_slider_touch_proxy(_music_volume_slider)
	_ensure_button_touch_proxy(_music_mute_button)

	_move_named_control_to_content("SfxCard", Vector2(card_x, SETTINGS_CARD_TOP + (SETTINGS_CARD_HEIGHT + SETTINGS_CARD_GAP) * 2.0), Vector2(card_width, SETTINGS_CARD_HEIGHT))
	_apply_named_panel_style("SfxCard", _card_style)
	_move_control_to_content(_sfx_volume_label, Vector2(label_x, SETTINGS_CARD_TOP + (SETTINGS_CARD_HEIGHT + SETTINGS_CARD_GAP) * 2.0 + 18.0), Vector2(sound_label_width, SETTINGS_LABEL_HEIGHT))
	_move_control_to_content(_sfx_mute_button, Vector2(mute_x, SETTINGS_CARD_TOP + (SETTINGS_CARD_HEIGHT + SETTINGS_CARD_GAP) * 2.0 + 18.0), Vector2(124.0, 82.0))
	_move_control_to_content(_sfx_volume_slider, Vector2(label_x, SETTINGS_CARD_TOP + (SETTINGS_CARD_HEIGHT + SETTINGS_CARD_GAP) * 2.0 + 72.0), volume_slider_size)
	_ensure_slider_touch_proxy(_sfx_volume_slider)
	_ensure_button_touch_proxy(_sfx_mute_button)

	_move_named_control_to_content("VoiceOverCard", Vector2(card_x, SETTINGS_CARD_TOP + (SETTINGS_CARD_HEIGHT + SETTINGS_CARD_GAP) * 3.0), Vector2(card_width, SETTINGS_CARD_HEIGHT))
	_apply_named_panel_style("VoiceOverCard", _card_style)
	_move_control_to_content(_voice_over_volume_label, Vector2(label_x, SETTINGS_CARD_TOP + (SETTINGS_CARD_HEIGHT + SETTINGS_CARD_GAP) * 3.0 + 18.0), Vector2(sound_label_width, SETTINGS_LABEL_HEIGHT))
	_move_control_to_content(_voice_over_mute_button, Vector2(mute_x, SETTINGS_CARD_TOP + (SETTINGS_CARD_HEIGHT + SETTINGS_CARD_GAP) * 3.0 + 18.0), Vector2(124.0, 82.0))
	_move_control_to_content(_voice_over_volume_slider, Vector2(label_x, SETTINGS_CARD_TOP + (SETTINGS_CARD_HEIGHT + SETTINGS_CARD_GAP) * 3.0 + 72.0), volume_slider_size)
	_ensure_slider_touch_proxy(_voice_over_volume_slider)
	_ensure_button_touch_proxy(_voice_over_mute_button)
	_layout_timer_controls(card_x, label_x, card_width, label_width)
	_layout_tester_tools()
	_apply_settings_tab_visibility()
	_raise_sound_mute_buttons()
	_refresh_exported_node_paths()


func _layout_content_groups() -> void:
	if _settings_content == null:
		return
	for group_name in ["SoundSettings", "GameplaySettings"]:
		var group := _find_content_control(group_name)
		if group == null:
			continue
		group.set_anchors_preset(Control.PRESET_TOP_LEFT)
		group.position = Vector2.ZERO
		group.size = _settings_content.size
		group.custom_minimum_size = _settings_content.size
		group.mouse_filter = Control.MOUSE_FILTER_PASS


func _get_current_settings_content_height() -> float:
	if _active_settings_tab == SETTINGS_TAB_LANGUAGE:
		return SETTINGS_LANGUAGE_CONTENT_HEIGHT
	if _active_settings_tab == SETTINGS_TAB_GAMEPLAY:
		return maxf(SETTINGS_GAMEPLAY_CONTENT_HEIGHT, _tester_tools_y + (360.0 if tester_tools_enabled else 0.0))
	return SETTINGS_SOUND_CONTENT_HEIGHT


func _apply_settings_tab_visibility() -> void:
	var sound_visible := _active_settings_tab == SETTINGS_TAB_SOUND
	var gameplay_visible := _active_settings_tab == SETTINGS_TAB_GAMEPLAY
	var language_visible := _active_settings_tab == SETTINGS_TAB_LANGUAGE
	_set_control_visible(_music_toggle, false)
	_set_control_visible(_voice_over_toggle, false)
	_set_toggle_extras_visible(_music_toggle, false)
	_set_toggle_extras_visible(_voice_over_toggle, false)
	for control in [_master_volume_label, _master_volume_slider, _music_volume_label, _music_volume_slider, _sfx_volume_label, _sfx_volume_slider, _voice_over_volume_label, _voice_over_volume_slider, _master_mute_button, _music_mute_button, _sfx_mute_button, _voice_over_mute_button]:
		_set_control_visible(control, sound_visible)
	for node_name in ["MasterCard", "MusicCard", "SfxCard", "VoiceOverCard"]:
		_set_named_control_visible(node_name, sound_visible)
	for slider in [_master_volume_slider, _music_volume_slider, _sfx_volume_slider, _voice_over_volume_slider]:
		_set_slider_proxy_visible(slider, sound_visible)
	for button in [_master_mute_button, _music_mute_button, _sfx_mute_button, _voice_over_mute_button]:
		_set_button_proxy_visible(button, sound_visible)

	if _language_card != null:
		_language_card.visible = language_visible
	_set_control_visible(_language_dropdown_button, language_visible)
	_set_control_visible(_privacy_button, language_visible)
	_set_button_proxy_visible(_language_dropdown_button, language_visible)
	if not language_visible:
		_close_language_popup()
		_close_privacy_policy()
	_hide_legacy_language_controls()

	for control in [_duck_pond_timeout_toggle, _mole_garden_timeout_toggle, _tap_anywhere_return_toggle]:
		_set_control_visible(control, gameplay_visible)
	for toggle in [_duck_pond_timeout_toggle, _mole_garden_timeout_toggle, _tap_anywhere_return_toggle]:
		_set_toggle_extras_visible(toggle, gameplay_visible)
	for timer_id in ["duck_pond", "mole_garden"]:
		var chips: Array = _timer_chip_buttons.get(timer_id, [])
		var timer_options_visible := gameplay_visible and _is_timer_enabled(timer_id)
		for chip in chips:
			_set_control_visible(chip as Control, timer_options_visible)
		var legacy_edit := _find_content_control("%sTimerCustomEdit" % timer_id.capitalize().replace(" ", "")) as LineEdit
		_set_control_visible(legacy_edit, false)
		var stepper := _timer_custom_steppers.get(timer_id) as Dictionary
		var stepper_visible := timer_options_visible and _should_show_timer_custom_edit(timer_id)
		if stepper != null:
			for control in [stepper.get("minus") as Control, stepper.get("value") as Control, stepper.get("plus") as Control]:
				_set_control_visible(control, stepper_visible)
	if _tester_tools_root != null:
		_tester_tools_root.visible = gameplay_visible and tester_tools_enabled
	_refresh_tab_buttons()
	if sound_visible:
		_raise_sound_mute_buttons()


func _set_named_control_visible(node_name: String, visible_value: bool) -> void:
	var control := get_node_or_null(node_name) as Control
	if control == null and _settings_content != null:
		control = _find_content_control(node_name)
	_set_control_visible(control, visible_value)


func _set_control_visible(control: Control, visible_value: bool) -> void:
	if control != null:
		control.visible = visible_value


func _hide_legacy_language_controls() -> void:
	for node_name in ["LanguageOptionButton", "LanguageAutoToggle", "TtsLanguageCard", "TtsLanguageTitle", "TtsLanguageAutoToggle", "TtsLanguageOptionButton"]:
		var control := _find_content_control(node_name)
		if control != null:
			_set_control_visible(control, false)
			if control is CheckButton:
				_set_toggle_extras_visible(control as CheckButton, false)


func _apply_named_panel_style(node_name: String, style: StyleBoxFlat) -> void:
	var panel := get_node_or_null(node_name) as Panel
	if panel == null and _settings_content != null:
		panel = _find_content_control(node_name) as Panel
	if panel != null:
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override("panel", style)


func _set_toggle_extras_visible(toggle: CheckButton, visible_value: bool) -> void:
	if toggle == null:
		return
	var visual = _toggle_visuals.get(toggle.name)
	if visual != null and is_instance_valid(visual):
		(visual as Control).visible = visible_value
	var proxy = _toggle_proxies.get(toggle.name)
	if proxy != null and is_instance_valid(proxy):
		(proxy as Control).visible = visible_value


func _set_slider_proxy_visible(slider: HSlider, visible_value: bool) -> void:
	if slider == null:
		return
	var proxy = _slider_proxies.get(slider.name)
	if proxy != null and is_instance_valid(proxy):
		(proxy as Control).visible = visible_value


func _set_button_proxy_visible(button: Button, visible_value: bool) -> void:
	if button == null:
		return
	var proxy = _button_proxies.get(button.name)
	if proxy != null and is_instance_valid(proxy):
		(proxy as Control).visible = visible_value


func _set_active_settings_tab(tab_name: String) -> void:
	if _active_settings_tab == tab_name:
		_refresh_tab_buttons()
		return
	_active_settings_tab = tab_name
	if _scroll_area != null:
		_scroll_area.scroll_vertical = 0
	_ensure_scroll_layout()


func _on_sound_tab_pressed() -> void:
	_set_active_settings_tab(SETTINGS_TAB_SOUND)


func _on_gameplay_tab_pressed() -> void:
	_set_active_settings_tab(SETTINGS_TAB_GAMEPLAY)


func _on_language_tab_pressed() -> void:
	_set_active_settings_tab(SETTINGS_TAB_LANGUAGE)


func _ensure_sound_controls() -> void:
	if _settings_content == null:
		return
	_master_mute_button = _ensure_content_button("MasterMuteButton", "🔊")
	_music_mute_button = _ensure_content_button("MusicMuteButton", "🔊")
	_sfx_mute_button = _ensure_content_button("SfxMuteButton", "🔊")
	_voice_over_mute_button = _ensure_content_button("VoiceOverMuteButton", "🔊")
	for button in [_master_mute_button, _music_mute_button, _sfx_mute_button, _voice_over_mute_button]:
		_apply_mute_button_style(button)
	if _master_mute_button != null and not _master_mute_button.pressed.is_connected(_on_master_mute_pressed):
		_master_mute_button.pressed.connect(_on_master_mute_pressed)
	if _music_mute_button != null and not _music_mute_button.pressed.is_connected(_on_music_mute_pressed):
		_music_mute_button.pressed.connect(_on_music_mute_pressed)
	if _sfx_mute_button != null and not _sfx_mute_button.pressed.is_connected(_on_sfx_mute_pressed):
		_sfx_mute_button.pressed.connect(_on_sfx_mute_pressed)
	if _voice_over_mute_button != null and not _voice_over_mute_button.pressed.is_connected(_on_voice_over_mute_pressed):
		_voice_over_mute_button.pressed.connect(_on_voice_over_mute_pressed)


func _ensure_content_button(node_name: String, text: String) -> Button:
	if _settings_content == null:
		return null
	var button := _find_content_control(node_name) as Button
	if button == null:
		button = Button.new()
		button.name = node_name
		button.text = text
		button.focus_mode = Control.FOCUS_NONE
		_settings_content.add_child(button)
	_apply_notebook_button_style(button)
	button.add_theme_font_size_override("font_size", 30)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	return button


func _ensure_gameplay_controls() -> void:
	if _settings_content == null:
		return
	_duck_pond_timeout_toggle = _find_content_control("DuckPondTimeoutToggle") as CheckButton
	if _duck_pond_timeout_toggle == null:
		_duck_pond_timeout_toggle = CheckButton.new()
		_duck_pond_timeout_toggle.name = "DuckPondTimeoutToggle"
		_duck_pond_timeout_toggle.focus_mode = Control.FOCUS_NONE
		_duck_pond_timeout_toggle.add_theme_font_size_override("font_size", SETTINGS_TOGGLE_FONT_SIZE)
		_duck_pond_timeout_toggle.custom_minimum_size = SETTINGS_TOGGLE_MIN_SIZE
		_settings_content.add_child(_duck_pond_timeout_toggle)
	_tap_anywhere_return_toggle = _find_content_control("TapAnywhereReturnToggle") as CheckButton
	if _tap_anywhere_return_toggle == null:
		_tap_anywhere_return_toggle = CheckButton.new()
		_tap_anywhere_return_toggle.name = "TapAnywhereReturnToggle"
		_tap_anywhere_return_toggle.focus_mode = Control.FOCUS_NONE
		_tap_anywhere_return_toggle.add_theme_font_size_override("font_size", SETTINGS_TOGGLE_FONT_SIZE)
		_tap_anywhere_return_toggle.custom_minimum_size = SETTINGS_TOGGLE_MIN_SIZE
		_settings_content.add_child(_tap_anywhere_return_toggle)
	_mole_garden_timeout_toggle = _find_content_control("MoleGardenTimeoutToggle") as CheckButton
	if _mole_garden_timeout_toggle == null:
		_mole_garden_timeout_toggle = CheckButton.new()
		_mole_garden_timeout_toggle.name = "MoleGardenTimeoutToggle"
		_mole_garden_timeout_toggle.focus_mode = Control.FOCUS_NONE
		_mole_garden_timeout_toggle.add_theme_font_size_override("font_size", SETTINGS_TOGGLE_FONT_SIZE)
		_mole_garden_timeout_toggle.custom_minimum_size = SETTINGS_TOGGLE_MIN_SIZE
		_settings_content.add_child(_mole_garden_timeout_toggle)
	_ensure_timer_controls("duck_pond")
	_ensure_timer_controls("mole_garden")
	_apply_gameplay_toggle_theme()


func _ensure_language_controls() -> void:
	if _settings_content == null:
		return
	if _language_card == null:
		_language_card = _find_content_control("LanguageCard") as Panel
		if _language_card == null:
			_language_card = Panel.new()
			_language_card.name = "LanguageCard"
			_settings_content.add_child(_language_card)
	_language_card.add_theme_stylebox_override("panel", _card_style)

	var title := _find_content_control("LanguageTitle") as Label
	if title == null:
		title = Label.new()
		title.name = "LanguageTitle"
		_language_card.add_child(title)
	title.text = tr("Language")
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("5f3b22"))

	_language_dropdown_button = _find_content_control("LanguageDropdownButton") as Button
	if _language_dropdown_button == null:
		_language_dropdown_button = Button.new()
		_language_dropdown_button.name = "LanguageDropdownButton"
		_language_dropdown_button.focus_mode = Control.FOCUS_NONE
		_language_dropdown_button.add_theme_font_size_override("font_size", 30)
		_language_card.add_child(_language_dropdown_button)
	if not _language_dropdown_button.pressed.is_connected(_on_language_dropdown_pressed):
		_language_dropdown_button.pressed.connect(_on_language_dropdown_pressed)
	_language_dropdown_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_notebook_button_style(_language_dropdown_button)
	_privacy_button = _find_content_control("PrivacyPolicyButton") as Button
	if _privacy_button == null:
		_privacy_button = Button.new()
		_privacy_button.name = "PrivacyPolicyButton"
		_privacy_button.focus_mode = Control.FOCUS_NONE
		_settings_content.add_child(_privacy_button)
	_privacy_button.text = tr("Privacy & Parents")
	_privacy_button.add_theme_font_size_override("font_size", 30)
	_apply_notebook_button_style(_privacy_button)
	if not _privacy_button.pressed.is_connected(_on_privacy_policy_pressed):
		_privacy_button.pressed.connect(_on_privacy_policy_pressed)
	_ensure_language_popup()
	_refresh_language_choices()
	_hide_legacy_language_controls()


func _ensure_privacy_overlay() -> void:
	_privacy_overlay = get_node_or_null("PrivacyPolicyOverlay") as Panel
	if _privacy_overlay == null:
		_privacy_overlay = Panel.new()
		_privacy_overlay.name = "PrivacyPolicyOverlay"
		add_child(_privacy_overlay)
	_privacy_overlay.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_privacy_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_privacy_overlay.z_index = 500
	_privacy_overlay.add_theme_stylebox_override("panel", _card_style)

	var title := _privacy_overlay.get_node_or_null("Title") as Label
	if title == null:
		title = Label.new()
		title.name = "Title"
		_privacy_overlay.add_child(title)
	title.text = tr("Privacy Policy")
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", NOTEBOOK_TEXT_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var close_button := _privacy_overlay.get_node_or_null("CloseButton") as Button
	if close_button == null:
		close_button = Button.new()
		close_button.name = "CloseButton"
		_privacy_overlay.add_child(close_button)
	close_button.text = tr("Done")
	close_button.focus_mode = Control.FOCUS_NONE
	_apply_notebook_button_style(close_button)
	close_button.add_theme_font_size_override("font_size", 30)
	if not close_button.pressed.is_connected(_close_privacy_policy):
		close_button.pressed.connect(_close_privacy_policy)

	var scroll := _privacy_overlay.get_node_or_null("Scroll") as ScrollContainer
	if scroll == null:
		scroll = ScrollContainer.new()
		scroll.name = "Scroll"
		_privacy_overlay.add_child(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	_privacy_text = scroll.get_node_or_null("Text") as RichTextLabel
	if _privacy_text == null:
		_privacy_text = RichTextLabel.new()
		_privacy_text.name = "Text"
		scroll.add_child(_privacy_text)
	_privacy_text.bbcode_enabled = true
	_privacy_text.fit_content = true
	_privacy_text.scroll_active = false
	_privacy_text.mouse_filter = Control.MOUSE_FILTER_PASS
	_privacy_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_privacy_text.add_theme_font_size_override("normal_font_size", 27)
	_privacy_text.add_theme_color_override("default_color", NOTEBOOK_TEXT_COLOR)
	_privacy_text.text = _load_privacy_policy_text()
	_privacy_overlay.visible = false


func _load_privacy_policy_text() -> String:
	var policy_path := _get_privacy_policy_path()
	if not FileAccess.file_exists(policy_path):
		return "PRIVACY POLICY FOR MY FIRST HOMESTEAD\n\nThe current privacy policy is available at:\n%s\n\nMy First Homestead does not collect, transmit, or share personal information. Game progress and settings are stored locally on the device. For questions, contact Cozy Sprout Games at wryan2986@gmail.com." % PRIVACY_POLICY_URL
	var policy_text := FileAccess.get_file_as_string(policy_path).strip_edges()
	if not policy_text.contains(PRIVACY_POLICY_URL):
		policy_text += "\n\nPUBLIC POLICY PAGE\n%s" % PRIVACY_POLICY_URL
	return policy_text


func _get_privacy_policy_path() -> String:
	var locale_code := GameSettings.get_active_locale()
	return String(PRIVACY_POLICY_PATHS.get(locale_code, PRIVACY_POLICY_PATH))


func _refresh_privacy_policy_ui(reset_scroll := false) -> void:
	if _privacy_overlay == null:
		return
	var title := _privacy_overlay.get_node_or_null("Title") as Label
	if title != null:
		title.text = tr("Privacy Policy")
	var close_button := _privacy_overlay.get_node_or_null("CloseButton") as Button
	if close_button != null:
		close_button.text = tr("Done")
	if _privacy_text != null:
		_privacy_text.text = _load_privacy_policy_text()
	var scroll := _privacy_overlay.get_node_or_null("Scroll") as ScrollContainer
	if reset_scroll and scroll != null:
		scroll.scroll_vertical = 0


func _on_privacy_policy_pressed() -> void:
	if _privacy_overlay == null:
		return
	_refresh_privacy_policy_ui(true)
	_privacy_overlay.visible = true
	_privacy_overlay.move_to_front()


func _close_privacy_policy() -> void:
	if _privacy_overlay != null:
		_privacy_overlay.visible = false


func _layout_privacy_overlay(panel_size: Vector2) -> void:
	if _privacy_overlay == null:
		return
	var overlay_size := Vector2(
		minf(panel_size.x - 96.0, 1540.0),
		minf(panel_size.y - 96.0, 900.0)
	)
	overlay_size.x = maxf(720.0, overlay_size.x)
	overlay_size.y = maxf(560.0, overlay_size.y)
	_privacy_overlay.position = (panel_size - overlay_size) * 0.5
	_privacy_overlay.size = overlay_size
	_privacy_overlay.custom_minimum_size = overlay_size
	var title := _privacy_overlay.get_node_or_null("Title") as Label
	if title != null:
		title.position = Vector2(40.0, 28.0)
		title.size = Vector2(overlay_size.x - 360.0, 64.0)
	var close_button := _privacy_overlay.get_node_or_null("CloseButton") as Button
	if close_button != null:
		close_button.position = Vector2(overlay_size.x - 260.0, 24.0)
		close_button.size = Vector2(204.0, 82.0)
	var scroll := _privacy_overlay.get_node_or_null("Scroll") as ScrollContainer
	if scroll != null:
		scroll.position = Vector2(42.0, 122.0)
		scroll.size = Vector2(overlay_size.x - 84.0, overlay_size.y - 154.0)
		scroll.custom_minimum_size = scroll.size
		var text := scroll.get_node_or_null("Text") as RichTextLabel
		if text != null:
			text.custom_minimum_size = Vector2(scroll.size.x - 48.0, 0.0)
			text.size.x = text.custom_minimum_size.x


func _ensure_timer_controls(timer_id: String) -> void:
	if _settings_content == null:
		return
	var chips: Array[Button] = []
	for seconds in SETTINGS_TIMER_PRESETS:
		var chip_name := "%sTimer%dChip" % [timer_id.capitalize().replace(" ", ""), int(seconds)]
		var chip := _ensure_content_button(chip_name, "%d" % int(seconds / 60.0))
		if chip != null:
			chip.text = "%d" % int(seconds / 60.0)
			chips.append(chip)
			var callable := Callable(self, "_on_timer_preset_pressed").bind(timer_id, float(seconds))
			if not chip.pressed.is_connected(callable):
				chip.pressed.connect(callable)
	var custom_chip := _ensure_content_button("%sTimerCustomChip" % timer_id.capitalize().replace(" ", ""), "Custom")
	if custom_chip != null:
		custom_chip.text = tr("Custom")
		chips.append(custom_chip)
		var custom_callable := Callable(self, "_on_timer_custom_pressed").bind(timer_id)
		if not custom_chip.pressed.is_connected(custom_callable):
			custom_chip.pressed.connect(custom_callable)
	_timer_chip_buttons[timer_id] = chips

	var prefix := timer_id.capitalize().replace(" ", "")
	var minus_button := _ensure_content_button("%sTimerCustomMinus" % prefix, "-")
	var plus_button := _ensure_content_button("%sTimerCustomPlus" % prefix, "+")
	var value_label := _find_content_control("%sTimerCustomValue" % prefix) as Label
	if value_label == null:
		value_label = Label.new()
		value_label.name = "%sTimerCustomValue" % prefix
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_settings_content.add_child(value_label)
	if minus_button != null:
		minus_button.text = "-"
		var minus_callable := Callable(self, "_on_timer_custom_step_pressed").bind(timer_id, -1)
		if not minus_button.pressed.is_connected(minus_callable):
			minus_button.pressed.connect(minus_callable)
	if plus_button != null:
		plus_button.text = "+"
		var plus_callable := Callable(self, "_on_timer_custom_step_pressed").bind(timer_id, 1)
		if not plus_button.pressed.is_connected(plus_callable):
			plus_button.pressed.connect(plus_callable)
	_style_timer_value_label(value_label)
	_timer_custom_steppers[timer_id] = {
		"minus": minus_button,
		"value": value_label,
		"plus": plus_button,
	}


func _layout_language_controls(card_x: float, label_x: float, card_width: float, label_width: float) -> void:
	if _language_card == null:
		return
	var card_size := Vector2(card_width, 210.0)
	_move_control_to_content(_language_card, Vector2(card_x, SETTINGS_CARD_TOP), card_size)
	var title := _find_content_control("LanguageTitle") as Label
	if title != null:
		title.position = Vector2(40.0, 18.0)
		title.size = Vector2(maxf(320.0, card_width - 80.0), 42.0)
	var language_button := _language_dropdown_button
	if language_button != null:
		language_button.position = Vector2(42.0, 104.0)
		language_button.size = Vector2(card_width - 84.0, 82.0)
		language_button.custom_minimum_size = language_button.size
		_raise_control_in_parent(language_button)
		_ensure_button_touch_proxy(language_button)
		if _language_popup != null and _language_popup.visible:
			_position_language_popup()
	if _privacy_button != null:
		_privacy_button.text = tr("Privacy & Parents")
		_move_control_to_content(_privacy_button, Vector2(card_x, 238.0), Vector2(card_width, 88.0))
		_privacy_button.custom_minimum_size = _privacy_button.size
		_raise_control_in_parent(_privacy_button)
	_hide_legacy_language_controls()


func _refresh_language_choices() -> void:
	if _language_dropdown_button == null:
		return
	_language_choices.clear()
	_language_choices.append({"code": "", "label": tr("Use device language")})
	for choice in GameSettings.get_locale_choices():
		var locale_code := String(choice.get("code", ""))
		if locale_code.is_empty():
			continue
		var label := String(choice.get("native_name", choice.get("name", locale_code)))
		_language_choices.append({"code": locale_code, "label": label})
	var active_label := tr("Use device language")
	var current_locale := GameSettings.get_effective_locale()
	if not GameSettings.is_using_system_locale():
		for choice in _language_choices:
			if String(choice.get("code", "")) == current_locale:
				active_label = String(choice.get("label", active_label))
				break
	_language_dropdown_button.text = active_label
	_language_dropdown_button.disabled = false
	_populate_language_popup()


func _ensure_language_popup() -> void:
	if _language_popup == null:
		_language_popup = get_node_or_null("LanguageDropdownPopup") as Panel
	if _language_popup == null:
		_language_popup = Panel.new()
		_language_popup.name = "LanguageDropdownPopup"
		add_child(_language_popup)
	_language_popup.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_language_popup.position = Vector2.ZERO
	_language_popup.size = Vector2(744.0, 110.0)
	_language_popup.custom_minimum_size = _language_popup.size
	_language_popup.scale = Vector2.ONE
	_language_popup.visible = false
	_language_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_language_popup.add_theme_stylebox_override("panel", _card_style)
	_language_popup.z_index = 400
	_language_popup.clip_contents = false

	_language_popup_list = _language_popup.get_node_or_null("LanguageRows") as VBoxContainer
	if _language_popup_list == null:
		_language_popup_list = VBoxContainer.new()
		_language_popup_list.name = "LanguageRows"
		_language_popup.add_child(_language_popup_list)
	_language_popup_list.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_language_popup_list.position = Vector2(12.0, 12.0)
	_language_popup_list.mouse_filter = Control.MOUSE_FILTER_STOP
	_language_popup_list.scale = Vector2.ONE


func _populate_language_popup() -> void:
	if _language_popup == null or _language_popup_list == null:
		return
	for child in _language_popup_list.get_children():
		child.queue_free()
	for index in _language_choices.size():
		var choice := _language_choices[index]
		var row := Button.new()
		row.name = "LanguageChoice%d" % index
		row.text = String(choice.get("label", ""))
		row.focus_mode = Control.FOCUS_NONE
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.custom_minimum_size = Vector2(720.0, 78.0)
		row.size = row.custom_minimum_size
		row.add_theme_font_size_override("font_size", 30)
		_apply_notebook_button_style(row)
		var locale_code := String(choice.get("code", ""))
		row.pressed.connect(_on_language_choice_pressed.bind(locale_code))
		_language_popup_list.add_child(row)
	_language_popup_list.size = Vector2(720.0, maxf(1.0, float(_language_choices.size()) * 86.0))
	_language_popup.size = _language_popup_list.size + Vector2(24.0, 24.0)
	_language_popup.custom_minimum_size = _language_popup.size


func _on_language_dropdown_pressed() -> void:
	if _language_popup == null:
		return
	if _language_popup.visible:
		_close_language_popup()
		return
	_populate_language_popup()
	_position_language_popup()
	_language_popup.visible = true
	_raise_control_in_parent(_language_popup)


func _position_language_popup() -> void:
	if _language_popup == null or _language_dropdown_button == null:
		return
	var button_rect := _language_dropdown_button.get_global_rect()
	var panel_rect := get_global_rect()
	var centered_x := (size.x - _language_popup.size.x) * 0.5
	var local_y := button_rect.position.y - panel_rect.position.y + button_rect.size.y + 8.0
	var local_position := Vector2(centered_x, local_y)
	var max_x := maxf(12.0, size.x - _language_popup.size.x - 12.0)
	var max_y := maxf(12.0, size.y - _language_popup.size.y - 12.0)
	_language_popup.position = Vector2(clampf(local_position.x, 12.0, max_x), clampf(local_position.y, 12.0, max_y))
	_language_popup.custom_minimum_size = _language_popup.size


func _close_language_popup() -> void:
	if _language_popup != null:
		_language_popup.visible = false


func _on_language_choice_pressed(locale_code: String) -> void:
	if _syncing_settings:
		return
	if locale_code.is_empty():
		GameSettings.set_use_system_locale(true)
	else:
		GameSettings.set_preferred_locale(locale_code)
	_close_language_popup()
	_update_labels()


func _on_locale_changed(_locale: String) -> void:
	_refresh_privacy_policy_ui(true)
	refresh()


func _style_timer_value_label(label: Label) -> void:
	if label == null:
		return
	label.add_theme_stylebox_override("normal", _card_style)
	label.add_theme_color_override("font_color", NOTEBOOK_TEXT_COLOR)
	label.add_theme_font_size_override("font_size", 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _layout_timer_controls(card_x: float, label_x: float, card_width: float, _label_width: float) -> void:
	var control_x := label_x - 22.0
	var row_width := card_width - 36.0
	var y := 150.0
	y = _layout_timer_block("duck_pond", _duck_pond_timeout_toggle, control_x, label_x, y, row_width)
	y = _layout_timer_block("mole_garden", _mole_garden_timeout_toggle, control_x, label_x, y, row_width)
	_tester_tools_y = y + SETTINGS_TESTER_TO_TIMER_GAP
	_update_timer_chip_styles("duck_pond")
	_update_timer_chip_styles("mole_garden")


func _layout_timer_block(timer_id: String, toggle: CheckButton, control_x: float, label_x: float, y: float, row_width: float) -> float:
	_move_control_to_content(toggle, Vector2(control_x, y), Vector2(row_width, SETTINGS_TOGGLE_ROW_HEIGHT))
	_layout_toggle_visual(toggle)
	_ensure_toggle_touch_proxy(toggle)
	var options_y := y + SETTINGS_TOGGLE_ROW_HEIGHT + SETTINGS_TIMER_OPTIONS_TOP_GAP
	_layout_timer_chip_row(timer_id, label_x, options_y)
	_layout_timer_custom_stepper(timer_id, label_x, options_y)
	if _is_timer_enabled(timer_id):
		return options_y + SETTINGS_TIMER_CHIP_SIZE.y + SETTINGS_TIMER_BLOCK_GAP
	return y + SETTINGS_TOGGLE_ROW_HEIGHT + SETTINGS_TIMER_DISABLED_GAP


func _layout_timer_chip_row(timer_id: String, label_x: float, y: float) -> void:
	var chips: Array = _timer_chip_buttons.get(timer_id, [])
	var x := label_x
	for index in range(chips.size()):
		var chip := chips[index] as Control
		var chip_size := SETTINGS_TIMER_CUSTOM_CHIP_SIZE if index == chips.size() - 1 else SETTINGS_TIMER_CHIP_SIZE
		_move_control_to_content(chip, Vector2(x, y), chip_size)
		_raise_control_in_parent(chip)
		x += chip_size.x + SETTINGS_TIMER_CHIP_GAP


func _layout_timer_custom_stepper(timer_id: String, label_x: float, y: float) -> void:
	var stepper := _timer_custom_steppers.get(timer_id) as Dictionary
	if stepper == null or stepper.is_empty():
		return
	var chips: Array = _timer_chip_buttons.get(timer_id, [])
	var x := label_x
	for index in range(chips.size()):
		var chip_size := SETTINGS_TIMER_CUSTOM_CHIP_SIZE if index == chips.size() - 1 else SETTINGS_TIMER_CHIP_SIZE
		x += chip_size.x + SETTINGS_TIMER_CHIP_GAP
	var visible_value := _active_settings_tab == SETTINGS_TAB_GAMEPLAY and _is_timer_enabled(timer_id) and _should_show_timer_custom_edit(timer_id)
	var minus_button := stepper.get("minus") as Button
	var value_label := stepper.get("value") as Label
	var plus_button := stepper.get("plus") as Button
	_move_control_to_content(minus_button, Vector2(x, y), SETTINGS_TIMER_STEPPER_BUTTON_SIZE)
	_move_control_to_content(value_label, Vector2(x + SETTINGS_TIMER_STEPPER_BUTTON_SIZE.x + SETTINGS_TIMER_CHIP_GAP, y), SETTINGS_TIMER_STEPPER_LABEL_SIZE)
	_move_control_to_content(plus_button, Vector2(x + SETTINGS_TIMER_STEPPER_BUTTON_SIZE.x + SETTINGS_TIMER_CHIP_GAP + SETTINGS_TIMER_STEPPER_LABEL_SIZE.x + SETTINGS_TIMER_CHIP_GAP, y), SETTINGS_TIMER_STEPPER_BUTTON_SIZE)
	for control in [minus_button, value_label, plus_button]:
		_set_control_visible(control, visible_value)
		_raise_control_in_parent(control)


func _update_timer_chip_styles(timer_id: String) -> void:
	var chips: Array = _timer_chip_buttons.get(timer_id, [])
	if chips.is_empty():
		return
	var seconds := _get_timer_seconds(timer_id)
	var selected_index := SETTINGS_TIMER_PRESETS.size()
	for index in range(SETTINGS_TIMER_PRESETS.size()):
		if absf(seconds - float(SETTINGS_TIMER_PRESETS[index])) < 0.5:
			selected_index = index
			break
	if bool(_timer_custom_visible.get(timer_id, false)) or _is_custom_timer_duration(timer_id):
		selected_index = SETTINGS_TIMER_PRESETS.size()
	for index in range(chips.size()):
		var chip := chips[index] as Button
		if chip == null:
			continue
		if index == selected_index:
			chip.add_theme_stylebox_override("normal", _tab_active_style)
			chip.add_theme_stylebox_override("hover", _tab_active_style)
			chip.add_theme_stylebox_override("pressed", _tab_active_style)
			chip.add_theme_color_override("font_color", NOTEBOOK_TEXT_COLOR)
		else:
			chip.add_theme_stylebox_override("normal", _tab_inactive_style)
			chip.add_theme_stylebox_override("hover", _tab_inactive_style)
			chip.add_theme_stylebox_override("pressed", _tab_inactive_style)
			chip.add_theme_color_override("font_color", NOTEBOOK_TEXT_COLOR)


func set_tester_tools_enabled(enabled: bool) -> void:
	tester_tools_enabled = enabled
	_ensure_tester_tools()
	_layout_tester_tools()
	refresh()


func _ensure_tester_tools() -> void:
	if _settings_content == null:
		return
	_tester_tools_root = _find_content_control("TesterTools")
	if _tester_tools_root == null:
		_tester_tools_root = Control.new()
		_tester_tools_root.name = "TesterTools"
		_settings_content.add_child(_tester_tools_root)
	_tester_tools_root.visible = tester_tools_enabled

	var title := _tester_tools_root.get_node_or_null("TesterTitle") as Label
	if title == null:
		title = Label.new()
		title.name = "TesterTitle"
		_tester_tools_root.add_child(title)
	title.text = tr("Tester Tools")
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("5f3b22"))

	var buttons := [
		["PrevDay", tr("Prev Day"), "step_day", -1],
		["NextDay", tr("Next Day"), "step_day", 1],
		["Spring", tr("Spring"), "season", "spring"],
		["Summer", tr("Summer"), "season", "summer"],
		["Fall", tr("Fall"), "season", "fall"],
		["Winter", tr("Winter"), "season", "winter"],
		["SeasonDay1", tr("Day 1"), "season_day", 1],
		["SeasonDay2", tr("Day 2"), "season_day", 2],
		["SeasonDay3", tr("Day 3"), "season_day", 3],
		["CompleteNext", tr("Complete Next"), "complete_next", ""],
		["CompleteAll", tr("Complete All"), "complete_all", ""],
		["UnlockEverything", tr("Unlock Everything"), "unlock_everything", ""],
		["ResetToday", tr("Reset Today"), "reset_today", ""],
		["DuckVisited", tr("Duck Visit"), "duck_visited", ""],
		["ResetFarm", tr("Reset Farm"), "reset_farm", ""],
	]
	for data in buttons:
		var button := _tester_tools_root.get_node_or_null(String(data[0])) as Button
		if button == null:
			button = Button.new()
			button.name = String(data[0])
			_tester_tools_root.add_child(button)
		button.text = String(data[1])
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 22)
		_copy_button_theme(button)
		var action := String(data[2])
		var payload = data[3]
		var callable := Callable(self, "_on_tester_tool_pressed").bind(action, payload)
		if not button.pressed.is_connected(callable):
			button.pressed.connect(callable)


func _on_tester_tool_pressed(action: String, payload: Variant) -> void:
	emit_signal("tester_action_requested", action, payload)


func _layout_tester_tools() -> void:
	if _settings_content == null:
		return
	if _tester_tools_root == null:
		_ensure_tester_tools()
	if _tester_tools_root == null:
		return
	var tester_height := 320.0 if tester_tools_enabled else 0.0
	_settings_content.size = Vector2(scroll_view_size.x - 32.0, _get_current_settings_content_height() + SETTINGS_CONTENT_BOTTOM_PADDING)
	_settings_content.custom_minimum_size = _settings_content.size
	var content_width := scroll_view_size.x - 32.0
	var control_width := minf(SETTINGS_CONTENT_MAX_WIDTH, maxf(720.0, content_width - SETTINGS_CONTENT_SIDE_GUTTER * 2.0))
	var content_left := maxf(0.0, (content_width - control_width) * 0.5)
	_tester_tools_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_tester_tools_root.position = Vector2(content_left + 14.0, _tester_tools_y)
	_tester_tools_root.size = Vector2(control_width - 28.0, tester_height)
	_tester_tools_root.custom_minimum_size = _tester_tools_root.size
	_tester_tools_root.visible = tester_tools_enabled and _active_settings_tab == SETTINGS_TAB_GAMEPLAY
	if not tester_tools_enabled:
		return

	var title := _tester_tools_root.get_node_or_null("TesterTitle") as Control
	if title != null:
		title.position = Vector2(40.0, 0.0)
		title.size = Vector2(maxf(320.0, _tester_tools_root.size.x - 80.0), 42.0)
	var button_size := Vector2(200.0, 54.0)
	var button_gap := Vector2(12.0, 12.0)
	var available_button_width := _tester_tools_root.size.x - 80.0 + button_gap.x
	var buttons_per_row: int = maxi(2, int(available_button_width / (button_size.x + button_gap.x)))
	var index: int = 0
	for child in _tester_tools_root.get_children():
		if not (child is Button):
			continue
		var button := child as Button
		var col: int = index % buttons_per_row
		var row: int = int(index / buttons_per_row)
		button.position = Vector2(40.0 + col * (button_size.x + button_gap.x), 54.0 + row * (button_size.y + button_gap.y))
		button.size = button_size
		button.custom_minimum_size = button_size
		index += 1


func _copy_button_theme(target: Button) -> void:
	if target == null:
		return
	_apply_notebook_button_style(target)


func _move_named_control_to_content(node_name: String, position: Vector2, size: Vector2) -> void:
	var control := get_node_or_null(node_name) as Control
	if control == null and _settings_content != null:
		control = _find_content_control(node_name)
	_move_control_to_content(control, position, size)


func _move_control_to_content(control: Control, position: Vector2, size: Vector2) -> void:
	if control == null or _settings_content == null:
		return
	if control.get_parent() != _settings_content:
		control.reparent(_settings_content)
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = position
	control.custom_minimum_size = size
	control.size = size
	control.scale = Vector2.ONE
	if control is Label:
		_style_notebook_label(control as Label)
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _raise_control_in_parent(control: Control) -> void:
	if control == null:
		return
	var parent := control.get_parent()
	if parent != null:
		parent.move_child(control, parent.get_child_count() - 1)


func _raise_sound_mute_buttons() -> void:
	for button in [_master_mute_button, _music_mute_button, _sfx_mute_button, _voice_over_mute_button]:
		if button == null:
			continue
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.disabled = false
		_raise_control_in_parent(button)
		var proxy = _button_proxies.get(button.name)
		if proxy != null and is_instance_valid(proxy):
			var control := proxy as Control
			control.position = button.position
			control.custom_minimum_size = button.size
			control.size = button.size
			control.visible = button.visible
			control.mouse_filter = Control.MOUSE_FILTER_STOP
			_raise_control_in_parent(control)


func _find_content_control(node_name: String) -> Control:
	if _settings_content == null:
		return null
	var direct := _settings_content.get_node_or_null(node_name) as Control
	if direct != null:
		return direct
	return _find_control_recursive(_settings_content, node_name)


func _find_control_recursive(root: Node, node_name: String) -> Control:
	for child in root.get_children():
		if child.name == node_name and child is Control:
			return child as Control
		var nested := _find_control_recursive(child, node_name)
		if nested != null:
			return nested
	return null


func _find_content_controls(node_name: String) -> Array[Control]:
	var results: Array[Control] = []
	if _settings_content != null:
		_collect_named_controls(_settings_content, node_name, results)
	return results


func _collect_named_controls(root: Node, node_name: String, results: Array[Control]) -> void:
	for child in root.get_children():
		if child.name == node_name and child is Control:
			results.append(child as Control)
		_collect_named_controls(child, node_name, results)


func _is_descendant_of(node: Node, ancestor: Node) -> bool:
	var current := node.get_parent()
	while current != null:
		if current == ancestor:
			return true
		current = current.get_parent()
	return false


func _style_notebook_label(label: Label) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", NOTEBOOK_TEXT_COLOR)
	label.add_theme_color_override("font_shadow_color", Color(1.0, 0.94, 0.70, 0.42))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)


func _layout_toggle_visual(toggle: CheckButton) -> void:
	if toggle == null or _settings_content == null:
		return
	_configure_toggle_row(toggle)
	var visual := _ensure_toggle_visual(toggle)
	if visual == null:
		return
	visual.set_anchors_preset(Control.PRESET_TOP_LEFT)
	visual.size = SETTINGS_TOGGLE_SWITCH_SIZE
	visual.custom_minimum_size = SETTINGS_TOGGLE_SWITCH_SIZE
	visual.position = toggle.position + Vector2(
		maxf(0.0, toggle.size.x - SETTINGS_TOGGLE_SWITCH_SIZE.x - SETTINGS_TOGGLE_SWITCH_RIGHT_PADDING),
		(toggle.size.y - SETTINGS_TOGGLE_SWITCH_SIZE.y) * 0.5
	)
	visual.scale = Vector2.ONE
	_settings_content.move_child(visual, _settings_content.get_child_count() - 1)


func _ensure_toggle_visual(toggle: CheckButton) -> Control:
	if toggle == null or _settings_content == null:
		return null
	var visual_name := "%sSwitchVisual" % toggle.name
	var visual := _find_content_control(visual_name)
	if visual == null:
		visual = ToggleSwitchVisualScript.new()
		visual.name = visual_name
		_settings_content.add_child(visual)
	_toggle_visuals[toggle.name] = visual
	visual.call("configure", toggle)
	visual.set("on_color", NOTEBOOK_GREEN)
	visual.set("off_color", Color("d8c8a4"))
	visual.set("border_color", NOTEBOOK_DARK_BORDER_COLOR)
	visual.set("knob_color", Color("fff6dc"))
	visual.set("knob_shadow_color", Color(0.32, 0.20, 0.11, 0.18))
	return visual


func _configure_toggle_row(toggle: CheckButton) -> void:
	if toggle == null:
		return
	toggle.add_theme_font_size_override("font_size", SETTINGS_TOGGLE_FONT_SIZE)
	toggle.custom_minimum_size = SETTINGS_TOGGLE_MIN_SIZE
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggle.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	toggle.add_theme_constant_override("h_separation", 0)
	toggle.add_theme_color_override("font_color", NOTEBOOK_TEXT_COLOR)
	toggle.add_theme_color_override("font_pressed_color", NOTEBOOK_TEXT_COLOR)
	toggle.add_theme_color_override("font_hover_color", NOTEBOOK_TEXT_COLOR)
	toggle.add_theme_color_override("font_focus_color", NOTEBOOK_TEXT_COLOR)
	toggle.add_theme_stylebox_override("normal", _toggle_row_style)
	toggle.add_theme_stylebox_override("pressed", _toggle_row_style)
	toggle.add_theme_stylebox_override("hover", _toggle_row_style)
	toggle.add_theme_stylebox_override("hover_pressed", _toggle_row_style)
	toggle.add_theme_stylebox_override("disabled", _toggle_row_style)
	toggle.add_theme_stylebox_override("focus", _toggle_row_style)
	var empty_icon := _get_transparent_toggle_icon()
	for icon_name in ["checked", "unchecked", "checked_disabled", "unchecked_disabled", "radio_checked", "radio_unchecked"]:
		toggle.add_theme_icon_override(icon_name, empty_icon)


func _get_transparent_toggle_icon() -> Texture2D:
	if _transparent_toggle_icon != null:
		return _transparent_toggle_icon
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 0.0))
	_transparent_toggle_icon = ImageTexture.create_from_image(image)
	return _transparent_toggle_icon


func _copy_toggle_theme(source: CheckButton, target: CheckButton) -> void:
	if source == null or target == null:
		return
	for style_name in ["normal", "pressed", "hover", "hover_pressed", "disabled", "focus"]:
		var stylebox := source.get_theme_stylebox(style_name)
		if stylebox != null:
			target.add_theme_stylebox_override(style_name, stylebox)
	var font_size := source.get_theme_font_size("font_size")
	if font_size > 0:
		target.add_theme_font_size_override("font_size", font_size)
	for color_name in ["font_color", "font_pressed_color", "font_hover_color", "font_focus_color", "font_disabled_color"]:
		var color := source.get_theme_color(color_name)
		target.add_theme_color_override(color_name, color)


func _apply_gameplay_toggle_theme() -> void:
	var source := _music_toggle if _music_toggle != null else _voice_over_toggle
	for toggle in [_duck_pond_timeout_toggle, _mole_garden_timeout_toggle, _tap_anywhere_return_toggle]:
		if toggle == null:
			continue
		_copy_toggle_theme(source, toggle)
		_configure_toggle_row(toggle)


func _style_scrollbars() -> void:
	if _scroll_area == null:
		return
	var v_scroll := _scroll_area.get_v_scroll_bar()
	if v_scroll != null:
		v_scroll.custom_minimum_size = Vector2(24.0, 0.0)
		v_scroll.add_theme_constant_override("minimum_grab_size", 72)
		var scroll_style := _make_stylebox(Color(0.86, 0.76, 0.55, 0.20), Color(0.0, 0.0, 0.0, 0.0), 0, 12)
		var grabber_style := _make_stylebox(Color(0.67, 0.52, 0.32, 0.72), Color(0.45, 0.31, 0.17, 0.36), 2, 12)
		v_scroll.add_theme_stylebox_override("scroll", scroll_style)
		v_scroll.add_theme_stylebox_override("grabber", grabber_style)
		v_scroll.add_theme_stylebox_override("grabber_highlight", grabber_style)
		v_scroll.add_theme_stylebox_override("grabber_pressed", grabber_style)
	var h_scroll := _scroll_area.get_h_scroll_bar()
	if h_scroll != null:
		h_scroll.custom_minimum_size = Vector2(0.0, 24.0)
		h_scroll.add_theme_constant_override("minimum_grab_size", 72)


func _refresh_exported_node_paths() -> void:
	# The panel keeps exported paths valid after moving controls into the scroll content.
	if _close_button != null:
		close_button_path = get_path_to(_close_button)
	if _music_toggle != null:
		music_toggle_path = get_path_to(_music_toggle)
	if _voice_over_toggle != null:
		voice_over_toggle_path = get_path_to(_voice_over_toggle)
	if _master_volume_slider != null:
		master_volume_slider_path = get_path_to(_master_volume_slider)
	if _music_volume_slider != null:
		music_volume_slider_path = get_path_to(_music_volume_slider)
	if _sfx_volume_slider != null:
		sfx_volume_slider_path = get_path_to(_sfx_volume_slider)
	if _voice_over_volume_slider != null:
		voice_over_volume_slider_path = get_path_to(_voice_over_volume_slider)
	if _master_volume_label != null:
		master_volume_label_path = get_path_to(_master_volume_label)
	if _music_volume_label != null:
		music_volume_label_path = get_path_to(_music_volume_label)
	if _sfx_volume_label != null:
		sfx_volume_label_path = get_path_to(_sfx_volume_label)
	if _voice_over_volume_label != null:
		voice_over_volume_label_path = get_path_to(_voice_over_volume_label)


func _ensure_toggle_touch_proxy(toggle: CheckButton) -> void:
	if toggle == null or _settings_content == null:
		return

	var proxy_name := "%sTouchProxy" % toggle.name
	var proxy := _find_content_control(proxy_name)
	if proxy == null:
		proxy = ToggleTouchProxyScript.new()
		proxy.name = proxy_name
		_settings_content.add_child(proxy)
	_toggle_proxies[toggle.name] = proxy

	proxy.call("configure", toggle)
	proxy.set_anchors_preset(Control.PRESET_TOP_LEFT)
	proxy.position = toggle.position
	var proxy_size := toggle.size
	if toggle == _duck_pond_timeout_toggle or toggle == _mole_garden_timeout_toggle:
		proxy_size.y = minf(proxy_size.y, SETTINGS_TIMER_HEADER_TOUCH_HEIGHT)
	proxy.size = proxy_size
	proxy.custom_minimum_size = proxy.size
	proxy.scale = Vector2.ONE
	_settings_content.move_child(proxy, _settings_content.get_child_count() - 1)


func _ensure_button_touch_proxy(button: Button) -> void:
	if button == null or _settings_content == null:
		return

	var proxy_name := "%sTouchProxy" % button.name
	var proxy: Control
	var matching_proxies := _find_content_controls(proxy_name)
	for candidate in matching_proxies:
		if proxy == null:
			proxy = candidate
		else:
			candidate.queue_free()
	if proxy == null:
		proxy = ButtonTouchProxyScript.new()
		proxy.name = proxy_name
		_settings_content.add_child(proxy)
	elif proxy.get_parent() != _settings_content:
		proxy.reparent(_settings_content)
	_button_proxies[button.name] = proxy

	proxy.call("configure", button)
	proxy.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var button_rect := button.get_global_rect()
	var content_rect := _settings_content.get_global_rect()
	proxy.position = button_rect.position - content_rect.position
	proxy.custom_minimum_size = button.size
	proxy.size = button.size
	proxy.scale = Vector2.ONE
	proxy.visible = button.visible
	_settings_content.move_child(proxy, _settings_content.get_child_count() - 1)


func _ensure_slider_touch_proxy(slider: HSlider) -> void:
	if slider == null or _settings_content == null:
		return

	var proxy_name := "%sTouchProxy" % slider.name
	var proxy: Control
	var matching_proxies := _find_content_controls(proxy_name)
	for candidate in matching_proxies:
		if proxy == null:
			proxy = candidate
		else:
			candidate.queue_free()
	if proxy == null:
		proxy = SliderTouchProxyScript.new()
		proxy.name = proxy_name
		_settings_content.add_child(proxy)
	elif proxy.get_parent() != _settings_content:
		proxy.reparent(_settings_content)
	_slider_proxies[slider.name] = proxy

	var horizontal_padding := SETTINGS_SLIDER_TOUCH_PADDING
	var vertical_padding := SETTINGS_SLIDER_VERTICAL_PADDING
	proxy.call("configure", slider, horizontal_padding)
	proxy.set("track_color", Color("dfc58f"))
	proxy.set("fill_color", NOTEBOOK_SOFT_GREEN)
	proxy.set("border_color", NOTEBOOK_DARK_BORDER_COLOR)
	proxy.set("knob_color", Color("fff5d8"))
	proxy.set("knob_shadow_color", Color(0.32, 0.20, 0.11, 0.18))
	proxy.set("track_height", 20.0)
	proxy.set("knob_radius", 30.0)
	proxy.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var proxy_position := slider.position + Vector2(-horizontal_padding, -vertical_padding)
	var proxy_size := Vector2(slider.size.x + horizontal_padding * 2.0, slider.size.y + vertical_padding * 2.0)
	var mute_button := _get_mute_button_for_slider(slider)
	if mute_button != null:
		var max_proxy_right := mute_button.position.x - 24.0
		proxy_size.x = minf(proxy_size.x, maxf(1.0, max_proxy_right - proxy_position.x))
		var slider_width := maxf(1.0, proxy_size.x - horizontal_padding * 2.0)
		slider.custom_minimum_size = Vector2(slider_width, slider.size.y)
		slider.size = Vector2(slider_width, slider.size.y)
	proxy.position = proxy_position
	proxy.custom_minimum_size = proxy_size
	proxy.size = proxy_size
	proxy.scale = Vector2.ONE
	_settings_content.move_child(proxy, _settings_content.get_child_count() - 1)


func _get_mute_button_for_slider(slider: HSlider) -> Button:
	if slider == null:
		return null
	match String(slider.name):
		"MasterVolumeSlider":
			return _master_mute_button if _master_mute_button != null else _find_content_control("MasterMuteButton") as Button
		"MusicVolumeSlider":
			return _music_mute_button if _music_mute_button != null else _find_content_control("MusicMuteButton") as Button
		"SfxVolumeSlider":
			return _sfx_mute_button if _sfx_mute_button != null else _find_content_control("SfxMuteButton") as Button
		"VoiceOverVolumeSlider":
			return _voice_over_mute_button if _voice_over_mute_button != null else _find_content_control("VoiceOverMuteButton") as Button
	return null


func refresh() -> void:
	_syncing_settings = true
	if _music_toggle != null:
		_music_toggle.button_pressed = MusicManager.is_music_enabled()
	if _voice_over_toggle != null:
		_voice_over_toggle.button_pressed = MusicManager.is_voice_over_enabled()
	if _master_volume_slider != null:
		_master_volume_slider.value = MusicManager.get_master_volume()
	if _music_volume_slider != null:
		_music_volume_slider.value = MusicManager.get_music_volume()
	if _sfx_volume_slider != null:
		_sfx_volume_slider.value = MusicManager.get_sfx_volume()
	if _voice_over_volume_slider != null:
		_voice_over_volume_slider.value = MusicManager.get_voice_over_volume()
	if _duck_pond_timeout_toggle != null:
		_duck_pond_timeout_toggle.button_pressed = GameSettings.is_duck_pond_time_limit_enabled()
	if _mole_garden_timeout_toggle != null:
		_mole_garden_timeout_toggle.button_pressed = GameSettings.is_mole_garden_time_limit_enabled()
	if _tap_anywhere_return_toggle != null:
		_tap_anywhere_return_toggle.button_pressed = GameSettings.is_tap_anywhere_chore_return_enabled()
	if _language_dropdown_button != null:
		_refresh_language_choices()
	_sync_timer_custom_stepper("duck_pond")
	_sync_timer_custom_stepper("mole_garden")
	_syncing_settings = false
	_ensure_scroll_layout()
	_update_labels()


func _configure_slider(slider: HSlider) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = slider_touch_size
	slider.size = slider_touch_size
	slider.scale = Vector2.ONE
	slider.modulate.a = 0.0
	slider.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_music_toggled(enabled: bool) -> void:
	if _syncing_settings:
		return
	MusicManager.set_music_enabled(enabled)
	_update_labels()


func _on_voice_over_toggled(enabled: bool) -> void:
	if _syncing_settings:
		return
	MusicManager.set_voice_over_enabled(enabled)
	_update_labels()


func _on_duck_pond_timeout_toggled(enabled: bool) -> void:
	if _syncing_settings:
		return
	GameSettings.set_duck_pond_time_limit_enabled(enabled)
	_ensure_scroll_layout()
	_update_labels()


func _on_mole_garden_timeout_toggled(enabled: bool) -> void:
	if _syncing_settings:
		return
	GameSettings.set_mole_garden_time_limit_enabled(enabled)
	_ensure_scroll_layout()
	_update_labels()


func _on_tap_anywhere_return_toggled(enabled: bool) -> void:
	if _syncing_settings:
		return
	GameSettings.set_tap_anywhere_chore_return_enabled(enabled)
	_update_labels()


func _on_master_volume_changed(value: float) -> void:
	if _syncing_settings:
		return
	MusicManager.set_master_volume(float(value))
	_update_labels()


func _on_music_volume_changed(value: float) -> void:
	if _syncing_settings:
		return
	MusicManager.set_music_volume(float(value))
	_update_labels()


func _on_sfx_volume_changed(value: float) -> void:
	if _syncing_settings:
		return
	MusicManager.set_sfx_volume(float(value))
	_update_labels()
	FarmFeedback.play_one_shot(self, preview_sound, -8.0)


func _on_voice_over_volume_changed(value: float) -> void:
	if _syncing_settings:
		return
	MusicManager.set_voice_over_volume(float(value))
	_update_labels()


func _on_master_mute_pressed() -> void:
	MusicManager.toggle_master_muted()
	refresh()


func _on_music_mute_pressed() -> void:
	MusicManager.toggle_music_muted()
	refresh()


func _on_sfx_mute_pressed() -> void:
	MusicManager.toggle_sfx_muted()
	refresh()


func _on_voice_over_mute_pressed() -> void:
	MusicManager.toggle_voice_over_muted()
	refresh()


func _on_timer_preset_pressed(timer_id: String, seconds: float) -> void:
	_timer_custom_visible[timer_id] = false
	_set_timer_seconds(timer_id, seconds)
	_sync_timer_custom_stepper(timer_id)
	_update_labels()
	_apply_settings_tab_visibility()


func _on_timer_custom_pressed(timer_id: String) -> void:
	_timer_custom_visible[timer_id] = true
	if not _is_custom_timer_duration(timer_id):
		_set_timer_seconds(timer_id, _get_timer_seconds(timer_id))
	_sync_timer_custom_stepper(timer_id)
	_update_labels()
	_apply_settings_tab_visibility()


func _on_timer_custom_step_pressed(timer_id: String, delta_minutes: int) -> void:
	var minutes := clampi(roundi(_get_timer_seconds(timer_id) / 60.0) + delta_minutes, 1, 30)
	_timer_custom_visible[timer_id] = true
	_set_timer_seconds(timer_id, float(minutes) * 60.0)
	_sync_timer_custom_stepper(timer_id)
	_update_labels()
	_apply_settings_tab_visibility()


func _apply_custom_timer_minutes(timer_id: String, text: String) -> void:
	var minutes := clampi(int(text), 1, 30)
	_set_timer_seconds(timer_id, float(minutes) * 60.0)
	_timer_custom_visible[timer_id] = true
	_sync_timer_custom_stepper(timer_id)
	_update_labels()
	_apply_settings_tab_visibility()


func _set_timer_seconds(timer_id: String, seconds: float) -> void:
	if timer_id == "duck_pond":
		GameSettings.set_duck_pond_time_limit_seconds(seconds)
	elif timer_id == "mole_garden":
		GameSettings.set_mole_garden_time_limit_seconds(seconds)


func _get_timer_seconds(timer_id: String) -> float:
	if timer_id == "duck_pond":
		return GameSettings.get_duck_pond_time_limit_seconds()
	if timer_id == "mole_garden":
		return GameSettings.get_mole_garden_time_limit_seconds()
	return GameSettings.DEFAULT_TIMER_SECONDS


func _is_timer_enabled(timer_id: String) -> bool:
	if timer_id == "duck_pond":
		return GameSettings.is_duck_pond_time_limit_enabled()
	if timer_id == "mole_garden":
		return GameSettings.is_mole_garden_time_limit_enabled()
	return false


func _sync_timer_custom_stepper(timer_id: String) -> void:
	var stepper := _timer_custom_steppers.get(timer_id) as Dictionary
	if stepper == null or stepper.is_empty():
		return
	var value_label := stepper.get("value") as Label
	if value_label != null:
		value_label.text = _get_timer_minutes_text(timer_id)


func _should_show_timer_custom_edit(timer_id: String) -> bool:
	return bool(_timer_custom_visible.get(timer_id, false)) or _is_custom_timer_duration(timer_id)


func _is_custom_timer_duration(timer_id: String) -> bool:
	var seconds := _get_timer_seconds(timer_id)
	for preset in SETTINGS_TIMER_PRESETS:
		if absf(seconds - float(preset)) < 0.5:
			return false
	return true


func _get_timer_minutes_text(timer_id: String) -> String:
	var minutes := clampi(roundi(_get_timer_seconds(timer_id) / 60.0), 1, 30)
	return tr("%d minute%s") % [minutes, "" if minutes == 1 else "s"]


func _update_labels() -> void:
	var title := get_node_or_null("SettingsTitle") as Label
	if title != null:
		title.text = tr("Farm Settings")
	var language_title := _find_content_control("LanguageTitle") as Label
	if language_title != null:
		language_title.text = tr("Language")
	if _close_button != null:
		_close_button.text = tr("Done")
	if _sound_tab_button != null:
		_sound_tab_button.text = tr("Sound")
	if _gameplay_tab_button != null:
		_gameplay_tab_button.text = tr("Gameplay")
	if _language_tab_button != null:
		_language_tab_button.text = tr("Language")
	if _privacy_button != null:
		_privacy_button.text = tr("Privacy & Parents")
	_refresh_privacy_policy_ui()
	if _music_toggle != null:
		_music_toggle.text = tr("Music On") if MusicManager.is_music_enabled() else tr("Music Off")
	if _voice_over_toggle != null:
		_voice_over_toggle.text = tr("Voice Over On") if MusicManager.is_voice_over_enabled() else tr("Voice Over Off")
	if _duck_pond_timeout_toggle != null:
		if GameSettings.is_duck_pond_time_limit_enabled():
			_duck_pond_timeout_toggle.text = tr("Duck Pond Timer %s %s") % [tr("On"), _get_timer_minutes_text("duck_pond")]
		else:
			_duck_pond_timeout_toggle.text = tr("Duck Pond Timer Off")
	if _mole_garden_timeout_toggle != null:
		if GameSettings.is_mole_garden_time_limit_enabled():
			_mole_garden_timeout_toggle.text = tr("Mole Garden Timer %s %s") % [tr("On"), _get_timer_minutes_text("mole_garden")]
		else:
			_mole_garden_timeout_toggle.text = tr("Mole Garden Timer Off")
	if _tap_anywhere_return_toggle != null:
		_tap_anywhere_return_toggle.text = tr("Tap Anywhere to Play On") if GameSettings.is_tap_anywhere_chore_return_enabled() else tr("Tap Anywhere to Play Off")
	if _master_volume_label != null:
		_master_volume_label.text = tr("All Sound: %d%%") % roundi(MusicManager.get_master_volume() * 100.0)
	if _music_volume_label != null:
		_music_volume_label.text = tr("Music: %d%%") % roundi(MusicManager.get_music_volume() * 100.0)
	if _sfx_volume_label != null:
		_sfx_volume_label.text = tr("Sound Effects: %d%%") % roundi(MusicManager.get_sfx_volume() * 100.0)
	if _voice_over_volume_label != null:
		_voice_over_volume_label.text = tr("Voice Over: %d%%") % roundi(MusicManager.get_voice_over_volume() * 100.0)
	if _master_mute_button != null:
		_master_mute_button.text = tr("On") if not MusicManager.is_master_muted() else tr("Off")
	if _music_mute_button != null:
		_music_mute_button.text = tr("On") if not MusicManager.is_music_muted() else tr("Off")
	if _sfx_mute_button != null:
		_sfx_mute_button.text = tr("On") if not MusicManager.is_sfx_muted() else tr("Off")
	if _voice_over_mute_button != null:
		_voice_over_mute_button.text = tr("On") if not MusicManager.is_voice_over_muted() else tr("Off")
	var tester_title := get_node_or_null("SettingsScroll/SettingsContent/GameplaySettings/TesterTools/TesterTitle") as Label
	if tester_title != null:
		tester_title.text = tr("Tester Tools")
	for chips in _timer_chip_buttons.values():
		var chip_array: Array = chips if chips is Array else []
		if chip_array.is_empty():
			continue
		var last_chip := chip_array[chip_array.size() - 1] as Button
		if last_chip != null:
			last_chip.text = tr("Custom")
	var tester_root := get_node_or_null("SettingsScroll/SettingsContent/GameplaySettings/TesterTools") as Control
	if tester_root != null:
		var tester_button_labels := {
			"PrevDay": tr("Prev Day"),
			"NextDay": tr("Next Day"),
			"Spring": tr("Spring"),
			"Summer": tr("Summer"),
			"Fall": tr("Fall"),
			"Winter": tr("Winter"),
			"SeasonDay1": tr("Day 1"),
			"SeasonDay2": tr("Day 2"),
			"SeasonDay3": tr("Day 3"),
			"CompleteNext": tr("Complete Next"),
			"CompleteAll": tr("Complete All"),
			"UnlockEverything": tr("Unlock Everything"),
			"ResetToday": tr("Reset Today"),
			"DuckVisited": tr("Duck Visit"),
			"ResetFarm": tr("Reset Farm"),
		}
		for button_name in tester_button_labels.keys():
			var tester_button := tester_root.get_node_or_null(button_name) as Button
			if tester_button != null:
				tester_button.text = str(tester_button_labels[button_name])
	_refresh_language_choices()
	_update_timer_chip_styles("duck_pond")
	_update_timer_chip_styles("mole_garden")
	for visual in _toggle_visuals.values():
		if visual != null and is_instance_valid(visual):
			(visual as Control).queue_redraw()
	for proxy in _slider_proxies.values():
		if proxy != null and is_instance_valid(proxy):
			(proxy as Control).queue_redraw()
