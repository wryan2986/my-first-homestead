extends Node2D

@export_file("*.tscn") var farmyard_scene_path := "res://scenes/FarmyardScene.tscn"
@export var background_sprite: NodePath
@export var back_button: NodePath
@export var feedback_label: NodePath
@export var mole_sprite: NodePath
@export var hole_nodes: Array[NodePath] = []
@export_file("*.png") var hole_texture_path := "res://art/props/mole_hole.png"
@export var note_effect_texture: Texture2D
@export var hole_note_colors: Array[Color] = []
@export var chord_root_sound: AudioStream
@export var chord_third_sound: AudioStream
@export var chord_fifth_sound: AudioStream
@export var chord_sixth_sound: AudioStream
@export var mole_scale := Vector2(0.18, 0.18)
@export var mole_scales: Array[Vector2] = [Vector2(0.16, 0.16), Vector2(0.155, 0.155), Vector2(0.16, 0.16), Vector2(0.18, 0.18), Vector2(0.18, 0.18)]
@export var mole_rise_offset := Vector2(0.0, 92.0)
@export var mole_rest_offset := Vector2(0.0, 16.0)
@export var mole_hide_offset := Vector2(0.0, 112.0)
@export var mole_rise_offsets: Array[Vector2] = [Vector2(0.0, 84.0), Vector2(0.0, 78.0), Vector2(0.0, 84.0), Vector2(0.0, 92.0), Vector2(0.0, 92.0)]
@export var mole_rest_offsets: Array[Vector2] = [Vector2(0.0, 8.0), Vector2(0.0, 6.0), Vector2(0.0, 8.0), Vector2(0.0, 16.0), Vector2(0.0, 16.0)]
@export var mole_hide_offsets: Array[Vector2] = [Vector2(0.0, 104.0), Vector2(0.0, 100.0), Vector2(0.0, 104.0), Vector2(0.0, 112.0), Vector2(0.0, 112.0)]
@export var rise_time := 0.32
@export var sink_time := 0.24
@export var next_mole_delay := 0.8
@export var note_spawn_offset := Vector2(0.0, -90.0)
@export var time_limit_seconds := 120.0

@onready var _background_sprite: Sprite2D = get_node_or_null(background_sprite) as Sprite2D
@onready var _back_button: Button = get_node_or_null(back_button) as Button
@onready var _feedback_label: Label = get_node_or_null(feedback_label) as Label
@onready var _mole_sprite: Sprite2D = get_node_or_null(mole_sprite) as Sprite2D

var _holes: Array[Area2D] = []
var _hole_visuals: Array[Sprite2D] = []
var _hole_visual_layer: Node2D
var _current_hole_index := -1
var _recent_hole_indices: Array[int] = []
var _hole_last_used_cycles: Array[int] = []
var _mole_spawn_cycle := 0
var _current_tune_index := 0
var _current_tune_step := 0
var _busy := false
var _rng := RandomNumberGenerator.new()
var _next_mole_timer: Timer
var _timeout_timer: SceneTreeTimer
var _time_limit_run_id := 0
var _hole_note_semitones := [0, 2, 4, 5, 7]
var _hole_texture: Texture2D
const HOLE_REUSE_COOLDOWN := 2
const TUNE_PATTERNS := [
	[2, 1, 0, 1, 2, 2, 2, 1, 1, 1, 2, 4, 4, 2, 1, 0, 1, 2, 2, 2, 2, 1, 1, 2, 1, 0],
	[0, 0, 4, 4, 3, 3, 4, 2, 2, 1, 1, 0],
	[0, 1, 2, 3, 4, 3, 2, 1],
]


func _ready() -> void:
	if _is_scene_navigator_cache_prepare():
		return
	_busy = false
	_current_hole_index = -1
	_time_limit_run_id += 1
	FarmState.mark_mole_garden_visited_today()
	_rng.randomize()
	_connect_ui()
	_apply_background()
	_cache_holes()
	_load_hole_texture()
	_apply_hole_texture()
	_prepare_mole_sprite()
	_create_next_mole_timer()
	_start_time_limit_if_enabled()
	_show_next_mole()
	FarmFeedback.hide_play_scene_text(self)


