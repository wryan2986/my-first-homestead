extends Node2D

const ChoreAssistScript := preload("res://scripts/core/ChoreAssist.gd")
const ChoreCompletionFlowScript := preload("res://scripts/core/ChoreCompletionFlow.gd")
const ChoreRuntimeScript := preload("res://scripts/core/ChoreRuntime.gd")
const ASSIST_STAGE_STRONG_HINT := 2
const ASSIST_STAGE_ACTION := 3

@export_file("*.tscn") var farmyard_scene_path := "res://scenes/FarmyardScene.tscn"
@export var basket_node: NodePath
@export var basket_fill_visual: NodePath
@export var egg_collection_target: NodePath
@export var progress_label: NodePath
@export var season_label: NodePath
@export var feedback_label: NodePath
@export var completion_panel: NodePath
@export var completion_label: NodePath
@export var back_button: NodePath
@export var egg_paths: Array[NodePath] = []
@export var chicken_paths: Array[NodePath] = []
@export var note_effect_texture: Texture2D
@export var egg_note_sounds: Array[AudioStream] = []
@export var egg_note_pitch_scales: Array[float] = []
@export var egg_note_colors: Array[Color] = []
@export var egg_collect_sound: AudioStream
@export var chicken_sound: AudioStream
@export var chicken_sounds: Array[AudioStream] = []
@export var completion_sound: AudioStream
@export var note_spawn_offset := Vector2(0.0, -88.0)
@export var direct_tap_margin := 20.0
@export var assist_stage_two_radius := 170.0
@export var post_completion_return_delay := 7.0
@export var post_completion_return_lock := 1.0
@export var min_random_cluck_delay_seconds := 18.0
@export var max_random_cluck_delay_seconds := 35.0
@export_range(0.0, 1.0, 0.01) var random_cluck_chance := 0.2

var _assist: RefCounted = ChoreAssistScript.new()
var _completion_active := false
var _basket_arrived_count := 0
var _rng := RandomNumberGenerator.new()
var _next_random_cluck_msec := 0
@onready var _basket_node: Node2D = get_node_or_null(basket_node) as Node2D
@onready var _basket_fill_visual: Node = get_node_or_null(basket_fill_visual)
@onready var _egg_collection_target: Node2D = get_node_or_null(egg_collection_target) as Node2D
@onready var _progress_label: Label = get_node_or_null(progress_label) as Label
@onready var _season_label: Label = get_node_or_null(season_label) as Label
@onready var _feedback_label: Label = get_node_or_null(feedback_label) as Label
@onready var _completion_panel: Control = get_node_or_null(completion_panel) as Control
@onready var _completion_label: Label = get_node_or_null(completion_label) as Label
@onready var _back_button: Button = get_node_or_null(back_button) as Button


func _ready() -> void:
	if _is_scene_navigator_cache_prepare():
		return
	_completion_active = false
	_rng.seed = int(Time.get_ticks_usec()) + get_instance_id()
	MusicManager.play_chore_music()
	if GameSettings.has_signal("locale_changed") and not GameSettings.locale_changed.is_connected(_on_locale_changed):
		GameSettings.locale_changed.connect(_on_locale_changed)
	ChoreRuntimeScript.configure_assist(_assist, FarmState.CHORE_EGGS)
	if _back_button != null and not _back_button.pressed.is_connected(_return_to_farmyard):
		_back_button.pressed.connect(_return_to_farmyard)
	if _completion_panel != null:
		_completion_panel.visible = false
	ChoreCompletionFlowScript.prepare_chore_scene(self, _back_button)
	FarmFeedback.hide_play_scene_text(self)

	for egg_path in egg_paths:
		var egg := get_node_or_null(egg_path) as EggCollectible
		if egg == null:
			continue
		egg.configure(FarmState.is_egg_collected(egg.egg_id))
		if not egg.collected.is_connected(_on_egg_collected):
			egg.collected.connect(_on_egg_collected)
		if not egg.collection_animation_finished.is_connected(_on_egg_arrived_at_basket):
			egg.collection_animation_finished.connect(_on_egg_arrived_at_basket)

	for chicken_path in chicken_paths:
		var chicken := get_node_or_null(chicken_path) as BouncyCritter
		if chicken == null:
			continue
		if not chicken.tapped.is_connected(_on_chicken_tapped):
			chicken.tapped.connect(_on_chicken_tapped)
	_configure_chicken_noise()

	_basket_arrived_count = FarmState.get_collected_egg_count()
	_refresh_ui(true)
	_schedule_next_random_cluck()

	if FarmState.is_chore_completed(FarmState.CHORE_EGGS):
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
	if _completion_active or FarmState.is_chore_completed(FarmState.CHORE_EGGS):
		return
	if bool(_assist.call("should_show_hint")):
		_show_assist_hint(int(_assist.call("get_stage")) >= ASSIST_STAGE_STRONG_HINT)
	_try_random_chicken_cluck()


