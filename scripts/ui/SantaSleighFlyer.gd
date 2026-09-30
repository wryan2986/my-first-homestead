class_name SantaSleighFlyer
extends Node2D

@export var sleigh_sprite: NodePath
@export var tap_area: NodePath
@export var sparkle_texture: Texture2D
@export var bell_sound: AudioStream
@export var ho_ho_sound: AudioStream
@export var ho_ho_sounds: Array[AudioStream] = []
@export var lane_y := 148.0
@export var left_start_x := -260.0
@export var right_end_x := 2180.0
@export var flight_duration_range := Vector2(10.0, 14.0)
@export var interval_range := Vector2(28.0, 48.0)
@export var bell_repeat_seconds := 2.2
@export var max_bell_jingles := 3
@export var bell_sequence_max_seconds := 5.2
@export var tap_audio_cooldown_seconds := 0.45
@export var bob_amount := 28.0
@export var sparkle_count := 7

@onready var _sleigh: Sprite2D = get_node_or_null(sleigh_sprite) as Sprite2D
@onready var _tap_area: Area2D = get_node_or_null(tap_area) as Area2D

var _rng := RandomNumberGenerator.new()
var _time_until_flight := 0.0
var _enabled := false
var _active_tween: Tween
var _tap_bounce_tween: Tween
var _bell_timer: Timer
var _bell_player: AudioStreamPlayer
var _tap_player: AudioStreamPlayer
var _bell_jingle_count := 0
var _bell_sequence_started_msec := 0
var _last_tap_audio_msec := -1000000
var _greeting_player: AudioStreamPlayer


func _ready() -> void:
	_rng.seed = int(Time.get_ticks_usec()) + get_instance_id()
	_time_until_flight = _random_range(interval_range) * 0.35
	if _sleigh != null:
		_sleigh.visible = false
	if _tap_area != null:
		_tap_area.input_pickable = false
	_bell_timer = Timer.new()
	_bell_timer.one_shot = false
	_bell_timer.wait_time = maxf(0.4, bell_repeat_seconds)
	_bell_timer.timeout.connect(_play_bells_if_visible)
	add_child(_bell_timer)
	_bell_player = AudioStreamPlayer.new()
	_bell_player.name = "BellPlayer"
	_bell_player.bus = _get_sfx_bus_name()
	add_child(_bell_player)
	_tap_player = AudioStreamPlayer.new()
	_tap_player.name = "TapPlayer"
	_tap_player.bus = _get_sfx_bus_name()
	add_child(_tap_player)
	_greeting_player = AudioStreamPlayer.new()
	_greeting_player.name = "SantaGreetingPlayer"
	_greeting_player.bus = _get_voice_over_bus_name()
	add_child(_greeting_player)
	set_process(false)


func _process(delta: float) -> void:
	if not _enabled:
		return
	if _active_tween != null and _active_tween.is_valid():
		return
	_time_until_flight -= delta
	if _time_until_flight <= 0.0:
		_start_flight()


func get_runtime_state() -> Dictionary:
	return {
		"enabled": _enabled,
		"time_until_flight": maxf(0.0, _time_until_flight),
		"active": _active_tween != null and _active_tween.is_valid(),
		"sleigh": _get_sprite_state(_sleigh),
	}


func apply_runtime_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
	if _tap_bounce_tween != null and _tap_bounce_tween.is_valid():
		_tap_bounce_tween.kill()
	_tap_bounce_tween = null
	_time_until_flight = maxf(0.0, float(state.get("time_until_flight", _time_until_flight)))
	_apply_sprite_state(_sleigh, state.get("sleigh", {}))
	var enabled := bool(state.get("enabled", _enabled))
	if not enabled:
		set_enabled(false)
		return
	_enabled = true
	set_process(true)
	visible = true
	if bool(state.get("active", false)) and _sleigh != null and _sleigh.visible:
		_start_bells()
		_resume_flight_from_restored_position()


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	set_process(enabled)
	visible = enabled
	if not enabled:
		_finish_flight(false)
		return
	if _tap_area != null:
		_tap_area.input_pickable = true


