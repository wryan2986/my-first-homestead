extends Node2D

const ChoreAssistScript := preload("res://scripts/core/ChoreAssist.gd")
const ChoreCompletionFlowScript := preload("res://scripts/core/ChoreCompletionFlow.gd")
const ChoreRuntimeScript := preload("res://scripts/core/ChoreRuntime.gd")
const ASSIST_STAGE_STRONG_HINT := 2
const ASSIST_STAGE_ACTION := 3

@export_file("*.tscn") var farmyard_scene_path := "res://scenes/FarmyardScene.tscn"
@export var background_sprite: NodePath
@export var background_overlay: NodePath
@export var season_label: NodePath
@export var progress_label: NodePath
@export var feedback_label: NodePath
@export var tip_label: NodePath
@export var completion_panel: NodePath
@export var completion_label: NodePath
@export var back_button: NodePath
@export var plot_paths: Array[NodePath] = []
@export var water_sound: AudioStream
@export var harvest_sound: AudioStream
@export var completion_sound: AudioStream
@export var watering_can_source: NodePath
@export var seed_source: NodePath
@export var harvest_basket: NodePath
@export var harvest_basket_fill: NodePath
@export var harvest_drop_target: NodePath
@export var action_animation_layer: NodePath
@export var winter_cold_frame_root: NodePath
@export var winter_cold_frame_tap_area: NodePath
@export var watering_can_texture: Texture2D
@export var water_drop_texture: Texture2D
@export var seed_texture: Texture2D
@export var seed_packet_texture: Texture2D
@export var harvest_item_texture: Texture2D
@export var harvest_sparkle_texture: Texture2D
@export var spring_background_texture: Texture2D
@export var summer_background_texture: Texture2D
@export var fall_background_texture: Texture2D
@export var winter_background_texture: Texture2D
@export var watering_feedback_actions: Array[String] = ["water", "care", "grow"]
@export var watering_can_travel_seconds := 0.95
@export var watering_effect_seconds := 0.62
@export var watering_can_pour_offset := Vector2(90.0, -150.0)
@export var watering_drops_offset := Vector2(18.0, -70.0)
@export var seed_travel_seconds := 0.85
@export var harvest_travel_seconds := 0.9
@export var direct_tap_margin := 24.0
@export var duplicate_tap_guard_seconds := 0.12
@export var assist_stage_two_radius := 210.0
@export var post_completion_return_delay := 7.0
@export var post_completion_return_lock := 1.0

var _completion_active := false
var _interaction_locked := false
var _last_plot_tap_msec := -1000000
var _last_plot_tap_index := -1
var _assist: RefCounted = ChoreAssistScript.new()
var _default_background_texture: Texture2D
@onready var _background_sprite: Sprite2D = get_node_or_null(background_sprite) as Sprite2D
@onready var _background_overlay: ColorRect = get_node_or_null(background_overlay) as ColorRect
@onready var _season_label: Label = get_node_or_null(season_label) as Label
@onready var _progress_label: Label = get_node_or_null(progress_label) as Label
@onready var _feedback_label: Label = get_node_or_null(feedback_label) as Label
@onready var _tip_label: Label = get_node_or_null(tip_label) as Label
@onready var _completion_panel: Control = get_node_or_null(completion_panel) as Control
@onready var _completion_label: Label = get_node_or_null(completion_label) as Label
@onready var _back_button: Button = get_node_or_null(back_button) as Button
@onready var _watering_can_source: Node2D = get_node_or_null(watering_can_source) as Node2D
@onready var _resting_watering_can: Sprite2D = get_node_or_null("WateringCanSource/RestingWateringCan") as Sprite2D
@onready var _seed_source: Node2D = get_node_or_null(seed_source) as Node2D
@onready var _resting_seed_packet: Sprite2D = get_node_or_null("SeedSource/SeedPacketVisual") as Sprite2D
@onready var _harvest_basket: Node2D = get_node_or_null(harvest_basket) as Node2D
@onready var _harvest_basket_fill: Node = get_node_or_null(harvest_basket_fill)
@onready var _harvest_drop_target: Node2D = get_node_or_null(harvest_drop_target) as Node2D
@onready var _action_animation_layer: Node = get_node_or_null(action_animation_layer)
@onready var _winter_cold_frame_root: Node2D = get_node_or_null(winter_cold_frame_root) as Node2D
@onready var _winter_cold_frame_tap_area: Area2D = get_node_or_null(winter_cold_frame_tap_area) as Area2D