func _input(event: InputEvent) -> void:
	if _completion_active:
		ChoreCompletionFlowScript.handle_completion_return_input(self, event, farmyard_scene_path)


func _unhandled_input(event: InputEvent) -> void:
	if _completion_active or FarmState.is_chore_completed(FarmState.CHORE_EGGS):
		return
	if not ChoreCompletionFlowScript.is_tap_event(event):
		return

	if _handle_direct_tap(event):
		get_viewport().set_input_as_handled()
		return

	get_viewport().set_input_as_handled()
	_handle_failed_tap(event)


func _on_chicken_tapped(chicken: BouncyCritter) -> void:
	if _completion_active:
		return
	chicken.hop()
	FarmFeedback.pulse(chicken, 1.08, 0.1)
	if chicken.cluck_sounds.is_empty():
		FarmFeedback.play_one_shot(self, _pick_chicken_sound(), -6.0)


func _on_egg_collected(egg: EggCollectible) -> void:
	if _completion_active:
		return
	_collect_egg(egg)


func _handle_direct_tap(event: InputEvent) -> bool:
	for egg_path in egg_paths:
		var egg := get_node_or_null(egg_path) as EggCollectible
		if egg == null or not egg.visible or FarmState.is_egg_collected(egg.egg_id):
			continue
		if ChoreCompletionFlowScript.is_event_inside_area(event, egg, self, direct_tap_margin):
			_collect_egg(egg)
			return true

	for chicken_path in chicken_paths:
		var chicken := get_node_or_null(chicken_path) as BouncyCritter
		if chicken == null or not chicken.visible:
			continue
		if ChoreCompletionFlowScript.is_event_inside_area(event, chicken, self, direct_tap_margin):
			_on_chicken_tapped(chicken)
			return true
	return false


func _collect_egg(egg: EggCollectible) -> bool:
	if not FarmState.collect_egg(egg.egg_id):
		return false

	_record_progress()

	var egg_note_index := _get_egg_note_index(egg)
	var egg_origin := egg.global_position
	var target := _get_egg_collection_target_position(egg)
	var completed_after_collection := FarmState.is_chore_completed(FarmState.CHORE_EGGS)
	if completed_after_collection:
		egg.collection_animation_finished.connect(_on_completion_egg_collection_finished, CONNECT_ONE_SHOT)
	egg.animate_collection(target)
	_play_egg_note(egg_origin, egg_note_index)
	FarmFeedback.flash_label(_feedback_label, tr("Egg in the basket!"), Color("ffe9a1"), 0.8)
	_refresh_ui()

	return true


func _on_egg_arrived_at_basket(_egg: EggCollectible) -> void:
	_basket_arrived_count = mini(_basket_arrived_count + 1, FarmState.get_collected_egg_count())
	_sync_basket_fill(true)
	if _basket_node != null:
		FarmFeedback.pulse(_basket_node, 1.06, 0.12)


func _on_completion_egg_collection_finished(_egg: EggCollectible) -> void:
	_show_completion(true)


func _get_egg_collection_target_position(egg: EggCollectible) -> Vector2:
	if _egg_collection_target != null:
		return _egg_collection_target.global_position
	if _basket_node != null:
		return _basket_node.global_position + Vector2(0.0, -28.0)
	return egg.global_position


