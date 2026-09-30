extends Node2D

const ChoreAssistScript := preload("res://scripts/core/ChoreAssist.gd")
const ChoreCompletionFlowScript := preload("res://scripts/core/ChoreCompletionFlow.gd")
const ChoreRuntimeScript := preload("res://scripts/core/ChoreRuntime.gd")
const ASSIST_STAGE_STRONG_HINT := 2
const ASSIST_STAGE_ACTION := 3

@export_file("*.tscn") var farmyard_scene_path := "res://scenes/FarmyardScene.tscn"
@export var brush_button: NodePath
@export var brush_visual: NodePath
@export var brush_token_texture: Texture2D
@export var feedback_label: NodePath
@export var progress_label: NodePath
@export var completion_panel: NodePath
@export var completion_label: NodePath
@export var back_button: NodePath
@export var animal_card_paths: Array[NodePath] = []
@export var brush_sound: AudioStream
@export var completion_sound: AudioStream
@export var direct_tap_margin := 22.0
@export var assist_stage_two_radius := 190.0
@export var post_completion_return_delay := 7.0
@export var post_completion_return_lock := 1.0

var _brush_animation_active := false
var _completion_active := false
var _assist: RefCounted = ChoreAssistScript.new()
@onready var _brush_button: Button = get_node_or_null(brush_button) as Button
@onready var _brush_visual: Node2D = get_node_or_null(brush_visual) as Node2D
@onready var _feedback_label: Label = get_node_or_null(feedback_label) as Label
@onready var _progress_label: Label = get_node_or_null(progress_label) as Label
@onready var _completion_panel: Control = get_node_or_null(completion_panel) as Control
@onready var _completion_label: Label = get_node_or_null(completion_label) as Label
@onready var _back_button: Button = get_node_or_null(back_button) as Button


func _ready() -> void:
	if _is_scene_navigator_cache_prepare():
		return
	_completion_active = false
	MusicManager.play_chore_music()
	if GameSettings.has_signal("locale_changed") and not GameSettings.locale_changed.is_connected(_refresh_ui):
		GameSettings.locale_changed.connect(_refresh_ui)
	ChoreRuntimeScript.configure_assist(_assist, FarmState.CHORE_BRUSHING)
	if _brush_button != null and not _brush_button.pressed.is_connected(_show_brush_hint):
		_brush_button.pressed.connect(_show_brush_hint)
	if _back_button != null and not _back_button.pressed.is_connected(_return_to_farmyard):
		_back_button.pressed.connect(_return_to_farmyard)
	if _completion_panel != null:
		_completion_panel.visible = false
	ChoreCompletionFlowScript.prepare_chore_scene(self, _back_button)
	FarmFeedback.hide_play_scene_text(self)

	for card_path in animal_card_paths:
		var card := get_node_or_null(card_path) as FarmAnimalCard
		if card == null:
			continue
		if not card.tapped.is_connected(_on_card_tapped):
			card.tapped.connect(_on_card_tapped)
		card.set_completed(FarmState.is_animal_brushed(card.animal_id), tr("Brushed and shiny!"))
		if card.animal_id == "duck" and not FarmState.has_unlock("duck_pond"):
			card.visible = false
			card.set_card_enabled(false)

	_refresh_ui()
	if FarmState.is_chore_completed(FarmState.CHORE_BRUSHING):
		_show_completion(false)


func prepare_for_cached_scene() -> void:
	pass


func activate_from_cache() -> void:
	_ready()


func deactivate_for_cache_or_free() -> void:
	pass


func _is_scene_navigator_cache_prepare() -> bool:
	return has_meta("_scene_navigator_cache_prepare")


func _process(_delta: float) -> void:
	if _completion_active or FarmState.is_chore_completed(FarmState.CHORE_BRUSHING):
		return
	if bool(_assist.call("should_show_hint")):
		_show_assist_hint(int(_assist.call("get_stage")) >= ASSIST_STAGE_STRONG_HINT)


func _input(event: InputEvent) -> void:
	if _completion_active:
		ChoreCompletionFlowScript.handle_completion_return_input(self, event, farmyard_scene_path)


func _unhandled_input(event: InputEvent) -> void:
	if _completion_active or FarmState.is_chore_completed(FarmState.CHORE_BRUSHING):
		return
	if not ChoreCompletionFlowScript.is_tap_event(event):
		return

	if _handle_direct_tap(event):
		get_viewport().set_input_as_handled()
		return

	get_viewport().set_input_as_handled()
	_handle_failed_tap(event)


func _show_brush_hint() -> void:
	if _completion_active:
		return
	_handle_failed_tap(null)
	if _brush_visual != null:
		FarmFeedback.pulse(_brush_visual, 1.14, 0.14)
		FarmFeedback.flash(_brush_visual, Color("d8fbff"), 0.12)


func _on_card_tapped(card: FarmAnimalCard) -> void:
	if _completion_active:
		return
	if _brush_card(card, false):
		return
	_handle_failed_tap(null)


func _handle_direct_tap(event: InputEvent) -> bool:
	for card_path in animal_card_paths:
		var card := get_node_or_null(card_path) as FarmAnimalCard
		if card == null or not card.visible:
			continue
		if ChoreCompletionFlowScript.is_event_inside_area(event, card, self, direct_tap_margin):
			_on_card_tapped(card)
			return true
	return false