func prepare_for_cached_scene() -> void:
	pass


func activate_from_cache() -> void:
	_ready()


func deactivate_for_cache_or_free() -> void:
	_time_limit_run_id += 1
	if _next_mole_timer != null and is_instance_valid(_next_mole_timer):
		_next_mole_timer.stop()
	_timeout_timer = null


func _is_scene_navigator_cache_prepare() -> bool:
	return has_meta("_scene_navigator_cache_prepare")


func _exit_tree() -> void:
	if _next_mole_timer != null and is_instance_valid(_next_mole_timer):
		_next_mole_timer.stop()


func _connect_ui() -> void:
	if _back_button != null and not _back_button.pressed.is_connected(_return_to_farmyard):
		_back_button.pressed.connect(_return_to_farmyard)


func _apply_background() -> void:
	if _background_sprite == null:
		return
	if _background_sprite.has_method("apply_cover"):
		_background_sprite.call("apply_cover")


func _cache_holes() -> void:
	_holes.clear()
	_hole_visuals.clear()
	_recent_hole_indices.clear()
	_hole_last_used_cycles.clear()
	_ensure_hole_visual_layer()
	for index in hole_nodes.size():
		var hole := get_node_or_null(hole_nodes[index]) as Area2D
		if hole == null:
			continue
		hole.input_pickable = true
		if not hole.input_event.is_connected(_on_hole_input_event.bind(index)):
			hole.input_event.connect(_on_hole_input_event.bind(index))
		_holes.append(hole)
		_hole_last_used_cycles.append(-1)
		var legacy_visual := hole.get_node_or_null("HoleVisual") as Sprite2D
		var hole_visual := _ensure_hole_visual(index, hole, legacy_visual)
		if legacy_visual != null:
			legacy_visual.visible = false
		_hole_visuals.append(hole_visual)


func _ensure_hole_visual_layer() -> void:
	_hole_visual_layer = get_node_or_null("HoleVisualLayer") as Node2D
	if _hole_visual_layer == null:
		_hole_visual_layer = Node2D.new()
		_hole_visual_layer.name = "HoleVisualLayer"
		add_child(_hole_visual_layer)
		move_child(_hole_visual_layer, min(get_child_count() - 1, 2))
	_hole_visual_layer.z_index = 4


func _ensure_hole_visual(index: int, hole: Area2D, legacy_visual: Sprite2D) -> Sprite2D:
	var visual_name := "HoleVisual%d" % index
	var visual := _hole_visual_layer.get_node_or_null(visual_name) as Sprite2D
	if visual == null:
		visual = Sprite2D.new()
		visual.name = visual_name
		_hole_visual_layer.add_child(visual)
	visual.centered = true
	visual.visible = true
	visual.z_index = 0
	visual.global_position = hole.global_position
	if legacy_visual != null:
		visual.scale = legacy_visual.scale
		visual.rotation = legacy_visual.rotation
		visual.modulate = legacy_visual.modulate
	else:
		visual.scale = Vector2(0.13, 0.13)
	return visual


func _load_hole_texture() -> void:
	_hole_texture = null
	if hole_texture_path.is_empty():
		return
	_hole_texture = ResourceLoader.load(hole_texture_path) as Texture2D
	if _hole_texture != null:
		return
	var image := Image.new()
	var load_error := image.load(ProjectSettings.globalize_path(hole_texture_path))
	if load_error != OK:
		return
	_hole_texture = ImageTexture.create_from_image(image)


func _apply_hole_texture() -> void:
	if _hole_texture == null:
		return
	for index in _hole_visuals.size():
		var hole_visual := _hole_visuals[index]
		if hole_visual != null:
			hole_visual.texture = _hole_texture
			if index < _holes.size() and _holes[index] != null:
				hole_visual.global_position = _holes[index].global_position


func _prepare_mole_sprite() -> void:
	if _mole_sprite == null:
		return
	_mole_sprite.visible = false
	_mole_sprite.scale = mole_scale
	_mole_sprite.modulate.a = 0.0


