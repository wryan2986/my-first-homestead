extends Control

@export var farmyard_scene: PackedScene
@export var title_label: NodePath
@export var subtitle_label: NodePath
@export var start_button: NodePath
@export var settings_button: NodePath
@export var settings_panel: NodePath
@export var start_sound: AudioStream
@export var reset_on_start := false
@export var subtitle_text := "Every helper tap makes the farm brighter."

@onready var _title_label: Label = get_node_or_null(title_label) as Label
@onready var _subtitle_label: Label = get_node_or_null(subtitle_label) as Label
@onready var _start_button: Button = get_node_or_null(start_button) as Button
@onready var _settings_button: Button = get_node_or_null(settings_button) as Button
@onready var _settings_panel: Control = get_node_or_null(settings_panel) as Control

var _starting := false


func _ready() -> void:
	if reset_on_start:
		FarmState.reset_all_state()
	MusicManager.play_farmyard_music()
	if GameSettings.has_signal("locale_changed") and not GameSettings.locale_changed.is_connected(_refresh_text):
		GameSettings.locale_changed.connect(_refresh_text)
	if _start_button != null:
		_start_button.pressed.connect(_start_game)
	if _settings_button != null:
		_settings_button.pressed.connect(_open_settings)
	if _settings_panel != null:
		_settings_panel.call("close")
	_refresh_text()
	if _title_label != null:
		FarmFeedback.pulse(_title_label, 1.03, 0.3)
	if farmyard_scene != null:
		call_deferred("_prewarm_farmyard_scene")


func _unhandled_input(event: InputEvent) -> void:
	if _settings_panel != null and _settings_panel.visible:
		if event is InputEventScreenTouch and event.pressed:
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
		return

	if not GameSettings.is_tap_anywhere_chore_return_enabled():
		return

	if event is InputEventScreenTouch and event.pressed:
		get_viewport().set_input_as_handled()
		_start_game()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_start_game()


func _start_game() -> void:
	if _starting or farmyard_scene == null:
		return
	_starting = true
	FarmFeedback.play_one_shot(self, start_sound, -4.0)
	if SceneNavigator.show_farmyard(farmyard_scene):
		return
	get_tree().change_scene_to_packed(farmyard_scene)


func _prewarm_farmyard_scene() -> void:
	if farmyard_scene != null and SceneNavigator.has_method("prepare_farmyard"):
		SceneNavigator.prepare_farmyard(farmyard_scene)


func _open_settings() -> void:
	if _settings_panel == null:
		return
	_settings_panel.call("open")


func _refresh_text(_locale: String = "") -> void:
	if _title_label != null:
		_title_label.text = tr("My First Homestead")
	if _subtitle_label != null:
		_subtitle_label.text = tr(subtitle_text)
	if _start_button != null:
		_start_button.text = tr("")
	if _settings_button != null:
		_settings_button.tooltip_text = tr("Settings")