func _brush_card(card: FarmAnimalCard, assisted: bool = false) -> bool:
	if _completion_active:
		return false
	if _brush_animation_active:
		return false
	if card.is_completed():
		return false
	if not FarmState.brush_animal(card.animal_id):
		return false

	_brush_animation_active = true
	var completed_after_brush := FarmState.is_chore_completed(FarmState.CHORE_BRUSHING)
	_send_brush_to(card, Callable(self, "_show_completion").bind(true) if completed_after_brush else Callable())
	card.cheer("So soft!")
	_record_progress()
	FarmFeedback.play_one_shot(self, brush_sound, -4.0)
	_refresh_ui()

	return true


func _handle_failed_tap(event) -> void:
	var stage_before := int(_assist.call("get_stage"))
	if event is InputEvent and stage_before >= ASSIST_STAGE_STRONG_HINT and _is_event_near_next_card(event):
		_brush_next_available_animal()
		return

	var stage := _record_failed_attempt()
	if event is InputEvent and stage >= ASSIST_STAGE_STRONG_HINT and _is_event_near_next_card(event):
		_brush_next_available_animal()
		return

	if stage >= ASSIST_STAGE_ACTION and bool(_assist.call("can_perform_assist_action")):
		ChoreRuntimeScript.mark_assist_action_performed(_assist, FarmState.CHORE_BRUSHING)
		_brush_next_available_animal()
		return

	if bool(_assist.call("should_show_hint")):
		_show_assist_hint(stage >= ASSIST_STAGE_STRONG_HINT)


func _record_failed_attempt() -> int:
	return ChoreRuntimeScript.record_failed_attempt(_assist, FarmState.CHORE_BRUSHING)


func _record_progress() -> void:
	ChoreRuntimeScript.record_progress(_assist, FarmState.CHORE_BRUSHING, "brushing_hint")


func _save_assist_memory() -> void:
	ChoreRuntimeScript.save_assist_memory(_assist, FarmState.CHORE_BRUSHING)


func _brush_next_available_animal() -> bool:
	if _brush_animation_active or FarmState.is_chore_completed(FarmState.CHORE_BRUSHING):
		return false
	var card := _get_next_brush_card()
	return card != null and _brush_card(card, true)


func _get_next_brush_card() -> FarmAnimalCard:
	for card_path in animal_card_paths:
		var card := get_node_or_null(card_path) as FarmAnimalCard
		if card == null or not card.visible or card.is_completed():
			continue
		if card.animal_id == "duck" and not FarmState.has_unlock("duck_pond"):
			continue
		return card
	return null


func _is_event_near_next_card(event: InputEvent) -> bool:
	var card := _get_next_brush_card()
	return card != null and ChoreCompletionFlowScript.is_event_near_node(event, card, assist_stage_two_radius)


func _show_assist_hint(strong: bool) -> void:
	var card := _get_next_brush_card()
	if card != null:
		ChoreRuntimeScript.show_assist_hint(card, strong, tr("Tap this animal to brush it."), "brushing_hint_%s_%s" % [card.animal_id, "strong" if strong else "gentle"])
	elif _brush_visual != null:
		ChoreRuntimeScript.show_assist_hint(_brush_visual, strong, tr("Tap an animal and the brush will help."), "brushing_hint_tool_strong" if strong else "brushing_hint_tool_gentle")


func _send_brush_to(card: FarmAnimalCard, finished: Callable = Callable()) -> void:
	if _brush_visual != null:
		FarmFeedback.pulse(_brush_visual, 1.08, 0.1)
	if _brush_visual == null or brush_token_texture == null:
		_brush_animation_active = false
		if finished.is_valid():
			finished.call()
		return

	var token := FarmFeedback.make_feedback_sprite(
		self,
		brush_token_texture,
		FarmFeedback.get_visual_global_scale(_brush_visual, Vector2(0.42, 0.42)),
		20
	)
	token.global_position = _brush_visual.global_position
	var target_position := card.global_position + Vector2(0, -42)
	if card.has_method("get_animal_global_position"):
		target_position = card.get_animal_global_position() + Vector2(0, -30)
	var tween := FarmFeedback.move_node_to(token, target_position, 0.34)
	tween.tween_property(token, "rotation_degrees", 16.0, 0.08)
	tween.tween_property(token, "rotation_degrees", -16.0, 0.08)
	tween.tween_property(token, "rotation_degrees", 0.0, 0.08)
	tween.tween_property(token, "modulate:a", 0.0, 0.12)
	tween.finished.connect(func() -> void:
		if is_instance_valid(token):
			token.queue_free()
		_brush_animation_active = false
		if finished.is_valid() and is_instance_valid(self):
			finished.call()
	)


func _refresh_ui() -> void:
	if _progress_label != null:
		FarmFeedback.show_counter_label(_progress_label, FarmState.get_brushed_animals().size(), FarmState.get_brushing_goal())
	for card_path in animal_card_paths:
		var card := get_node_or_null(card_path) as FarmAnimalCard
		if card == null:
			continue
		card.set_selected(false)


func _show_completion(play_sound: bool) -> void:
	if _completion_active:
		return
	_completion_active = true
	var feedback := FarmState.get_chore_completion_feedback(FarmState.CHORE_BRUSHING)
	var message := str(feedback.get("text", _get_completion_message()))
	var voice_key := str(feedback.get("voice_key", "brushing_complete_0"))
	ChoreCompletionFlowScript.show_completion_feedback(
		self,
		_completion_panel,
		_completion_label,
		_back_button,
		message,
		play_sound,
		completion_sound,
		voice_key,
		Vector2(960.0, 560.0),
		22,
		farmyard_scene_path,
		post_completion_return_delay,
		post_completion_return_lock
	)


func _return_to_farmyard() -> void:
	ChoreCompletionFlowScript.try_return_to_farmyard(self, farmyard_scene_path)


func _get_completion_message() -> String:
	return FarmState.get_chore_completion_message(FarmState.CHORE_BRUSHING)
