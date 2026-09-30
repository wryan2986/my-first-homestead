extends Node2D

const ChoreAssistScript := preload("res://scripts/core/ChoreAssist.gd")
const ChoreCompletionFlowScript := preload("res://scripts/core/ChoreCompletionFlow.gd")
const ChoreRuntimeScript := preload("res://scripts/core/ChoreRuntime.gd")
const SceneEntranceMotionScript := preload("res://scripts/core/SceneEntranceMotion.gd")

const ASSIST_STAGE_STRONG_HINT := 2
const ASSIST_STAGE_ACTION := 3

enum ScenePhase {
	INTRO,
	PETTING,
	MILKING,
	COMPLETE,
}

@export_file("*.tscn") var farmyard_scene_path := "res://scenes/FarmyardScene.tscn"
@export var cow_rig: NodePath
@export var pet_area: NodePath
@export var udder_area: NodePath
@export var cow_visual: NodePath
@export var bucket_node: NodePath
@export var bucket_fill: NodePath
@export var milk_stream_source: NodePath
@export var milk_stream_target: NodePath
@export var pet_glow: NodePath
@export var udder_glow: NodePath
@export var progress_label: NodePath
@export var feedback_label: NodePath
@export var completion_panel: NodePath
@export var completion_label: NodePath
@export var back_button: NodePath
@export var cow_idle_texture: Texture2D
@export var cow_blinking_texture: Texture2D
@export var cow_happy_texture: Texture2D
@export var cow_celebrating_texture: Texture2D
@export var milk_sound: AudioStream
@export var cow_moo_sound: AudioStream
@export var completion_sound: AudioStream
@export var direct_tap_margin := 24.0
@export var assist_stage_two_radius := 230.0
@export var pet_taps_required := 1
@export var cow_intro_start_offset := Vector2(860.0, 130.0)
@export var cow_intro_approach_one_offset := Vector2(620.0, 122.0)
@export var cow_intro_approach_two_offset := Vector2(388.0, 110.0)
@export var cow_intro_step_offset := Vector2(182.0, 54.0)
@export var cow_intro_settle_offset := Vector2(0.0, -8.0)
@export var cow_intro_start_duration := 0.82
@export var cow_intro_approach_one_duration := 0.68
@export var cow_intro_approach_two_duration := 0.56
@export var cow_intro_step_duration := 0.34
@export var cow_settle_duration := 0.18
@export var milk_stream_color := Color("fbfdff")
@export var milk_stream_width := 10.0
@export var milk_stream_duration := 0.28
@export var post_completion_return_delay := 7.0
@export var post_completion_return_lock := 1.0
@export var milk_phase_input_lock_seconds := 0.45

var _assist: RefCounted = ChoreAssistScript.new()
var _completion_active := false
var _intro_active := true
var _phase := ScenePhase.INTRO
var _pet_tap_count := 0
var _last_milk_tap_msec := -1000
var _milk_input_locked_until_msec := 0
var _cow_rig_rest_position := Vector2.ZERO
var _cow_rig_intro_start_position := Vector2.ZERO
var _cow_rig_intro_approach_one_position := Vector2.ZERO
var _cow_rig_intro_approach_two_position := Vector2.ZERO
var _cow_rig_intro_step_position := Vector2.ZERO
var _cache_prepared := false

@onready var _cow_rig: Node2D = get_node_or_null(cow_rig) as Node2D
@onready var _pet_area: Area2D = get_node_or_null(pet_area) as Area2D
@onready var _udder_area: Area2D = get_node_or_null(udder_area) as Area2D
@onready var _cow_visual: Sprite2D = get_node_or_null(cow_visual) as Sprite2D
@onready var _bucket_node: Node2D = get_node_or_null(bucket_node) as Node2D
@onready var _bucket_fill: Node = get_node_or_null(bucket_fill)
@onready var _milk_stream_source: Node2D = get_node_or_null(milk_stream_source) as Node2D
@onready var _milk_stream_target: Node2D = get_node_or_null(milk_stream_target) as Node2D
@onready var _pet_glow_item: CanvasItem = get_node_or_null(pet_glow) as CanvasItem
@onready var _udder_glow_item: CanvasItem = get_node_or_null(udder_glow) as CanvasItem
@onready var _progress_label: Label = get_node_or_null(progress_label) as Label
@onready var _feedback_label: Label = get_node_or_null(feedback_label) as Label
@onready var _completion_panel: Control = get_node_or_null(completion_panel) as Control
@onready var _completion_label: Label = get_node_or_null(completion_label) as Label
@onready var _back_button: Button = get_node_or_null(back_button) as Button