func _ready() -> void:
	if _is_scene_navigator_cache_prepare():
		return
	_completion_active = false
	_interaction_locked = false
	MusicManager.play_chore_music()
	if _background_sprite != null:
		_default_background_texture = _background_sprite.texture
	if GameSettings.has_signal("locale_changed") and not GameSettings.locale_changed.is_connected(_refresh_scene):
		GameSettings.locale_changed.connect(_refresh_scene)
	ChoreRuntimeScript.configure_assist(_assist, FarmState.CHORE_GARDEN)
	FarmState.prepare_garden_for_current_day()
	if _back_button != null and not _back_button.pressed.is_connected(_return_to_farmyard):
		_back_button.pressed.connect(_return_to_farmyard)
	if _completion_panel != null:
		_completion_panel.visible = false
	ChoreCompletionFlowScript.prepare_chore_scene(self, _back_button)
	FarmFeedback.hide_play_scene_text(self)
	if _winter_cold_frame_tap_area != null:
		if not _winter_cold_frame_tap_area.input_event.is_connected(_on_cold_frame_input_event):
			_winter_cold_frame_tap_area.input_event.connect(_on_cold_frame_input_event)

	for plot_path in plot_paths:
		var plot := get_node_or_null(plot_path) as GardenPlot
		if plot == null:
			continue
		if not plot.tapped.is_connected(_on_plot_tapped):
			plot.tapped.connect(_on_plot_tapped)
		_refresh_plot(plot)

	_refresh_scene()
	_complete_garden_if_all_plots_are_cared_for()
	if FarmState.is_chore_completed(FarmState.CHORE_GARDEN):
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
	if _completion_active or FarmState.is_chore_completed(FarmState.CHORE_GARDEN):
		return
	if bool(_assist.call("should_show_hint")):
		_show_assist_hint(int(_assist.call("get_stage")) >= ASSIST_STAGE_STRONG_HINT)


func _input(event: InputEvent) -> void:
	if _completion_active:
		ChoreCompletionFlowScript.handle_completion_return_input(self, event, farmyard_scene_path)


func _unhandled_input(event: InputEvent) -> void:
	if not ChoreCompletionFlowScript.is_tap_event(event):
		return
	if _interaction_locked:
		get_viewport().set_input_as_handled()
		return
	if _completion_active or FarmState.is_chore_completed(FarmState.CHORE_GARDEN):
		return

	if _handle_direct_tap(event):
		get_viewport().set_input_as_handled()
		return

	get_viewport().set_input_as_handled()
	_handle_failed_tap(event)


func _on_plot_tapped(plot: GardenPlot) -> void:
	if _completion_active or _interaction_locked:
		return
	_handle_plot_tap(plot)


func _on_cold_frame_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _completion_active or _interaction_locked or not _is_winter_scene_active():
		return
	if _is_event_inside_any_plot(event):
		return
	if ChoreCompletionFlowScript.is_tap_event(event):
		get_viewport().set_input_as_handled()
		_perform_next_garden_action()


func _handle_plot_tap(plot: GardenPlot) -> void:
	if _interaction_locked or plot == null or _is_duplicate_plot_tap(plot.plot_index):
		return
	_last_plot_tap_index = plot.plot_index
	_last_plot_tap_msec = Time.get_ticks_msec()

	var result := FarmState.interact_with_plot(plot.plot_index)
	result["plot_index"] = plot.plot_index
	_handle_garden_result(result)


func _handle_direct_tap(event: InputEvent) -> bool:
	for plot_path in plot_paths:
		var plot := get_node_or_null(plot_path) as GardenPlot
		if plot == null or not plot.visible:
			continue
		if ChoreCompletionFlowScript.is_event_inside_area(event, plot, self, direct_tap_margin):
			_handle_plot_tap(plot)
			return true

	if _is_winter_scene_active() and _winter_cold_frame_tap_area != null:
		if ChoreCompletionFlowScript.is_event_inside_area(event, _winter_cold_frame_tap_area, self, direct_tap_margin):
			_perform_next_garden_action()
			return true
	return false


