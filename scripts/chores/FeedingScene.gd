extends Node2D

const ChoreAssistScript := preload("res://scripts/core/ChoreAssist.gd")
const ChoreCompletionFlowScript := preload("res://scripts/core/ChoreCompletionFlow.gd")
const ChoreRuntimeScript := preload("res://scripts/core/ChoreRuntime.gd")
const ASSIST_STAGE_STRONG_HINT := 2
const ASSIST_STAGE_ACTION := 3

@export_file("*.tscn") var farmyard_scene_path := "res://scenes/FarmyardScene.tscn"
@export var feed_bag_pile: NodePath
@export var feed_bag_texture: Texture2D
@export var feed_pour_texture: Texture2D
@export var progress_label: NodePath
@export var feedback_label: NodePath
@export var completion_panel: NodePath
@export var completion_label: NodePath
@export var back_button: NodePath
@export var animal_card_paths: Array[NodePath] = []
@export var feed_sound: AudioStream
@export var completion_sound: AudioStream
@export var direct_tap_margin := 22.0
@export var assist_stage_two_radius := 190.0
@export var post_completion_return_delay := 7.0
@export var post_completion_return_lock := 1.0
@export var feed_bag_pop_duration := 0.28
@export var feed_bag_travel_duration := 0.9
@export var feed_pour_duration := 0.48

var _assist: RefCounted = ChoreAssistScript.new()
var _completion_active := false
@onready var _feed_bag_pile: Node2D = get_node_or_null(feed_bag_pile) as Node2D
@onready var _progress_label: Label = get_node_or_null(progress_label) as Label
@onready var _feedback_label: Label = get_node_or_null(feedback_label) as Label
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
	ChoreRuntimeScript.configure_assist(_assist, FarmState.CHORE_FEEDING)
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
		var fed_today := FarmState.is_animal_fed(card.animal_id)
		card.set_completed(fed_today, "Fed and happy!")
		if card.has_method("set_feed_visible"):
			card.call("set_feed_visible", fed_today, false)
		if fed_today and card.has_method("move_to_trough_and_eat"):
			card.call("move_to_trough_and_eat", false)

		if card.animal_id == "goat" and not FarmState.has_unlock("goat_friend"):
			card.visible = false
			card.set_card_enabled(false)

	_refresh_ui()
	if FarmState.is_chore_completed(FarmState.CHORE_FEEDING):
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
	if _completion_active or FarmState.is_chore_completed(FarmState.CHORE_FEEDING):
		return
	if bool(_assist.call("should_show_hint")):
		_show_assist_hint(int(_assist.call("get_stage")) >= ASSIST_STAGE_STRONG_HINT)


func _input(event: InputEvent) -> void:
	if _completion_active:
		ChoreCompletionFlowScript.handle_completion_return_input(self, event, farmyard_scene_path)


func _unhandled_input(event: InputEvent) -> void:
	if _completion_active or FarmState.is_chore_completed(FarmState.CHORE_FEEDING):
		return
	if not ChoreCompletionFlowScript.is_tap_event(event):
		return

	if _handle_direct_tap(event):
		get_viewport().set_input_as_handled()
		return

	get_viewport().set_input_as_handled()
	_handle_failed_tap(event)


func _on_card_tapped(card: FarmAnimalCard) -> void:
	if _completion_active:
		return
	if _feed_card(card, false):
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


func _feed_card(card: FarmAnimalCard, assisted: bool = false) -> bool:
	if _completion_active:
		return false
	if card.animal_id == "goat" and not FarmState.has_unlock("goat_friend"):
		return false
	if not FarmState.feed_animal(card.animal_id):
		if not assisted:
			FarmFeedback.flash_label(_feedback_label, tr("%s already had a snack.") % card.animal_name, Color("fff3c8"), 0.7)
		return false

	var completed_after_feed := FarmState.is_chore_completed(FarmState.CHORE_FEEDING)
	_send_feed_to(card, Callable(self, "_show_completion").bind(true) if completed_after_feed else Callable())
	card.cheer(tr("Yummy feed!"))
	_record_progress()
	FarmFeedback.play_one_shot(self, feed_sound, -4.0)
	FarmFeedback.flash_label(_feedback_label, tr("%s got a tasty snack.") % card.animal_name, Color("fff5b3"), 0.8)
	_refresh_ui()

	return true


func _handle_failed_tap(event) -> void:
	var stage_before := int(_assist.call("get_stage"))
	if event is InputEvent and stage_before >= ASSIST_STAGE_STRONG_HINT and _is_event_near_next_card(event):
		_feed_next_available_animal()
		return

	var stage := _record_failed_attempt()
	if event is InputEvent and stage >= ASSIST_STAGE_STRONG_HINT and _is_event_near_next_card(event):
		_feed_next_available_animal()
		return

	if stage >= ASSIST_STAGE_ACTION and bool(_assist.call("can_perform_assist_action")):
		ChoreRuntimeScript.mark_assist_action_performed(_assist, FarmState.CHORE_FEEDING)
		_feed_next_available_animal()
		return

	if bool(_assist.call("should_show_hint")):
		_show_assist_hint(stage >= ASSIST_STAGE_STRONG_HINT)


func _record_failed_attempt() -> int:
	return ChoreRuntimeScript.record_failed_attempt(_assist, FarmState.CHORE_FEEDING)


func _record_progress() -> void:
	ChoreRuntimeScript.record_progress(_assist, FarmState.CHORE_FEEDING, "feeding_hint")