func _create_next_mole_timer() -> void:
	if _next_mole_timer != null and is_instance_valid(_next_mole_timer):
		_next_mole_timer.stop()
		_next_mole_timer.wait_time = maxf(0.2, next_mole_delay)
		return
	_next_mole_timer = Timer.new()
	_next_mole_timer.one_shot = true
	_next_mole_timer.wait_time = maxf(0.2, next_mole_delay)
	_next_mole_timer.timeout.connect(_show_next_mole)
	add_child(_next_mole_timer)


func _show_next_mole() -> void:
	if _busy or _mole_sprite == null or _holes.is_empty():
		return
	_mole_spawn_cycle += 1
	_current_hole_index = _pick_next_hole_index()
	var hole := _holes[_current_hole_index]
	if hole == null or not is_instance_valid(hole):
		_current_hole_index = -1
		return
	_register_hole_use(_current_hole_index)
	_busy = true
	_mole_sprite.visible = true
	_mole_sprite.scale = _get_mole_scale(_current_hole_index)
	_mole_sprite.rotation = 0.0
	_mole_sprite.flip_h = _rng.randf() < 0.5
	var target_position := hole.global_position + _get_mole_offset(mole_rest_offsets, _current_hole_index, mole_rest_offset)
	_mole_sprite.global_position = hole.global_position + _get_mole_offset(mole_rise_offsets, _current_hole_index, mole_rise_offset)
	_mole_sprite.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_mole_sprite, "modulate:a", 1.0, 0.16)
	tween.tween_property(_mole_sprite, "global_position", target_position, rise_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_mole_sprite, "rotation", -0.03 if _mole_sprite.flip_h else 0.03, 0.16)
	tween.set_parallel(false)
	tween.tween_property(_mole_sprite, "rotation", 0.0, 0.16)
	tween.tween_callback(func() -> void:
		_busy = false
	)


func _pick_next_hole_index() -> int:
	if _holes.size() <= 1:
		return 0
	var tune := _get_current_tune()
	if tune.is_empty():
		return 0
	return posmod(int(tune[_current_tune_step]), _holes.size())


func _get_current_tune() -> Array:
	if TUNE_PATTERNS.is_empty():
		return []
	return TUNE_PATTERNS[posmod(_current_tune_index, TUNE_PATTERNS.size())]


func _advance_tune_step() -> void:
	var tune := _get_current_tune()
	if tune.is_empty():
		return
	_current_tune_step += 1
	if _current_tune_step >= tune.size():
		_current_tune_step = 0
		_current_tune_index = posmod(_current_tune_index + 1, TUNE_PATTERNS.size())


func _register_hole_use(hole_index: int) -> void:
	if hole_index < 0:
		return
	if hole_index >= _hole_last_used_cycles.size():
		return
	_hole_last_used_cycles[hole_index] = _mole_spawn_cycle
	_recent_hole_indices.erase(hole_index)
	_recent_hole_indices.push_front(hole_index)
	while _recent_hole_indices.size() > HOLE_REUSE_COOLDOWN:
		_recent_hole_indices.pop_back()


func _get_hole_weight(hole_index: int) -> float:
	if hole_index < 0 or hole_index >= _hole_last_used_cycles.size():
		return 0.0
	var last_used_cycle := _hole_last_used_cycles[hole_index]
	if last_used_cycle < 0:
		return 1.0
	var cycles_since_use := _mole_spawn_cycle - last_used_cycle
	if cycles_since_use <= HOLE_REUSE_COOLDOWN:
		return 0.0
	return float(cycles_since_use - HOLE_REUSE_COOLDOWN)


func _on_hole_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, hole_index: int) -> void:
	if not _is_press_event(event):
		return
	get_viewport().set_input_as_handled()
	if _busy or hole_index != _current_hole_index:
		return
	_hit_current_mole()