func _is_event_inside_any_plot(event: InputEvent) -> bool:
	for plot_path in plot_paths:
		var plot := get_node_or_null(plot_path) as GardenPlot
		if plot == null or not plot.visible:
			continue
		if ChoreCompletionFlowScript.is_event_inside_area(event, plot, self, direct_tap_margin):
			return true
	return false


func _perform_next_garden_action() -> bool:
	if _completion_active or _interaction_locked:
		return false
	var result := FarmState.interact_with_next_garden_plot()
	_handle_garden_result(result)
	return bool(result.get("success", false))


func _handle_failed_tap(event: InputEvent) -> void:
	var stage_before := int(_assist.call("get_stage"))
	if stage_before >= ASSIST_STAGE_STRONG_HINT and _is_event_near_next_plot(event):
		_perform_next_garden_action()
		return

	var stage := _record_failed_attempt()
	if stage >= ASSIST_STAGE_STRONG_HINT and _is_event_near_next_plot(event):
		_perform_next_garden_action()
		return

	if stage >= ASSIST_STAGE_ACTION and bool(_assist.call("can_perform_assist_action")):
		ChoreRuntimeScript.mark_assist_action_performed(_assist, FarmState.CHORE_GARDEN)
		_perform_next_garden_action()
		return

	if bool(_assist.call("should_show_hint")):
		_show_assist_hint(stage >= ASSIST_STAGE_STRONG_HINT)


func _is_duplicate_plot_tap(plot_index: int) -> bool:
	if plot_index != _last_plot_tap_index:
		return false
	var elapsed := float(Time.get_ticks_msec() - _last_plot_tap_msec) / 1000.0
	return elapsed <= duplicate_tap_guard_seconds


func _handle_garden_result(result: Dictionary) -> void:
	if bool(result.get("success", false)):
		_record_progress()
		var plot_index := int(result.get("plot_index", -1))
		var plot := _get_plot_by_index(plot_index)
		var action := String(result.get("action", "care"))
		if action == "harvest":
			FarmFeedback.play_one_shot(self, harvest_sound, -3.0)
		else:
			FarmFeedback.play_one_shot(self, water_sound, -4.0)

		_interaction_locked = true
		_play_action_feedback(plot, action, func() -> void:
			_finish_success_result(result, plot_index, action)
		)
	else:
		_refresh_all_plots()
		_refresh_scene()


func _finish_success_result(result: Dictionary, plot_index: int, action: String) -> void:
	_interaction_locked = false
	_refresh_all_plots()
	_refresh_scene()

	var plot := _get_plot_by_index(plot_index)
	if plot != null and plot.visible:
		plot.play_success(action)
	elif _winter_cold_frame_root != null and _winter_cold_frame_root.visible:
		FarmFeedback.pulse(_winter_cold_frame_root, 1.04, 0.16)
	_complete_garden_if_all_plots_are_cared_for()
	if FarmState.is_chore_completed(FarmState.CHORE_GARDEN):
		_show_completion(true)


func _complete_garden_if_all_plots_are_cared_for() -> void:
	if FarmState.is_chore_completed(FarmState.CHORE_GARDEN):
		return
	if FarmState.is_garden_cared_for_today():
		FarmState.complete_chore(FarmState.CHORE_GARDEN)


func _play_action_feedback(plot: GardenPlot, action: String, finished: Callable) -> void:
	match action:
		"seed":
			_play_seed_feedback(plot, finished)
		"harvest":
			_play_harvest_feedback(plot, finished)
		"rest":
			_play_cold_frame_feedback(plot, finished)
		_:
			if action in watering_feedback_actions:
				_play_watering_feedback(plot, finished)
			else:
				finished.call()