func _save_assist_memory() -> void:
	ChoreRuntimeScript.save_assist_memory(_assist, FarmState.CHORE_FEEDING)


func _feed_next_available_animal() -> bool:
	if FarmState.is_chore_completed(FarmState.CHORE_FEEDING):
		return false
	var card := _get_next_feed_card()
	return card != null and _feed_card(card, true)


func _get_next_feed_card() -> FarmAnimalCard:
	for card_path in animal_card_paths:
		var card := get_node_or_null(card_path) as FarmAnimalCard
		if card == null or not card.visible:
			continue
		if card.animal_id == "goat" and not FarmState.has_unlock("goat_friend"):
			continue
		if FarmState.is_animal_fed(card.animal_id):
			continue
		return card
	return null


func _is_event_near_next_card(event: InputEvent) -> bool:
	var card := _get_next_feed_card()
	return card != null and ChoreCompletionFlowScript.is_event_near_node(event, card, assist_stage_two_radius)


func _show_assist_hint(strong: bool) -> void:
	var card := _get_next_feed_card()
	if card != null:
		ChoreRuntimeScript.show_assist_hint(card, strong, tr("Tap this animal to give it food."), "feeding_hint_%s_%s" % [card.animal_id, "strong" if strong else "gentle"])


func _send_feed_to(card: FarmAnimalCard, finished: Callable = Callable()) -> void:
	if _feed_bag_pile == null or feed_bag_texture == null:
		if finished.is_valid():
			finished.call()
		return

	var start_position := _get_feed_start_position()

	var bag := Sprite2D.new()
	bag.texture = feed_bag_texture
	bag.scale = Vector2(0.08, 0.08)
	bag.modulate = Color(1.0, 1.0, 1.0, 0.0)
	bag.rotation_degrees = -4.0
	bag.z_index = 50
	add_child(bag)
	bag.global_position = start_position + Vector2(-18.0, 16.0)

	var target_position := _get_feed_target_position(card)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(bag, "global_position", start_position + Vector2(-18.0, -56.0), feed_bag_pop_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(bag, "scale", Vector2(0.22, 0.22), feed_bag_pop_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(bag, "modulate", Color.WHITE, 0.08)
	tween.chain().tween_property(bag, "global_position", target_position + Vector2(-26.0, -78.0), feed_bag_travel_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(bag, "rotation_degrees", -10.0, feed_bag_travel_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_property(bag, "rotation_degrees", 58.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(Callable(self, "_show_feed_pour").bind(target_position))
	tween.chain().tween_interval(feed_pour_duration)
	tween.chain().tween_property(bag, "rotation_degrees", 4.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(bag, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.14)
	tween.parallel().tween_property(bag, "scale", Vector2(0.12, 0.12), 0.14)
	tween.chain().tween_callback(Callable(self, "_finish_feed_delivery").bind(bag, card, finished))


func _get_feed_start_position() -> Vector2:
	if _feed_bag_pile != null:
		return _feed_bag_pile.global_position
	return Vector2(960.0, 540.0)


func _get_feed_target_position(card: FarmAnimalCard) -> Vector2:
	if card != null and card.has_method("get_feed_target_global_position"):
		return card.call("get_feed_target_global_position")
	return card.global_position


func _finish_feed_delivery(token: Node, card: FarmAnimalCard, finished: Callable = Callable()) -> void:
	if is_instance_valid(token):
		token.queue_free()
	if is_instance_valid(card) and card.has_method("set_feed_visible"):
		card.call("set_feed_visible", true, true)
	if is_instance_valid(card) and card.has_method("move_to_trough_and_eat"):
		card.call("move_to_trough_and_eat", true)
	if finished.is_valid() and is_instance_valid(self):
		finished.call()


func _show_feed_pour(target_position: Vector2) -> void:
	if feed_pour_texture == null:
		return
	var pour := Sprite2D.new()
	pour.texture = feed_pour_texture
	pour.scale = Vector2(0.32, 0.32)
	pour.modulate = Color(1.0, 1.0, 1.0, 0.0)
	pour.rotation_degrees = -8.0
	pour.z_index = 49
	add_child(pour)
	pour.global_position = target_position + Vector2(-24.0, -54.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(pour, "modulate", Color.WHITE, 0.08)
	tween.tween_property(pour, "global_position", target_position, feed_pour_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_property(pour, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.1)
	tween.chain().tween_callback(Callable(pour, "queue_free"))


func _refresh_ui() -> void:
	if _progress_label != null:
		FarmFeedback.show_counter_label(_progress_label, FarmState.get_fed_animals().size(), FarmState.get_feeding_goal())


func _show_completion(play_sound: bool) -> void:
	if _completion_active:
		return
	_completion_active = true
	var feedback := FarmState.get_chore_completion_feedback(FarmState.CHORE_FEEDING)
	var message := str(feedback.get("text", _get_completion_message()))
	var voice_key := str(feedback.get("voice_key", "feeding_complete_0"))
	ChoreCompletionFlowScript.show_completion_feedback(
		self,
		_completion_panel,
		_completion_label,
		_back_button,
		message,
		play_sound,
		completion_sound,
		voice_key,
		Vector2(960.0, 580.0),
		22,
		farmyard_scene_path,
		post_completion_return_delay,
		post_completion_return_lock
	)


func _return_to_farmyard() -> void:
	ChoreCompletionFlowScript.try_return_to_farmyard(self, farmyard_scene_path)


func _get_completion_message() -> String:
	return FarmState.get_chore_completion_message(FarmState.CHORE_FEEDING)