func _hit_current_mole() -> void:
	if _mole_sprite == null or _current_hole_index < 0 or _current_hole_index >= _holes.size():
		return
	var hole := _holes[_current_hole_index]
	if hole == null or not is_instance_valid(hole):
		return
	_busy = true
	FarmFeedback.pulse(_mole_sprite, 1.08, 0.12)
	FarmFeedback.spawn_note_shape(self, note_effect_texture, _mole_sprite.global_position + note_spawn_offset, _current_hole_index, _get_hole_note_color(_current_hole_index), Vector2(1.44, 1.44), Vector2(0.0, -68.0), 24, 0.85)
	_play_hole_note(_current_hole_index)
	_advance_tune_step()
	var hide_position := hole.global_position + _get_mole_offset(mole_hide_offsets, _current_hole_index, mole_hide_offset)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_mole_sprite, "global_position", hide_position, sink_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(_mole_sprite, "modulate:a", 0.0, sink_time)
	tween.tween_property(_mole_sprite, "rotation", 0.0, sink_time)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		if _mole_sprite != null and is_instance_valid(_mole_sprite):
			_mole_sprite.visible = false
		_current_hole_index = -1
		_busy = false
		_schedule_next_mole()
	)


func _play_hole_note(hole_index: int) -> void:
	if _holes.is_empty():
		return
	var note_index: int = posmod(hole_index, _hole_note_semitones.size())
	var semitone_offset: int = int(_hole_note_semitones[note_index])
	var stream := _get_note_stream_for_hole(note_index)
	var pitch_scale := _get_note_pitch_scale(note_index, semitone_offset)
	if stream != null:
		FarmFeedback.play_one_shot(self, stream, -8.0, pitch_scale)


func _get_note_stream_for_hole(note_index: int) -> AudioStream:
	match note_index:
		0, 1, 3:
			return chord_root_sound
		2:
			return chord_third_sound if chord_third_sound != null else chord_root_sound
		4:
			return chord_fifth_sound if chord_fifth_sound != null else chord_root_sound
	return chord_root_sound


func _get_note_pitch_scale(note_index: int, semitone_offset: int) -> float:
	match note_index:
		0:
			return 1.0
		2:
			return 1.0 if chord_third_sound != null else _semitones_to_pitch_scale(semitone_offset)
		4:
			return 1.0 if chord_fifth_sound != null else _semitones_to_pitch_scale(semitone_offset)
	return _semitones_to_pitch_scale(semitone_offset)


func _semitones_to_pitch_scale(semitones: int) -> float:
	return pow(2.0, float(semitones) / 12.0)


func _get_mole_scale(hole_index: int) -> Vector2:
	if hole_index >= 0 and hole_index < mole_scales.size():
		var scale := mole_scales[hole_index]
		if scale != Vector2.ZERO:
			return scale
	return mole_scale


func _get_mole_offset(offsets: Array[Vector2], hole_index: int, fallback: Vector2) -> Vector2:
	if hole_index >= 0 and hole_index < offsets.size():
		var offset := offsets[hole_index]
		if offset != Vector2.ZERO:
			return offset
	return fallback


func _get_hole_note_color(hole_index: int) -> Color:
	if hole_index >= 0 and hole_index < hole_note_colors.size():
		return hole_note_colors[hole_index]
	return Color.WHITE


func _schedule_next_mole() -> void:
	if _next_mole_timer == null or not is_instance_valid(_next_mole_timer):
		return
	_next_mole_timer.stop()
	_next_mole_timer.wait_time = maxf(0.2, next_mole_delay)
	_next_mole_timer.start()


func _start_time_limit_if_enabled() -> void:
	if not GameSettings.is_mole_garden_time_limit_enabled():
		return
	var run_id := _time_limit_run_id
	_timeout_timer = get_tree().create_timer(maxf(1.0, GameSettings.get_mole_garden_time_limit_seconds()), false)
	_timeout_timer.timeout.connect(func() -> void:
		if run_id == _time_limit_run_id and is_inside_tree() and visible:
			_return_to_farmyard()
	)


func _is_press_event(event: InputEvent) -> bool:
	return (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)


func _return_to_farmyard() -> void:
	if farmyard_scene_path.is_empty():
		return
	ChoreCompletionFlow.return_to_farmyard(self, farmyard_scene_path)
