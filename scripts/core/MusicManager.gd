extends Node

const SAVE_PATH := "user://farm_chore_friends_audio_settings.json"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const VOICE_OVER_BUS := "VoiceOver"
const MASTER_BUS := "Master"

@export var farmyard_music: AudioStream
@export var chore_music: AudioStream
@export var soundtrack_playlist: Array[AudioStream] = []
@export var farmyard_playlist: Array[AudioStream] = []
@export var chore_playlist: Array[AudioStream] = []
@export var spring_playlist: Array[AudioStream] = []
@export var summer_playlist: Array[AudioStream] = []
@export var fall_playlist: Array[AudioStream] = []
@export var winter_playlist: Array[AudioStream] = []
@export var music_volume_db := -22.0
@export var fade_duration := 0.8
@export var music_enabled := true
@export var keep_music_continuous_between_scenes := true
@export_range(0.0, 1.0, 0.01) var master_volume := 1.0
@export_range(0.0, 1.0, 0.01) var music_volume := 0.75
@export_range(0.0, 1.0, 0.01) var sfx_volume := 1.0
@export var voice_over_enabled := true
@export_range(0.0, 1.0, 0.01) var voice_over_volume := 0.85
@export_range(0.0, 1.0, 0.01) var last_master_volume := 1.0
@export_range(0.0, 1.0, 0.01) var last_music_volume := 0.75
@export_range(0.0, 1.0, 0.01) var last_sfx_volume := 1.0
@export_range(0.0, 1.0, 0.01) var last_voice_over_volume := 0.85

@onready var _player: AudioStreamPlayer = $MusicPlayer

var _current_stream: AudioStream
var _fade_tween: Tween
var _active_playlist: Array[AudioStream] = []
var _playlist_index := 0
var _headless_mode := false
var _active_context := "farmyard"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	load_audio_settings()
	_apply_audio_settings()
	_player.bus = MUSIC_BUS
	_player.finished.connect(_restart_current_track)
	if FarmState != null and not FarmState.season_changed.is_connected(_on_season_changed):
		FarmState.season_changed.connect(_on_season_changed)
	if DisplayServer.get_name() == "headless":
		_headless_mode = true
		return
	play_farmyard_music()


func _exit_tree() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	if _player != null:
		_player.stop()
		_player.stream = null
	if FarmState != null and FarmState.season_changed.is_connected(_on_season_changed):
		FarmState.season_changed.disconnect(_on_season_changed)
	_current_stream = null


func play_farmyard_music() -> void:
	_active_context = "farmyard"
	_request_music(farmyard_music, _get_farmyard_playlist())


func play_chore_music() -> void:
	_active_context = "chore"
	_request_music(chore_music, _get_chore_playlist())


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	_apply_audio_settings()
	save_audio_settings()
	if music_enabled:
		if _player.playing and _current_stream != null:
			return
		var resume_stream := _current_stream if _current_stream != null else farmyard_music
		_play_track(resume_stream, true, _active_playlist)
	else:
		_stop_music()


func is_music_enabled() -> bool:
	return music_enabled


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	if master_volume > 0.001:
		last_master_volume = master_volume
	_apply_audio_settings()
	save_audio_settings()


func get_master_volume() -> float:
	return master_volume


func toggle_master_muted() -> void:
	if master_volume > 0.001:
		last_master_volume = master_volume
		master_volume = 0.0
	else:
		master_volume = clampf(last_master_volume, 0.05, 1.0)
	_apply_audio_settings()
	save_audio_settings()


func is_master_muted() -> bool:
	return master_volume <= 0.001


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if music_volume > 0.001:
		last_music_volume = music_volume
		music_enabled = true
	else:
		music_enabled = false
	_apply_audio_settings()
	save_audio_settings()


func get_music_volume() -> float:
	return music_volume


func toggle_music_muted() -> void:
	if music_volume > 0.001 and music_enabled:
		last_music_volume = music_volume
		music_volume = 0.0
		music_enabled = false
	else:
		music_volume = clampf(last_music_volume, 0.05, 1.0)
		music_enabled = true
	_apply_audio_settings()
	save_audio_settings()


func is_music_muted() -> bool:
	return not music_enabled or music_volume <= 0.001


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	if sfx_volume > 0.001:
		last_sfx_volume = sfx_volume
	_apply_audio_settings()
	save_audio_settings()


func get_sfx_volume() -> float:
	return sfx_volume


func toggle_sfx_muted() -> void:
	if sfx_volume > 0.001:
		last_sfx_volume = sfx_volume
		sfx_volume = 0.0
	else:
		sfx_volume = clampf(last_sfx_volume, 0.05, 1.0)
	_apply_audio_settings()
	save_audio_settings()