func _start_flight() -> void:
	if _sleigh == null:
		return

	var left_to_right := _rng.randf() < 0.5
	var start_x := left_start_x if left_to_right else right_end_x
	var end_x := right_end_x if left_to_right else left_start_x
	var direction_scale := -1.0 if left_to_right else 1.0
	var duration := _random_range(flight_duration_range)

	_sleigh.visible = true
	_sleigh.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_sleigh.position = Vector2(start_x, lane_y + _rng.randf_range(-18.0, 20.0))
	_sleigh.scale = Vector2(0.36 * direction_scale, 0.36)
	_sleigh.rotation = 0.0
	if _tap_area != null:
		_tap_area.input_pickable = true
	_start_bells()

	_active_tween = create_tween()
	_active_tween.tween_property(_sleigh, "modulate:a", 1.0, 0.45)
	var middle_y := lane_y + _rng.randf_range(-bob_amount, bob_amount)
	_active_tween.parallel().tween_property(_sleigh, "position", Vector2(lerpf(start_x, end_x, 0.34), middle_y), duration * 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tween.tween_property(_sleigh, "position", Vector2(lerpf(start_x, end_x, 0.68), lane_y - middle_y + lane_y), duration * 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tween.tween_property(_sleigh, "position", Vector2(end_x, lane_y + _rng.randf_range(-18.0, 20.0)), duration * 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tween.parallel().tween_property(_sleigh, "rotation", 0.04 * direction_scale, duration * 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tween.tween_property(_sleigh, "rotation", -0.035 * direction_scale, duration * 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tween.tween_property(_sleigh, "rotation", 0.0, duration * 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tween.parallel().tween_callback(_drop_sparkles).set_delay(duration * 0.15)
	_active_tween.parallel().tween_callback(_drop_sparkles).set_delay(duration * 0.42)
	_active_tween.parallel().tween_callback(_drop_sparkles).set_delay(duration * 0.68)
	_active_tween.parallel().tween_callback(_stop_bells).set_delay(maxf(0.2, duration - 1.2))
	_active_tween.tween_property(_sleigh, "modulate:a", 0.0, 0.45)
	_active_tween.tween_callback(func() -> void:
		_finish_flight(true)
	)


func _drop_sparkles() -> void:
	if _sleigh == null or sparkle_texture == null or not is_instance_valid(_sleigh):
		return
	for index in sparkle_count:
		var sparkle := Sprite2D.new()
		sparkle.texture = sparkle_texture
		sparkle.z_index = 20
		sparkle.position = _sleigh.position + Vector2(_rng.randf_range(-64.0, 48.0), _rng.randf_range(22.0, 54.0))
		sparkle.scale = Vector2.ONE * _rng.randf_range(0.13, 0.22)
		sparkle.modulate.a = 0.82
		add_child(sparkle)
		var tween := sparkle.create_tween()
		tween.tween_property(sparkle, "position", sparkle.position + Vector2(_rng.randf_range(-18.0, 18.0), _rng.randf_range(34.0, 70.0)), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(sparkle, "modulate:a", 0.0, 1.1)
		tween.parallel().tween_property(sparkle, "scale", sparkle.scale * 0.45, 1.1)
		tween.tween_callback(sparkle.queue_free)


func _finish_flight(schedule_next: bool) -> void:
	if _active_tween != null and _active_tween.is_valid() and not schedule_next:
		_active_tween.kill()
	_active_tween = null
	if _tap_bounce_tween != null and _tap_bounce_tween.is_valid():
		_tap_bounce_tween.kill()
	_tap_bounce_tween = null
	if _sleigh != null:
		_sleigh.visible = false
		_sleigh.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_sleigh.rotation = 0.0
	if _tap_area != null:
		_tap_area.input_pickable = false
	_stop_bells()
	if schedule_next:
		_time_until_flight = _random_range(interval_range)


func _resume_flight_from_restored_position() -> void:
	if _sleigh == null:
		return
	_sleigh.modulate = Color.WHITE
	var moving_right := _sleigh.scale.x < 0.0
	var end_x := right_end_x if moving_right else left_start_x
	var duration := _get_remaining_flight_duration(end_x)
	_active_tween = create_tween()
	_active_tween.tween_property(_sleigh, "position", Vector2(end_x, _sleigh.position.y), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tween.parallel().tween_property(_sleigh, "rotation", 0.0, duration * 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tween.parallel().tween_callback(_drop_sparkles).set_delay(duration * 0.35)
	_active_tween.parallel().tween_callback(_stop_bells).set_delay(maxf(0.2, duration - 0.8))
	_active_tween.tween_property(_sleigh, "modulate:a", 0.0, 0.35)
	_active_tween.tween_callback(func() -> void:
		_finish_flight(true)
	)


func _get_remaining_flight_duration(end_x: float) -> float:
	var full_distance := absf(right_end_x - left_start_x)
	if full_distance <= 0.0 or _sleigh == null:
		return _random_range(flight_duration_range)
	var average_duration := (minf(flight_duration_range.x, flight_duration_range.y) + maxf(flight_duration_range.x, flight_duration_range.y)) * 0.5
	var remaining_ratio := clampf(absf(end_x - _sleigh.position.x) / full_distance, 0.0, 1.0)
	return clampf(average_duration * remaining_ratio, 0.45, average_duration)


func _get_sprite_state(sprite: Sprite2D) -> Dictionary:
	if sprite == null:
		return {}
	return {
		"visible": sprite.visible,
		"position": _vector_to_dict(sprite.position),
		"scale": _vector_to_dict(sprite.scale),
		"rotation": sprite.rotation,
		"alpha": sprite.modulate.a,
	}


func _apply_sprite_state(sprite: Sprite2D, raw_state: Variant) -> void:
	if sprite == null or not (raw_state is Dictionary):
		return
	var state := raw_state as Dictionary
	sprite.visible = bool(state.get("visible", sprite.visible))
	sprite.position = _dict_to_vector(state.get("position", {}), sprite.position)
	sprite.scale = _dict_to_vector(state.get("scale", {}), sprite.scale)
	sprite.rotation = float(state.get("rotation", sprite.rotation))
	var modulate := sprite.modulate
	modulate.a = clampf(float(state.get("alpha", modulate.a)), 0.0, 1.0)
	sprite.modulate = modulate


func _vector_to_dict(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}


func _dict_to_vector(raw_value: Variant, fallback: Vector2) -> Vector2:
	if not (raw_value is Dictionary):
		return fallback
	var value := raw_value as Dictionary
	return Vector2(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)))


func _start_bells() -> void:
	_bell_jingle_count = 0
	_bell_sequence_started_msec = Time.get_ticks_msec()
	_play_bells_if_visible()
	if _bell_timer == null:
		return
	if _bell_jingle_count >= max_bell_jingles:
		return
	_bell_timer.wait_time = maxf(0.4, bell_repeat_seconds)
	_bell_timer.start()


func _stop_bells() -> void:
	if _bell_timer != null:
		_bell_timer.stop()
	if _bell_player != null:
		_bell_player.stop()
	_bell_jingle_count = 0
	_bell_sequence_started_msec = 0


func _play_tap_sound() -> void:
	var now_msec := Time.get_ticks_msec()
	var cooldown_msec := int(maxf(0.0, tap_audio_cooldown_seconds) * 1000.0)
	if now_msec - _last_tap_audio_msec < cooldown_msec:
		return
	_last_tap_audio_msec = now_msec

	if _play_santa_greeting():
		return

	var sound := _pick_ho_ho_sound()
	if sound == null:
		return
	if _tap_player == null or not is_instance_valid(_tap_player):
		_tap_player = AudioStreamPlayer.new()
		_tap_player.name = "TapPlayer"
		add_child(_tap_player)
	_tap_player.stop()
	_tap_player.stream = sound
	_tap_player.bus = _get_sfx_bus_name()
	_tap_player.volume_db = -5.0
	_tap_player.play()


func _play_santa_greeting() -> bool:
	if _greeting_player == null or not MusicManager.is_voice_over_enabled():
		return false
	var locale := _resolve_santa_locale()
	if locale.is_empty():
		return false
	if _greeting_player.playing:
		return true
	var path := _get_santa_greeting_path(locale)
	if path.is_empty():
		return false
	var stream := ResourceLoader.load(path) as AudioStream
	if stream == null:
		return false
	_greeting_player.stop()
	_greeting_player.stream = stream
	_greeting_player.volume_db = 0.0
	_greeting_player.play()
	return true


func _resolve_santa_locale() -> String:
	var locale := TranslationServer.get_locale()
	var normalized := locale.replace("_", "-")
	if normalized == "en" or normalized.begins_with("en-"):
		return "en-US"
	return ""


func _get_santa_greeting_path(locale: String) -> String:
	if locale.is_empty():
		return ""
	var candidate_paths := [
		"res://sounds/voice_over/locales/%s/santa_full_greeting.ogg" % locale,
	]
	for path in candidate_paths:
		if ResourceLoader.exists(path):
			return path
	return ""


func _play_bells_if_visible() -> void:
	if _sleigh == null or not _sleigh.visible:
		return
	if _bell_player == null or bell_sound == null:
		return
	if _bell_jingle_count >= max_bell_jingles:
		if _bell_timer != null:
			_bell_timer.stop()
		return
	if _bell_sequence_started_msec > 0:
		var elapsed := float(Time.get_ticks_msec() - _bell_sequence_started_msec) / 1000.0
		if elapsed > bell_sequence_max_seconds:
			if _bell_timer != null:
				_bell_timer.stop()
			return
	_bell_player.stop()
	_bell_player.stream = bell_sound
	_bell_player.bus = _get_sfx_bus_name()
	_bell_player.volume_db = -7.0
	_bell_player.play()
	_bell_jingle_count += 1


func _get_sfx_bus_name() -> String:
	var tree := get_tree()
	if tree == null:
		return "Master"
	var music_manager := tree.root.get_node_or_null("MusicManager")
	if music_manager != null and music_manager.has_method("get_sfx_bus_name"):
		return String(music_manager.call("get_sfx_bus_name"))
	return "Master"


func _get_voice_over_bus_name() -> String:
	var tree := get_tree()
	if tree == null:
		return "Master"
	var music_manager := tree.root.get_node_or_null("MusicManager")
	if music_manager != null and music_manager.has_method("get_voice_over_bus_name"):
		return String(music_manager.call("get_voice_over_bus_name"))
	return "Master"


func _random_range(range: Vector2) -> float:
	return _rng.randf_range(minf(range.x, range.y), maxf(range.x, range.y))


func handle_tap() -> void:
	if _sleigh == null or not _sleigh.visible:
		return
	get_viewport().set_input_as_handled()
	_stop_bells()
	_play_tap_sound()
	_drop_sparkles()
	if _tap_bounce_tween != null and _tap_bounce_tween.is_valid():
		_tap_bounce_tween.kill()
	var original_position := _sleigh.position
	_tap_bounce_tween = _sleigh.create_tween()
	_tap_bounce_tween.tween_property(_sleigh, "position:y", original_position.y - 34.0, 0.11).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tap_bounce_tween.tween_property(_sleigh, "position:y", original_position.y, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _pick_ho_ho_sound() -> AudioStream:
	var valid_sounds: Array[AudioStream] = []
	for sound in ho_ho_sounds:
		if sound != null:
			valid_sounds.append(sound)
	if valid_sounds.is_empty():
		return ho_ho_sound
	return valid_sounds[_rng.randi_range(0, valid_sounds.size() - 1)]