func _ready() -> void:
	if _is_scene_navigator_cache_prepare():
		return
	_activate_scene()


func prepare_for_cached_scene() -> void:
	_prepare_static_scene()


func activate_from_cache() -> void:
	_activate_scene()


func deactivate_for_cache_or_free() -> void:
	pass


func is_cache_prepared() -> bool:
	return _cache_prepared


func _activate_scene() -> void:
	var activation_started_msec := Time.get_ticks_msec()
	_prepare_static_scene()
	_completion_active = false
	_intro_active = true
	_pet_tap_count = 0
	_last_milk_tap_msec = -1000
	_milk_input_locked_until_msec = 0
	MusicManager.play_chore_music()
	ChoreRuntimeScript.configure_assist(_assist, FarmState.CHORE_MILKING)
	if _completion_panel != null:
		_completion_panel.visible = false
	ChoreCompletionFlowScript.prepare_chore_scene(self, _back_button)
	FarmFeedback.hide_play_scene_text(self)

	if FarmState.is_chore_completed(FarmState.CHORE_MILKING):
		_prepare_scene_for_completion()
		_refresh_ui()
		_show_completion(false)
	else:
		_prepare_scene_for_intro()
		_refresh_ui()
		call_deferred("_start_intro_sequence")
	if OS.is_debug_build():
		print("[SceneTiming] milking activation_setup_ms=%d cache_prepared=%s" % [
			Time.get_ticks_msec() - activation_started_msec,
			_cache_prepared,
		])


func _prepare_static_scene() -> void:
	if _cache_prepared:
		return
	var prepare_started_msec := Time.get_ticks_msec()
	if GameSettings.has_signal("locale_changed") and not GameSettings.locale_changed.is_connected(_refresh_ui):
		GameSettings.locale_changed.connect(_refresh_ui)
	if _back_button != null and not _back_button.pressed.is_connected(_return_to_farmyard):
		_back_button.pressed.connect(_return_to_farmyard)
	if _completion_panel != null:
		_completion_panel.visible = false
	ChoreCompletionFlowScript.prepare_chore_scene(self, _back_button)
	FarmFeedback.hide_play_scene_text(self)
	_cache_intro_positions()
	_prepare_scene_for_intro()
	_cache_prepared = true
	if OS.is_debug_build():
		print("[SceneTiming] milking cache_prepare_ms=%d" % (
			Time.get_ticks_msec() - prepare_started_msec
		))


func _is_scene_navigator_cache_prepare() -> bool:
	return has_meta("_scene_navigator_cache_prepare")


func _cache_intro_positions() -> void:
	if _cow_rig != null:
		_cow_rig_rest_position = _cow_rig.position
		_cow_rig_intro_start_position = _cow_rig_rest_position + cow_intro_start_offset
		_cow_rig_intro_approach_one_position = _cow_rig_rest_position + cow_intro_approach_one_offset
		_cow_rig_intro_approach_two_position = _cow_rig_rest_position + cow_intro_approach_two_offset
		_cow_rig_intro_step_position = _cow_rig_rest_position + cow_intro_step_offset
	elif _cow_visual != null:
		_cow_rig_rest_position = _cow_visual.position
		_cow_rig_intro_start_position = _cow_rig_rest_position + cow_intro_start_offset
		_cow_rig_intro_approach_one_position = _cow_rig_rest_position + cow_intro_approach_one_offset
		_cow_rig_intro_approach_two_position = _cow_rig_rest_position + cow_intro_approach_two_offset
		_cow_rig_intro_step_position = _cow_rig_rest_position + cow_intro_step_offset


func _prepare_scene_for_intro() -> void:
	_set_phase(ScenePhase.INTRO)
	if _cow_rig != null:
		_cow_rig.position = _cow_rig_intro_start_position
	_set_cow_texture(cow_idle_texture if cow_idle_texture != null else cow_happy_texture)
	_set_area_pickable(_pet_area, false)
	_set_area_pickable(_udder_area, false)
	_set_item_visible(_pet_glow_item, false)
	_set_item_visible(_udder_glow_item, false)