func is_sfx_muted() -> bool:
	return sfx_volume <= 0.001


func set_voice_over_enabled(enabled: bool) -> void:
	voice_over_enabled = enabled
	_apply_audio_settings()
	save_audio_settings()
	if not voice_over_enabled and VoiceOverManager != null:
		VoiceOverManager.stop()


func is_voice_over_enabled() -> bool:
	return voice_over_enabled


func set_voice_over_volume(value: float) -> void:
	voice_over_volume = clampf(value, 0.0, 1.0)
	if voice_over_volume > 0.001:
		last_voice_over_volume = voice_over_volume
		voice_over_enabled = true
	else:
		voice_over_enabled = false
	_apply_audio_settings()
	save_audio_settings()


func get_voice_over_volume() -> float:
	return voice_over_volume


func toggle_voice_over_muted() -> void:
	if voice_over_volume > 0.001 and voice_over_enabled:
		last_voice_over_volume = voice_over_volume
		voice_over_volume = 0.0
		voice_over_enabled = false
		if VoiceOverManager != null:
			VoiceOverManager.stop()
	else:
		voice_over_volume = clampf(last_voice_over_volume, 0.05, 1.0)
		voice_over_enabled = true
	_apply_audio_settings()
	save_audio_settings()


func is_voice_over_muted() -> bool:
	return not voice_over_enabled or voice_over_volume <= 0.001


func get_sfx_bus_name() -> StringName:
	return SFX_BUS


func get_voice_over_bus_name() -> StringName:
	return VOICE_OVER_BUS


func save_audio_settings() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	var data := {
		"music_enabled": music_enabled,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"voice_over_enabled": voice_over_enabled,
		"voice_over_volume": voice_over_volume,
		"last_master_volume": last_master_volume,
		"last_music_volume": last_music_volume,
		"last_sfx_volume": last_sfx_volume,
		"last_voice_over_volume": last_voice_over_volume,
	}
	file.store_string(JSON.stringify(data, "\t"))


func load_audio_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	var data := parsed as Dictionary
	music_enabled = _read_bool(data.get("music_enabled", music_enabled), music_enabled)
	master_volume = clampf(_read_float(data.get("master_volume", master_volume), master_volume), 0.0, 1.0)
	music_volume = clampf(_read_float(data.get("music_volume", music_volume), music_volume), 0.0, 1.0)
	sfx_volume = clampf(_read_float(data.get("sfx_volume", data.get("sound_effects_volume", sfx_volume)), sfx_volume), 0.0, 1.0)
	voice_over_enabled = _read_bool(data.get("voice_over_enabled", voice_over_enabled), voice_over_enabled)
	voice_over_volume = clampf(_read_float(data.get("voice_over_volume", voice_over_volume), voice_over_volume), 0.0, 1.0)
	last_master_volume = clampf(_read_float(data.get("last_master_volume", maxf(master_volume, last_master_volume)), last_master_volume), 0.05, 1.0)
	last_music_volume = clampf(_read_float(data.get("last_music_volume", maxf(music_volume, last_music_volume)), last_music_volume), 0.05, 1.0)
	last_sfx_volume = clampf(_read_float(data.get("last_sfx_volume", maxf(sfx_volume, last_sfx_volume)), last_sfx_volume), 0.05, 1.0)
	last_voice_over_volume = clampf(_read_float(data.get("last_voice_over_volume", maxf(voice_over_volume, last_voice_over_volume)), last_voice_over_volume), 0.05, 1.0)


func _request_music(fallback_stream: AudioStream, playlist: Array[AudioStream] = []) -> void:
	if _headless_mode:
		return
	var clean_playlist := _clean_playlist(playlist)
	_active_playlist = clean_playlist
	if keep_music_continuous_between_scenes and _player.playing:
		_current_stream = _player.stream
		return

	var stream := _get_requested_stream(fallback_stream, clean_playlist)
	_play_track(stream, false, clean_playlist)


func _get_requested_stream(fallback_stream: AudioStream, playlist: Array[AudioStream]) -> AudioStream:
	if not playlist.is_empty():
		if _player != null and _player.playing:
			var current_index := playlist.find(_player.stream)
			if current_index != -1:
				_playlist_index = current_index
				return playlist[current_index]
		_playlist_index = _get_next_playlist_index(playlist)
		return playlist[_playlist_index]
	return fallback_stream