func _play_egg_note(origin: Vector2, egg_note_index: int) -> void:
	var note_stream := _get_egg_note_stream(egg_note_index)
	var pitch_scale := _get_egg_note_pitch_scale(egg_note_index)
	var note_color := _get_egg_note_color(egg_note_index)
	FarmFeedback.spawn_note_shape(self, note_effect_texture, origin + note_spawn_offset, egg_note_index, note_color, Vector2(1.52, 1.52), Vector2(0.0, -72.0), 30, 0.8)
	if note_stream != null:
		FarmFeedback.play_one_shot(self, note_stream, -4.0, pitch_scale)
	elif egg_collect_sound != null:
		FarmFeedback.play_one_shot(self, egg_collect_sound, -3.0)


func _get_egg_note_index(egg: EggCollectible) -> int:
	for index in egg_paths.size():
		var egg_node := get_node_or_null(egg_paths[index]) as EggCollectible
		if egg_node == egg:
			return index
	return 0


func _get_egg_note_stream(egg_note_index: int) -> AudioStream:
	if egg_note_index >= 0 and egg_note_index < egg_note_sounds.size():
		return egg_note_sounds[egg_note_index]
	return egg_collect_sound


func _get_egg_note_pitch_scale(egg_note_index: int) -> float:
	if egg_note_index >= 0 and egg_note_index < egg_note_pitch_scales.size():
		return maxf(0.01, egg_note_pitch_scales[egg_note_index])
	return 1.0


func _get_egg_note_color(egg_note_index: int) -> Color:
	if egg_note_index >= 0 and egg_note_index < egg_note_colors.size():
		return egg_note_colors[egg_note_index]
	return Color.WHITE


func _handle_failed_tap(event) -> void:
	var stage_before := int(_assist.call("get_stage"))
	if event is InputEvent and stage_before >= ASSIST_STAGE_STRONG_HINT and _is_event_near_next_egg(event):
		_collect_next_available_egg()
		return

	var stage := _record_failed_attempt()
	if event is InputEvent and stage >= ASSIST_STAGE_STRONG_HINT and _is_event_near_next_egg(event):
		_collect_next_available_egg()
		return

	if stage >= ASSIST_STAGE_ACTION and bool(_assist.call("can_perform_assist_action")):
		ChoreRuntimeScript.mark_assist_action_performed(_assist, FarmState.CHORE_EGGS)
		_collect_next_available_egg()
		return

	if bool(_assist.call("should_show_hint")):
		_show_assist_hint(stage >= ASSIST_STAGE_STRONG_HINT)


func _record_failed_attempt() -> int:
	return ChoreRuntimeScript.record_failed_attempt(_assist, FarmState.CHORE_EGGS)


func _record_progress() -> void:
	ChoreRuntimeScript.record_progress(_assist, FarmState.CHORE_EGGS, "eggs_hint")


func _save_assist_memory() -> void:
	ChoreRuntimeScript.save_assist_memory(_assist, FarmState.CHORE_EGGS)


func _collect_next_available_egg() -> bool:
	if FarmState.is_chore_completed(FarmState.CHORE_EGGS):
		return false
	for egg_path in egg_paths:
		var egg := get_node_or_null(egg_path) as EggCollectible
		if egg == null or not egg.visible or FarmState.is_egg_collected(egg.egg_id):
			continue
		return _collect_egg(egg)
	return false


func _is_event_near_next_egg(event: InputEvent) -> bool:
	var egg := _get_next_available_egg()
	return egg != null and ChoreCompletionFlowScript.is_event_near_node(event, egg, assist_stage_two_radius)


func _get_next_available_egg() -> EggCollectible:
	for egg_path in egg_paths:
		var egg := get_node_or_null(egg_path) as EggCollectible
		if egg != null and egg.visible and not FarmState.is_egg_collected(egg.egg_id):
			return egg
	return null