func _prepare_scene_for_completion() -> void:
	_set_phase(ScenePhase.COMPLETE)
	if _cow_rig != null:
		_cow_rig.position = _cow_rig_rest_position
	_set_cow_texture(cow_celebrating_texture if cow_celebrating_texture != null else cow_happy_texture)
	_set_area_pickable(_pet_area, false)
	_set_area_pickable(_udder_area, false)
	_set_item_visible(_pet_glow_item, false)
	_set_item_visible(_udder_glow_item, false)


func _start_intro_sequence() -> void:
	if _completion_active or FarmState.is_chore_completed(FarmState.CHORE_MILKING):
		return
	if _cow_rig == null:
		_intro_active = false
		_set_phase(ScenePhase.PETTING)
		return
	_play_intro_motion()


func _play_intro_motion() -> void:
	var rig_positions: Array = [
		_cow_rig_intro_start_position,
		_cow_rig_intro_approach_one_position,
		_cow_rig_intro_approach_two_position,
		_cow_rig_intro_step_position,
		_cow_rig_rest_position,
		_cow_rig_rest_position + cow_intro_settle_offset,
		_cow_rig_rest_position,
	]
	var rig_durations: Array = [
		cow_intro_start_duration,
		cow_intro_approach_one_duration,
		cow_intro_approach_two_duration,
		cow_intro_step_duration,
		0.16,
		0.12,
	]
	var rig_rotations: Array = [0.0, 2.4, -1.6, 1.0, -0.5, 0.0, 0.0]
	var rig_scales: Array = [
		Vector2(0.86, 0.86),
		Vector2(0.9, 0.9),
		Vector2(0.93, 0.93),
		Vector2(0.97, 0.97),
		Vector2(1.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(1.0, 1.0),
	]
	var rig_tween = SceneEntranceMotionScript.tween_keyframes(_cow_rig, rig_positions, rig_durations, rig_rotations, rig_scales)

	if _cow_visual != null:
		_cow_visual.position = Vector2.ZERO
		_cow_visual.rotation_degrees = 0.0
		_cow_visual.scale = Vector2(0.88, 0.88)
		var cow_positions: Array = [
			Vector2.ZERO,
			Vector2(6.0, -1.0),
			Vector2(-5.0, 1.5),
			Vector2(4.0, -1.0),
			Vector2.ZERO,
			Vector2.ZERO,
			Vector2.ZERO,
		]
		var cow_durations: Array = [
			cow_intro_start_duration,
			cow_intro_approach_one_duration,
			cow_intro_approach_two_duration,
			cow_intro_step_duration,
			0.16,
			0.12,
		]
		var cow_rotations: Array = [0.0, -2.0, 1.6, -1.0, 0.0, 0.0, 0.0]
		var cow_scales: Array = [
			Vector2(0.86, 0.86),
			Vector2(0.88, 0.88),
			Vector2(0.89, 0.89),
			Vector2(0.905, 0.905),
			Vector2(0.88, 0.88),
			Vector2(0.88, 0.88),
			Vector2(0.88, 0.88),
		]
		SceneEntranceMotionScript.tween_keyframes(_cow_visual, cow_positions, cow_durations, cow_rotations, cow_scales)

	if rig_tween != null:
		rig_tween.finished.connect(func() -> void:
			if _completion_active or FarmState.is_chore_completed(FarmState.CHORE_MILKING):
				return
			_intro_active = false
			_set_cow_texture(cow_idle_texture if cow_idle_texture != null else cow_happy_texture)
			_set_phase(ScenePhase.PETTING)
			_show_phase_feedback(tr("Pat the cow to begin."), Color("fff2d8"), 0.95)
			FarmFeedback.play_one_shot(self, cow_moo_sound, -12.0, 0.92)
			_pulse_cow()
		)
	else:
		_intro_active = false
		_set_phase(ScenePhase.PETTING)


func _process(_delta: float) -> void:
	if _intro_active or _completion_active or FarmState.is_chore_completed(FarmState.CHORE_MILKING):
		return
	if bool(_assist.call("should_show_hint")):
		_show_assist_hint(int(_assist.call("get_stage")) >= ASSIST_STAGE_STRONG_HINT)


func _input(event: InputEvent) -> void:
	if _completion_active:
		ChoreCompletionFlowScript.handle_completion_return_input(self, event, farmyard_scene_path)


func _unhandled_input(event: InputEvent) -> void:
	if _intro_active or _completion_active or FarmState.is_chore_completed(FarmState.CHORE_MILKING):
		return
	if not ChoreCompletionFlowScript.is_tap_event(event):
		return

	if _handle_direct_tap(event):
		get_viewport().set_input_as_handled()
		return

	get_viewport().set_input_as_handled()
	_handle_failed_tap(event)


func _on_cow_pet_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _intro_active or _completion_active or FarmState.is_chore_completed(FarmState.CHORE_MILKING):
		return
	if _phase != ScenePhase.PETTING:
		return
	if not _is_primary_tap_event(event):
		return

	get_viewport().set_input_as_handled()
	_pet_cow()


func _on_udder_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _intro_active or _completion_active or FarmState.is_chore_completed(FarmState.CHORE_MILKING):
		return
	if _phase != ScenePhase.MILKING:
		return
	if not _is_primary_tap_event(event):
		return
	if _is_milk_input_locked():
		get_viewport().set_input_as_handled()
		return

	get_viewport().set_input_as_handled()
	_add_milk_from_tap()


func _handle_direct_tap(event: InputEvent) -> bool:
	match _phase:
		ScenePhase.PETTING:
			if ChoreCompletionFlowScript.is_event_inside_area(event, _pet_area, self, direct_tap_margin):
				_pet_cow()
				return true
		ScenePhase.MILKING:
			if not _is_milk_input_locked() and _is_event_on_udder(event):
				_add_milk_from_tap()
				return true
	return false


func _handle_failed_tap(event: InputEvent) -> void:
	match _phase:
		ScenePhase.PETTING:
			var stage_before := int(_assist.call("get_stage"))
			if stage_before >= ASSIST_STAGE_STRONG_HINT and _is_event_near_pet_target(event):
				_pet_cow()
				return

			var stage := _record_failed_attempt()
			if stage >= ASSIST_STAGE_STRONG_HINT and _is_event_near_pet_target(event):
				_pet_cow()
				return

			if stage >= ASSIST_STAGE_ACTION and bool(_assist.call("can_perform_assist_action")):
				ChoreRuntimeScript.mark_assist_action_performed(_assist, FarmState.CHORE_MILKING)
				_pet_cow()
				return

			if bool(_assist.call("should_show_hint")):
				_show_assist_hint(stage >= ASSIST_STAGE_STRONG_HINT)
		ScenePhase.MILKING:
			var milk_stage := _record_failed_attempt()
			if bool(_assist.call("should_show_hint")):
				_show_assist_hint(milk_stage >= ASSIST_STAGE_STRONG_HINT)


func _pet_cow() -> void:
	if _intro_active or _completion_active or _phase != ScenePhase.PETTING:
		return

	_pet_tap_count += 1
	_set_cow_texture(cow_blinking_texture if cow_blinking_texture != null else cow_happy_texture)
	_pulse_cow(1.06, 0.08)
	_nudge_cow(Vector2(0.0, -5.0), cow_settle_duration)
	FarmFeedback.flash(_cow_visual, Color("fff7d1"), 0.08)
	FarmFeedback.play_one_shot(self, cow_moo_sound, -11.5, 0.98)
	_show_phase_feedback("Nice pat!", Color("fff2d8"), 0.65)

	if _pet_tap_count >= pet_taps_required:
		_pet_tap_count = 0
		_lock_milk_input(milk_phase_input_lock_seconds)
		_set_phase(ScenePhase.MILKING)
		_set_cow_texture(cow_happy_texture if cow_happy_texture != null else cow_idle_texture)
		_pulse_cow(1.04, 0.1)
		_nudge_cow(Vector2(0.0, 4.0), cow_settle_duration)
		_show_phase_feedback("Now help with milking.", Color("fff2d8"), 0.9)
		_refresh_ui()
		return

	_refresh_ui()


func _add_milk_from_tap() -> void:
	if _intro_active or _completion_active or _phase != ScenePhase.MILKING or FarmState.is_chore_completed(FarmState.CHORE_MILKING):
		return
	if _is_milk_input_locked():
		return
	var now_msec := Time.get_ticks_msec()
	if now_msec - _last_milk_tap_msec < 140:
		return
	_last_milk_tap_msec = now_msec

	var milk_amount := FarmState.add_milk()
	_record_progress("milking_hint")
	_set_cow_texture(cow_blinking_texture if cow_blinking_texture != null else cow_happy_texture)
	_pulse_cow(1.03, 0.08)
	_nudge_cow(Vector2(0.0, -4.0), 0.06)
	FarmFeedback.flash(_cow_visual, Color("fff7d1"), 0.08)
	FarmFeedback.play_one_shot(self, milk_sound, -4.0)
	_show_phase_feedback("Squeeze! Milk into the bucket.", Color("fff2d8"), 0.6)
	_refresh_ui()
	var completed_after_milk := milk_amount >= FarmState.MILK_GOAL
	_play_milk_stream(Callable(self, "_show_completion").bind(true) if completed_after_milk else Callable())
	if _bucket_fill != null and _bucket_fill.has_method("play_splash"):
		_bucket_fill.call("play_splash")
	_set_cow_texture(cow_happy_texture if cow_happy_texture != null else cow_idle_texture)


func _record_failed_attempt() -> int:
	return ChoreRuntimeScript.record_failed_attempt(_assist, FarmState.CHORE_MILKING)


func _record_progress(hint_prefix: String) -> void:
	ChoreRuntimeScript.record_progress(_assist, FarmState.CHORE_MILKING, hint_prefix)


func _save_assist_memory() -> void:
	ChoreRuntimeScript.save_assist_memory(_assist, FarmState.CHORE_MILKING)


func _lock_milk_input(seconds: float) -> void:
	_milk_input_locked_until_msec = Time.get_ticks_msec() + int(maxf(0.0, seconds) * 1000.0)


func _is_milk_input_locked() -> bool:
	return Time.get_ticks_msec() < _milk_input_locked_until_msec


func _set_phase(new_phase: ScenePhase) -> void:
	_phase = new_phase
	_apply_phase_visuals()
	_refresh_ui()


func _apply_phase_visuals() -> void:
	var petting := _phase == ScenePhase.PETTING
	var milking := _phase == ScenePhase.MILKING
	_set_area_pickable(_pet_area, petting)
	_set_area_pickable(_udder_area, milking)
	_set_item_visible(_pet_glow_item, petting)
	_set_item_visible(_udder_glow_item, milking)
	if _phase == ScenePhase.PETTING:
		_set_cow_texture(cow_idle_texture if cow_idle_texture != null else cow_happy_texture)
	elif _phase == ScenePhase.MILKING:
		_set_cow_texture(cow_happy_texture if cow_happy_texture != null else cow_idle_texture)
	elif _phase == ScenePhase.COMPLETE:
		_set_area_pickable(_pet_area, false)
		_set_area_pickable(_udder_area, false)
		_set_item_visible(_pet_glow_item, false)
		_set_item_visible(_udder_glow_item, false)
		_set_cow_texture(cow_celebrating_texture if cow_celebrating_texture != null else cow_happy_texture)


func _set_area_pickable(area: Area2D, enabled: bool) -> void:
	if area != null:
		area.input_pickable = enabled


func _set_item_visible(item: CanvasItem, enabled: bool) -> void:
	if item != null:
		item.visible = enabled


func _set_cow_texture(texture: Texture2D) -> void:
	if _cow_visual != null and texture != null:
		_cow_visual.texture = texture


func _pulse_cow(scale_multiplier: float = 1.04, duration: float = 0.08) -> void:
	if _cow_visual == null:
		return
	FarmFeedback.pulse(_cow_visual, scale_multiplier, duration)


func _nudge_cow(offset: Vector2, duration: float) -> void:
	if _cow_visual == null:
		return
	var original_position := _cow_visual.position
	var tween := _cow_visual.create_tween()
	tween.tween_property(_cow_visual, "position", original_position + offset, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_cow_visual, "position", original_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _show_assist_hint(strong: bool) -> void:
	match _phase:
		ScenePhase.PETTING:
			if _pet_area != null:
				ChoreRuntimeScript.show_assist_hint(
					_pet_area,
					strong,
					tr("Tap the cow to give her a gentle pat."),
					"milking_pet_hint_strong" if strong else "milking_pet_hint_gentle"
				)
			elif _cow_visual != null:
				ChoreRuntimeScript.show_assist_hint(
					_cow_visual,
					strong,
					tr("Tap the cow to give her a gentle pat."),
					"milking_pet_hint_strong" if strong else "milking_pet_hint_gentle"
				)
		ScenePhase.MILKING:
			if _udder_area != null:
				ChoreRuntimeScript.show_assist_hint(
					_udder_area,
					strong,
					tr("Tap the udder to help fill the bucket."),
					"milking_hint_strong" if strong else "milking_hint_gentle"
				)
			elif _cow_visual != null:
				ChoreRuntimeScript.show_assist_hint(
					_cow_visual,
					strong,
					tr("Tap near the cow to help with milking."),
					"milking_hint_cow_strong" if strong else "milking_hint_cow_gentle"
				)


func _is_event_near_pet_target(event: InputEvent) -> bool:
	if _pet_area != null:
		return ChoreCompletionFlowScript.is_event_near_node(event, _pet_area, assist_stage_two_radius)
	return _cow_visual != null and ChoreCompletionFlowScript.is_event_near_node(event, _cow_visual, assist_stage_two_radius)


func _is_event_near_udder(event: InputEvent) -> bool:
	if _udder_area != null:
		return ChoreCompletionFlowScript.is_event_near_node(event, _udder_area, assist_stage_two_radius)
	return _cow_visual != null and ChoreCompletionFlowScript.is_event_near_node(event, _cow_visual, assist_stage_two_radius)


func _is_event_on_udder(event: InputEvent) -> bool:
	return ChoreCompletionFlowScript.is_event_inside_area(event, _udder_area, self, direct_tap_margin)


func _is_primary_tap_event(event: InputEvent) -> bool:
	return (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)


func _refresh_ui() -> void:
	if _progress_label != null:
		FarmFeedback.show_counter_label(_progress_label, FarmState.get_milk_amount(), FarmState.MILK_GOAL)
	if _bucket_fill != null:
		var milk_amount := FarmState.get_milk_amount()
		if _phase != ScenePhase.MILKING and _phase != ScenePhase.COMPLETE:
			milk_amount = 0
		var ratio := float(milk_amount) / float(FarmState.MILK_GOAL)
		if _bucket_fill.has_method("set_fill_ratio"):
			_bucket_fill.call("set_fill_ratio", ratio)
		elif _bucket_fill is ColorRect:
			var fill_rect := _bucket_fill as ColorRect
			fill_rect.size = Vector2(fill_rect.size.x, lerp(18.0, 250.0, ratio))
			fill_rect.position = Vector2(fill_rect.position.x, 770.0 - fill_rect.size.y)


func _show_phase_feedback(text: String, color: Color, duration: float = 0.8) -> void:
	FarmFeedback.flash_label(_feedback_label, text, color, duration)


func _play_milk_stream(finished: Callable = Callable()) -> void:
	var stream_start := _get_milk_stream_start()
	var stream_end := _get_milk_stream_end()
	if stream_start == Vector2.INF or stream_end == Vector2.INF:
		if finished.is_valid():
			finished.call()
		return

	var stream := Line2D.new()
	stream.default_color = milk_stream_color
	stream.width = milk_stream_width
	stream.z_index = 20
	var midpoint := stream_start.lerp(stream_end, 0.52) + Vector2(0.0, 24.0)
	stream.points = PackedVector2Array([
		to_local(stream_start),
		to_local(midpoint),
		to_local(stream_end),
	])
	add_child(stream)

	var tween := create_tween()
	tween.tween_property(stream, "modulate:a", 0.0, milk_stream_duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(stream):
			stream.queue_free()
		if finished.is_valid() and is_instance_valid(self):
			finished.call()
	)


func _get_milk_stream_start() -> Vector2:
	if _milk_stream_source != null:
		return _milk_stream_source.global_position
	if _udder_area != null:
		return _udder_area.to_global(Vector2(0.0, 56.0))
	return Vector2.INF


func _get_milk_stream_end() -> Vector2:
	if _milk_stream_target != null:
		return _milk_stream_target.global_position
	if _bucket_node != null:
		return _bucket_node.to_global(Vector2(0.0, -48.0))
	return Vector2.INF


func _show_completion(play_sound: bool) -> void:
	if _completion_active:
		return
	_completion_active = true
	_set_phase(ScenePhase.COMPLETE)
	var feedback := FarmState.get_chore_completion_feedback(FarmState.CHORE_MILKING)
	var message := str(feedback.get("text", _get_completion_message()))
	var voice_key := str(feedback.get("voice_key", "milking_complete_0"))
	var origin := _cow_rig.global_position + Vector2(320.0, 24.0) if _cow_rig != null else _cow_visual.global_position + Vector2(360.0, 24.0) if _cow_visual != null else Vector2(960.0, 540.0)
	FarmFeedback.pulse(_cow_visual, 1.08, 0.12)
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
		22,
		farmyard_scene_path,
		post_completion_return_delay,
		post_completion_return_lock
	)


func _return_to_farmyard() -> void:
	ChoreCompletionFlowScript.try_return_to_farmyard(self, farmyard_scene_path)


func _get_completion_message() -> String:
	return FarmState.get_chore_completion_message(FarmState.CHORE_MILKING)