func _play_watering_feedback(plot: GardenPlot, finished: Callable) -> void:
	if watering_can_texture == null:
		finished.call()
		return

	var target_position := _get_action_origin(plot)
	var can_scale := FarmFeedback.get_visual_global_scale(_resting_watering_can, Vector2(0.24, 0.24))
	var can := _make_feedback_sprite(watering_can_texture, can_scale, 35)

	var start_position := target_position + Vector2(160.0, -210.0)
	if _watering_can_source != null:
		start_position = _watering_can_source.global_position
	can.global_position = start_position
	can.modulate.a = 1.0
	if _resting_watering_can != null:
		_resting_watering_can.visible = false

	var pour_position := target_position + watering_can_pour_offset
	var water_position := target_position + watering_drops_offset
	var travel_time := clampf(watering_can_travel_seconds, 0.2, 2.0)
	var effect_time := clampf(watering_effect_seconds, 0.2, 1.4)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(can, "global_position", pour_position, travel_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(can, "rotation_degrees", -18.0, travel_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		_spawn_water_drops(water_position, effect_time)
	)
	tween.tween_interval(effect_time)
	tween.tween_property(can, "rotation_degrees", 0.0, 0.2)
	tween.tween_property(can, "global_position", start_position, minf(0.35, travel_time * 0.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		can.queue_free()
		if _resting_watering_can != null:
			_resting_watering_can.visible = true
		finished.call()
	)


func _play_seed_feedback(plot: GardenPlot, finished: Callable) -> void:
	if plot == null or seed_texture == null:
		finished.call()
		return

	var seed_target := plot.global_position + Vector2(0.0, -42.0)
	var start_position := seed_target + Vector2(210.0, -150.0)
	if _seed_source != null:
		start_position = _seed_source.global_position

	var packet: Sprite2D = null
	if seed_packet_texture != null:
		var packet_scale := FarmFeedback.get_visual_global_scale(_resting_seed_packet, Vector2(0.22, 0.22))
		packet = _make_feedback_sprite(seed_packet_texture, packet_scale, 35)
		packet.global_position = start_position
		packet.modulate.a = 0.0
		var packet_tween := create_tween()
		packet_tween.set_parallel(true)
		packet_tween.tween_property(packet, "modulate:a", 1.0, 0.12)
		packet_tween.tween_property(packet, "scale", packet_scale * 1.12, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var travel_time := clampf(seed_travel_seconds, 0.2, 2.0)
	for index in range(5):
		var seed := _make_feedback_sprite(seed_texture, Vector2(0.09, 0.09), 36)
		seed.global_position = start_position + Vector2(-28.0 + float(index) * 14.0, 8.0 - float(index % 2) * 10.0)
		var end_position := seed_target + Vector2(-46.0 + float(index) * 23.0, -12.0 + float(index % 2) * 20.0)
		var seed_tween := create_tween()
		seed_tween.set_parallel(true)
		seed_tween.tween_property(seed, "global_position", end_position, travel_time + float(index) * 0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		seed_tween.tween_property(seed, "rotation_degrees", 160.0 - float(index) * 32.0, travel_time)
		seed_tween.tween_property(seed, "modulate:a", 0.0, 0.18).set_delay(travel_time - 0.12)
		seed_tween.set_parallel(false)
		seed_tween.tween_callback(Callable(seed, "queue_free"))

	var timer := get_tree().create_timer(travel_time + 0.2)
	timer.timeout.connect(func() -> void:
		if packet != null and is_instance_valid(packet):
			var fade := create_tween()
			fade.tween_property(packet, "modulate:a", 0.0, 0.14)
			fade.tween_callback(Callable(packet, "queue_free"))
		finished.call()
	)


func _play_harvest_feedback(plot: GardenPlot, finished: Callable) -> void:
	var visual_texture := harvest_item_texture
	var source_position := _get_action_origin(plot) + Vector2(0.0, -86.0)
	var source_scale := Vector2(0.24, 0.24)
	var basket_scale := Vector2(0.25, 0.25)
	var source_modulate := Color.WHITE
	if plot != null and plot.visible:
		var plot_texture := plot.get_plant_feedback_texture()
		if plot_texture != null:
			visual_texture = plot.get_harvest_basket_texture()
			source_position = plot.get_plant_feedback_origin()
			source_scale = plot.get_harvest_basket_scale()
			basket_scale = plot.get_harvest_basket_scale()
			source_modulate = plot.get_plant_feedback_modulate()
			plot.set_plant_feedback_visible(false)

	if visual_texture == null:
		finished.call()
		return

	var crop := _make_feedback_sprite(visual_texture, source_scale, 36)
	crop.global_position = source_position
	crop.modulate = source_modulate
	FarmFeedback.pulse(crop, 1.12, 0.08)

	var basket_position := _get_harvest_drop_position(crop.global_position)

	var travel_time := clampf(harvest_travel_seconds, 0.2, 2.0)
	var settle_time := minf(0.18, travel_time * 0.28)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(crop, "global_position", basket_position, travel_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(crop, "scale", source_scale * 0.58, travel_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(crop, "rotation_degrees", 22.0, travel_time)
	tween.set_parallel(false)
	tween.tween_property(crop, "modulate:a", 0.0, settle_time)
	tween.tween_callback(func() -> void:
		crop.queue_free()
		if _harvest_basket != null:
			FarmFeedback.pulse(_harvest_basket, 1.08, 0.12)
			if harvest_sparkle_texture != null:
				FarmFeedback.soft_sparkle_burst(self, harvest_sparkle_texture, basket_position, 5, 0.11)
		if _harvest_basket_fill != null and _harvest_basket_fill.has_method("add_crop"):
			_harvest_basket_fill.call("add_crop", visual_texture, source_modulate, basket_scale)
		finished.call()
	)


func _get_harvest_drop_position(fallback_position: Vector2) -> Vector2:
	if _harvest_drop_target != null:
		return _harvest_drop_target.global_position
	if _harvest_basket != null:
		return _harvest_basket.global_position + Vector2(0.0, -42.0)
	return fallback_position + Vector2(190.0, 120.0)


func _play_cold_frame_feedback(plot: GardenPlot, finished: Callable) -> void:
	if _winter_cold_frame_root == null:
		finished.call()
		return
	FarmFeedback.pulse(_winter_cold_frame_root, 1.04, 0.16)
	var care_origin := _get_action_origin(plot) + Vector2(0.0, -70.0)
	_spawn_water_drops(care_origin, 0.5)
	var timer := get_tree().create_timer(0.58)
	timer.timeout.connect(func() -> void:
		finished.call()
	)


func _spawn_water_drops(origin: Vector2, duration: float = 0.42) -> void:
	if water_drop_texture == null:
		return

	for index in range(5):
		var drop := _make_feedback_sprite(water_drop_texture, Vector2(0.075, 0.075), 34)
		drop.modulate.a = 0.9

		var start_offset := Vector2(-72.0 + float(index) * 36.0, -22.0 - float(index % 2) * 18.0)
		var end_offset := Vector2(-28.0 + float(index) * 14.0, 88.0 + float(index % 2) * 8.0)
		drop.global_position = origin + start_offset
		var fall := create_tween()
		fall.set_parallel(true)
		fall.tween_property(drop, "global_position", origin + end_offset, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		fall.tween_property(drop, "modulate:a", 0.0, duration)
		fall.set_parallel(false)
		fall.tween_callback(Callable(drop, "queue_free"))


func _make_feedback_sprite(texture: Texture2D, sprite_scale: Vector2, z_index: int) -> Sprite2D:
	return FarmFeedback.make_feedback_sprite(_get_animation_parent(), texture, sprite_scale, z_index)


func _get_animation_parent() -> Node:
	return _action_animation_layer if _action_animation_layer != null else self


func _get_action_origin(plot: GardenPlot) -> Vector2:
	if plot != null and plot.visible:
		return plot.global_position
	if _winter_cold_frame_root != null and _winter_cold_frame_root.visible:
		return _winter_cold_frame_root.global_position
	return Vector2(960.0, 720.0)


func _record_failed_attempt() -> int:
	return ChoreRuntimeScript.record_failed_attempt(_assist, FarmState.CHORE_GARDEN)


func _record_progress() -> void:
	ChoreRuntimeScript.record_progress(_assist, FarmState.CHORE_GARDEN, "garden_hint")


func _save_assist_memory() -> void:
	ChoreRuntimeScript.save_assist_memory(_assist, FarmState.CHORE_GARDEN)


func _refresh_all_plots() -> void:
	for plot_path in plot_paths:
		var plot := get_node_or_null(plot_path) as GardenPlot
		if plot != null:
			_refresh_plot(plot)


func _get_plot_by_index(plot_index: int) -> GardenPlot:
	for plot_path in plot_paths:
		var plot := get_node_or_null(plot_path) as GardenPlot
		if plot != null and plot.plot_index == plot_index:
			return plot
	return null


func _get_next_plot() -> GardenPlot:
	return _get_plot_by_index(FarmState.get_next_interactable_garden_plot_index())


func _is_event_near_next_plot(event: InputEvent) -> bool:
	var plot := _get_next_plot()
	if plot != null and ChoreCompletionFlowScript.is_event_near_node(event, plot, assist_stage_two_radius):
		return true
	if _is_winter_scene_active() and _winter_cold_frame_root != null:
		return ChoreCompletionFlowScript.is_event_near_node(event, _winter_cold_frame_root, assist_stage_two_radius)
	return false


func _show_assist_hint(strong: bool) -> void:
	var plot := _get_next_plot()
	if plot != null:
		var hint_text := "Tap the covered garden plot to care for the winter lettuce." if _is_winter_scene_active() else "Tap this garden plot to care for the plants."
		var hint_key := "garden_hint_plot_gentle"
		if _is_winter_scene_active():
			hint_key = "garden_hint_winter_strong" if strong else "garden_hint_winter_gentle"
		else:
			hint_key = "garden_hint_plot_strong" if strong else "garden_hint_plot_gentle"
		ChoreRuntimeScript.show_assist_hint(plot, strong, hint_text, hint_key)
	elif _is_winter_scene_active() and _winter_cold_frame_root != null:
		ChoreRuntimeScript.show_assist_hint(_winter_cold_frame_root, strong, tr("Tap a covered garden plot to care for the winter lettuce."), "garden_hint_winter_strong" if strong else "garden_hint_winter_gentle")


func _refresh_plot(plot: GardenPlot) -> void:
	plot.apply_plot_data(FarmState.get_plot_data(plot.plot_index), FarmState.current_season)


func _refresh_scene() -> void:
	_refresh_winter_visual_state()
	_refresh_background_texture()
	if _season_label != null:
		FarmFeedback.hide_label(_season_label)
	if _progress_label != null:
		FarmFeedback.show_counter_label(_progress_label, FarmState.get_garden_actions_today(), FarmState.get_garden_goal_for_today())
	if _tip_label != null:
		FarmFeedback.hide_label(_tip_label)
	if _background_overlay != null:
		_background_overlay.color = _get_overlay_color()


func _refresh_winter_visual_state() -> void:
	var winter_active := _is_winter_scene_active()
	if _winter_cold_frame_root != null:
		_winter_cold_frame_root.visible = winter_active
	if _winter_cold_frame_tap_area != null:
		_winter_cold_frame_tap_area.input_pickable = winter_active
		_winter_cold_frame_tap_area.monitorable = winter_active
	for plot_path in plot_paths:
		var plot := get_node_or_null(plot_path) as GardenPlot
		if plot != null:
			plot.visible = true
			plot.input_pickable = true


func _refresh_background_texture() -> void:
	if _background_sprite == null:
		return
	var seasonal_texture := _get_background_texture_for_season()
	_background_sprite.texture = seasonal_texture if seasonal_texture != null else _default_background_texture
	if _background_sprite.has_method("apply_cover"):
		_background_sprite.call("apply_cover")


func _get_background_texture_for_season() -> Texture2D:
	match FarmState.current_season:
		"spring":
			return spring_background_texture
		"summer":
			return summer_background_texture
		"fall":
			return fall_background_texture
		"winter":
			return winter_background_texture
		_:
			return null


func _is_winter_scene_active() -> bool:
	return FarmState.current_season == "winter"


func _show_completion(play_sound: bool) -> void:
	if _completion_active:
		return
	_completion_active = true
	var feedback := FarmState.get_chore_completion_feedback(FarmState.CHORE_GARDEN)
	var message := str(feedback.get("text", _get_completion_message()))
	var voice_key := str(feedback.get("voice_key", "garden_complete_0"))
	ChoreCompletionFlowScript.show_completion_feedback(
		self,
		_completion_panel,
		_completion_label,
		_back_button,
		message,
		play_sound,
		completion_sound,
		voice_key,
		Vector2(960.0, 600.0),
		24,
		farmyard_scene_path,
		post_completion_return_delay,
		post_completion_return_lock
	)


func _get_overlay_color() -> Color:
	match FarmState.current_season:
		"spring":
			return Color(0.72, 1.0, 0.76, 0.16)
		"summer":
			return Color(1.0, 0.95, 0.58, 0.14)
		"fall":
			return Color(1.0, 0.8, 0.58, 0.18)
		_:
			return Color(0.88, 0.95, 1.0, 0.22)


func _return_to_farmyard() -> void:
	ChoreCompletionFlowScript.try_return_to_farmyard(self, farmyard_scene_path)


func _get_completion_message() -> String:
	return FarmState.get_chore_completion_message(FarmState.CHORE_GARDEN)