func _show_assist_hint(strong: bool) -> void:
	var egg := _get_next_available_egg()
	if egg != null:
		ChoreRuntimeScript.show_assist_hint(egg, strong, tr("Tap the egg in the nest."), "eggs_hint_strong" if strong else "eggs_hint_gentle")
	elif _basket_node != null:
		ChoreRuntimeScript.show_assist_hint(_basket_node, strong, tr("The eggs go in the basket."), "eggs_hint_basket_strong" if strong else "eggs_hint_basket_gentle")


func _try_random_chicken_cluck() -> void:
	if _pick_chicken_sound() == null or Time.get_ticks_msec() < _next_random_cluck_msec:
		return
	_schedule_next_random_cluck()
	if _rng.randf() > clampf(random_cluck_chance, 0.0, 1.0):
		return
	var chickens := _get_visible_chickens()
	if chickens.is_empty():
		return
	var chicken := chickens[_rng.randi_range(0, chickens.size() - 1)]
	FarmFeedback.pulse(chicken, 1.04, 0.12)
	FarmFeedback.play_one_shot(self, _pick_chicken_sound(), -8.0)


func _schedule_next_random_cluck() -> void:
	var min_delay := maxf(1.0, minf(min_random_cluck_delay_seconds, max_random_cluck_delay_seconds))
	var max_delay := maxf(min_delay, maxf(min_random_cluck_delay_seconds, max_random_cluck_delay_seconds))
	_next_random_cluck_msec = Time.get_ticks_msec() + int(_rng.randf_range(min_delay, max_delay) * 1000.0)


func _get_visible_chickens() -> Array[BouncyCritter]:
	var chickens: Array[BouncyCritter] = []
	for child in get_children():
		var chicken := child as BouncyCritter
		if chicken != null and chicken.visible:
			chickens.append(chicken)
	return chickens


func _configure_chicken_noise() -> void:
	for child in get_children():
		var chicken := child as BouncyCritter
		if chicken != null:
			chicken.random_clucks_enabled = false
			if not chicken_sounds.is_empty():
				chicken.cluck_sounds = chicken_sounds.duplicate()


func _pick_chicken_sound() -> AudioStream:
	var valid_sounds: Array[AudioStream] = []
	for sound in chicken_sounds:
		if sound != null:
			valid_sounds.append(sound)
	if valid_sounds.is_empty():
		return chicken_sound
	return valid_sounds[_rng.randi_range(0, valid_sounds.size() - 1)]


func _refresh_ui(sync_basket := false) -> void:
	var collected := FarmState.get_collected_egg_count()
	if _progress_label != null:
		FarmFeedback.show_counter_label(_progress_label, collected, FarmState.EGG_GOAL)
	if _season_label != null:
		FarmFeedback.hide_label(_season_label)
	if sync_basket:
		_sync_basket_fill(false)


func _sync_basket_fill(animate_new: bool) -> void:
	if _basket_fill_visual != null and _basket_fill_visual.has_method("set_collected_count"):
		_basket_fill_visual.set_collected_count(_basket_arrived_count, FarmState.EGG_GOAL, animate_new)


func _on_locale_changed(_locale: String) -> void:
	_refresh_ui()


func _show_completion(play_sound: bool) -> void:
	if _completion_active:
		return
	_completion_active = true
	var feedback := FarmState.get_chore_completion_feedback(FarmState.CHORE_EGGS)
	var message := str(feedback.get("text", _get_completion_message()))
	var voice_key := str(feedback.get("voice_key", "eggs_complete_0"))
	var origin := _basket_node.global_position if _basket_node != null else Vector2(960.0, 540.0)
	ChoreCompletionFlowScript.show_completion_feedback(
		self,
		_completion_panel,
		_completion_label,
		_back_button,
		message,
		play_sound,
		completion_sound,
		voice_key,
		origin,
		24,
		farmyard_scene_path,
		post_completion_return_delay,
		post_completion_return_lock
	)


func _return_to_farmyard() -> void:
	ChoreCompletionFlowScript.try_return_to_farmyard(self, farmyard_scene_path)


func _get_completion_message() -> String:
	return FarmState.get_chore_completion_message(FarmState.CHORE_EGGS)