func _play_track(stream: AudioStream, force := false, playlist: Array[AudioStream] = []) -> void:
	if stream == null:
		return
	if not music_enabled:
		if _current_stream == null:
			_current_stream = stream
		return

	var clean_playlist := _clean_playlist(playlist)
	var can_continue_current := keep_music_continuous_between_scenes and _player.playing and not force
	if can_continue_current:
		if clean_playlist.is_empty() and _player.stream == stream:
			return
		if not clean_playlist.is_empty() and clean_playlist.has(_player.stream):
			_active_playlist = clean_playlist
			_current_stream = _player.stream
			return
	if _player.stream == stream and _player.playing:
		return

	_current_stream = stream
	_active_playlist = clean_playlist

	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	if _player.playing and fade_duration > 0.0:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", -48.0, fade_duration * 0.5)
		_fade_tween.tween_callback(_start_current_track)
	else:
		_start_current_track()


func _start_current_track() -> void:
	if _current_stream == null or not music_enabled:
		return

	_player.stop()
	_player.stream = _current_stream
	_player.volume_db = -48.0 if fade_duration > 0.0 else _get_music_player_volume_db()
	_player.play()

	if fade_duration > 0.0:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", _get_music_player_volume_db(), fade_duration * 0.5)
	else:
		_player.volume_db = _get_music_player_volume_db()


func _restart_current_track() -> void:
	if not music_enabled:
		return
	if _active_playlist.size() > 1:
		_playlist_index = (_playlist_index + 1) % _active_playlist.size()
		_play_track(_active_playlist[_playlist_index], true, _active_playlist)
	elif _current_stream != null:
		_play_track(_current_stream, true)


func _on_season_changed(_new_season: String) -> void:
	if _headless_mode:
		return
	if _active_context == "chore":
		_request_music(chore_music, _get_chore_playlist())
	else:
		_request_music(farmyard_music, _get_farmyard_playlist())


func _get_farmyard_playlist() -> Array[AudioStream]:
	var seasonal_playlist := _get_seasonal_playlist()
	if not seasonal_playlist.is_empty():
		return seasonal_playlist
	if not farmyard_playlist.is_empty():
		return farmyard_playlist
	return soundtrack_playlist


func _get_chore_playlist() -> Array[AudioStream]:
	var seasonal_playlist := _get_seasonal_playlist()
	if not seasonal_playlist.is_empty():
		return seasonal_playlist
	if not chore_playlist.is_empty():
		return chore_playlist
	return soundtrack_playlist


func _get_seasonal_playlist() -> Array[AudioStream]:
	if FarmState == null:
		return []
	match FarmState.current_season:
		"spring":
			return _clean_playlist(spring_playlist)
		"summer":
			return _clean_playlist(summer_playlist)
		"fall":
			return _clean_playlist(fall_playlist)
		"winter":
			return _clean_playlist(winter_playlist)
		_:
			return []


func _clean_playlist(playlist: Array[AudioStream]) -> Array[AudioStream]:
	var clean: Array[AudioStream] = []
	for stream in playlist:
		if stream != null:
			clean.append(stream)
	return clean


func _get_next_playlist_index(playlist: Array[AudioStream]) -> int:
	if playlist.is_empty():
		return -1
	if playlist.size() == 1:
		return 0
	var next_index := randi_range(0, playlist.size() - 1)
	if _current_stream != null:
		var guard := 0
		while playlist[next_index] == _current_stream and guard < 8:
			next_index = randi_range(0, playlist.size() - 1)
			guard += 1
	return next_index


func _stop_music() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_player.stop()


func _ensure_audio_buses() -> void:
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	_ensure_bus(VOICE_OVER_BUS)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus(AudioServer.get_bus_count())
	var bus_index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, MASTER_BUS)


func _apply_audio_settings() -> void:
	_apply_bus_volume(MASTER_BUS, master_volume, true)
	_apply_bus_volume(SFX_BUS, sfx_volume, true)
	_apply_bus_volume(VOICE_OVER_BUS, voice_over_volume, voice_over_enabled)
	_apply_bus_volume(MUSIC_BUS, music_volume, music_enabled)
	if _player != null:
		_player.volume_db = _get_music_player_volume_db()


func _apply_bus_volume(bus_name: String, volume: float, enabled: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	var clamped_volume := clampf(volume, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, not enabled or clamped_volume <= 0.001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(clamped_volume, 0.001)))


func _get_music_player_volume_db() -> float:
	return music_volume_db


func _read_bool(value: Variant, default_value: bool) -> bool:
	if value is bool:
		return value
	if value is int or value is float:
		return float(value) != 0.0
	if value is String or value is StringName:
		var normalized := str(value).strip_edges().to_lower()
		if ["true", "yes", "1", "on"].has(normalized):
			return true
		if ["false", "no", "0", "off", ""].has(normalized):
			return false
	return default_value


func _read_float(value: Variant, default_value: float) -> float:
	if value is int or value is float:
		return float(value)
	if value is String or value is StringName:
		var text := str(value).strip_edges()
		if text.is_valid_float():
			return float(text)
	return default_value
