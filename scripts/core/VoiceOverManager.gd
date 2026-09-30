extends Node

signal voice_over_unavailable(text: String, prompt_key: String)

@export var preferred_language := ""
@export var tts_pitch := 1.0
@export var tts_rate := 0.92
@export var repeat_cooldown_seconds := 3.0
@export var hint_cooldown_seconds := 8.0
@export var recorded_prompt_catalog_path := "res://sounds/voice_over/voice_lines.json"
@export var use_recorded_prompts := true
@export var use_tts_fallback := true
@export var recorded_prompt_streams: Dictionary = {}

var _voice := ""
var _utterance_id := 1
var _last_spoken_msec_by_key: Dictionary = {}
var _spoken_hint_keys: Dictionary = {}
var _localized_prompt_paths: Dictionary = {}
var _localized_prompt_aliases: Dictionary = {}
var _localized_prompt_texts: Dictionary = {}
var _shared_prompt_paths: Dictionary = {}
var _shared_prompt_aliases: Dictionary = {}
var _shared_prompt_texts: Dictionary = {}
var _recorded_prompt_paths: Dictionary = {}
var _recorded_prompt_aliases: Dictionary = {}
var _recorded_stream_cache: Dictionary = {}
var _recorded_player: AudioStreamPlayer
var _tts_available := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tts_available = DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH)
	_recorded_player = AudioStreamPlayer.new()
	_recorded_player.bus = MusicManager.get_voice_over_bus_name()
	add_child(_recorded_player)
	if GameSettings != null and GameSettings.has_signal("locale_changed"):
		if not GameSettings.locale_changed.is_connected(_on_locale_changed):
			GameSettings.locale_changed.connect(_on_locale_changed)
	if GameSettings != null and GameSettings.has_signal("tts_locale_changed"):
		if not GameSettings.tts_locale_changed.is_connected(_on_tts_locale_changed):
			GameSettings.tts_locale_changed.connect(_on_tts_locale_changed)
	_on_locale_changed(GameSettings.get_active_locale() if GameSettings != null else "")


func speak_hint(text: String, prompt_key: String) -> void:
	if prompt_key.is_empty():
		prompt_key = _clean_text(text)
	if _spoken_hint_keys.has(prompt_key):
		return
	if speak(text, prompt_key, true, 0.0):
		_spoken_hint_keys[prompt_key] = true


func speak_completion(text: String, prompt_key: String = "") -> void:
	if prompt_key.is_empty():
		prompt_key = "completion_%s" % _clean_text(text)
	speak(text, prompt_key, true, 0.0)


func reset_hint(prompt_key: String) -> void:
	_spoken_hint_keys.erase(prompt_key)


func reset_hints_with_prefix(prefix: String) -> void:
	for key in _spoken_hint_keys.keys():
		if String(key).begins_with(prefix):
			_spoken_hint_keys.erase(key)


func speak(text: String, prompt_key: String = "", interrupt := true, cooldown_seconds := -1.0) -> bool:
	if not MusicManager.is_voice_over_enabled():
		return false
	var cleaned_text := _clean_text(text)
	if cleaned_text.is_empty():
		return false

	var key := prompt_key if not prompt_key.is_empty() else cleaned_text
	var cooldown := repeat_cooldown_seconds if cooldown_seconds < 0.0 else cooldown_seconds
	if cooldown > 0.0 and _is_on_cooldown(key, cooldown):
		return false
	_last_spoken_msec_by_key[key] = Time.get_ticks_msec()

	if use_recorded_prompts and _play_recorded_prompt(key, interrupt):
		return true

	if use_tts_fallback and _tts_available:
		return _speak_with_tts(cleaned_text, interrupt)

	if not use_recorded_prompts and _play_recorded_prompt(key, interrupt):
		return true

	emit_signal("voice_over_unavailable", cleaned_text, key)
	return false


func stop() -> void:
	if _tts_available:
		DisplayServer.tts_stop()
	if _recorded_player != null:
		_recorded_player.stop()


func _speak_with_tts(text: String, interrupt: bool) -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	if interrupt:
		if _recorded_player != null:
			_recorded_player.stop()
		DisplayServer.tts_stop()
	_utterance_id += 1
	var volume := roundi(clampf(MusicManager.get_master_volume() * MusicManager.get_voice_over_volume(), 0.0, 1.0) * 100.0)
	if volume <= 0:
		return false
	DisplayServer.tts_speak(text, _voice, volume, tts_pitch, tts_rate, _utterance_id, interrupt)
	return true


func _play_recorded_prompt(prompt_key: String, interrupt: bool) -> bool:
	if _recorded_player == null:
		return false
	var resolved_key := _resolve_prompt_key(prompt_key)
	var stream := _get_recorded_stream(resolved_key)
	if stream == null:
		return false
	if interrupt:
		if _tts_available:
			DisplayServer.tts_stop()
		_recorded_player.stop()
	_recorded_player.stream = stream
	# The VoiceOver audio bus owns volume, so recorded clips do not apply it twice.
	_recorded_player.volume_db = 0.0
	_recorded_player.play()
	return true


func _get_recorded_stream(prompt_key: String) -> AudioStream:
	if prompt_key.is_empty():
		return null
	if recorded_prompt_streams.has(prompt_key):
		return recorded_prompt_streams[prompt_key] as AudioStream
	var localized_path := _get_recorded_prompt_path(prompt_key, true)
	var stream := _get_recorded_stream_from_path(localized_path)
	if stream != null:
		return stream
	var shared_path := _get_recorded_prompt_path(prompt_key, false)
	stream = _get_recorded_stream_from_path(shared_path)
	if stream != null:
		return stream
	return _get_recorded_stream_by_convention(prompt_key)


func _resolve_prompt_key(prompt_key: String) -> String:
	var localized_key := _resolve_prompt_key_in_catalog(prompt_key, _localized_prompt_paths, _localized_prompt_aliases)
	if not localized_key.is_empty():
		return localized_key
	var shared_key := _resolve_prompt_key_in_catalog(prompt_key, _shared_prompt_paths, _shared_prompt_aliases)
	if not shared_key.is_empty():
		return shared_key

	var automatic_alias := _get_automatic_alias(prompt_key)
	if not automatic_alias.is_empty():
		localized_key = _resolve_prompt_key_in_catalog(automatic_alias, _localized_prompt_paths, _localized_prompt_aliases)
		if not localized_key.is_empty():
			return localized_key
		shared_key = _resolve_prompt_key_in_catalog(automatic_alias, _shared_prompt_paths, _shared_prompt_aliases)
		if not shared_key.is_empty():
			return shared_key
	return prompt_key


func _has_recorded_prompt(prompt_key: String) -> bool:
	return recorded_prompt_streams.has(prompt_key) or _localized_prompt_paths.has(prompt_key) or _shared_prompt_paths.has(prompt_key)


func _get_automatic_alias(prompt_key: String) -> String:
	var parts := prompt_key.split("_")
	if parts.size() < 4:
		return ""
	var strength := String(parts[parts.size() - 1])
	if not ["gentle", "strong"].has(strength):
		return ""
	if prompt_key.begins_with("feeding_hint_"):
		return "feeding_hint_%s" % strength
	if prompt_key.begins_with("brushing_hint_"):
		return "brushing_hint_%s" % strength
	return ""


func _load_recorded_prompt_catalog() -> void:
	_localized_prompt_paths.clear()
	_localized_prompt_aliases.clear()
	_localized_prompt_texts.clear()
	_shared_prompt_paths.clear()
	_shared_prompt_aliases.clear()
	_shared_prompt_texts.clear()
	_recorded_prompt_paths.clear()
	_recorded_prompt_aliases.clear()
	_recorded_stream_cache.clear()

	_load_prompt_catalog_into(_get_localized_recorded_prompt_catalog_path(), _localized_prompt_paths, _localized_prompt_aliases, _localized_prompt_texts)
	_load_prompt_catalog_into(recorded_prompt_catalog_path, _shared_prompt_paths, _shared_prompt_aliases, _shared_prompt_texts)
	_recorded_prompt_paths = _localized_prompt_paths
	_recorded_prompt_aliases = _localized_prompt_aliases


func _select_voice() -> String:
	var language_code := _get_preferred_language_code()
	var voices := DisplayServer.tts_get_voices_for_language(language_code)
	if voices.size() > 0:
		return String(voices[0])
	var all_voices := DisplayServer.tts_get_voices()
	for voice_data in all_voices:
		if voice_data.has("id"):
			return String(voice_data["id"])
		if voice_data.has("name"):
			return String(voice_data["name"])
	return ""


func _on_locale_changed(_locale: String) -> void:
	if _tts_available:
		_voice = _select_voice()
	_load_recorded_prompt_catalog()


func _on_tts_locale_changed(_locale: String) -> void:
	if _tts_available:
		_voice = _select_voice()
	_load_recorded_prompt_catalog()


func _get_preferred_language_code() -> String:
	var code := preferred_language.strip_edges()
	if not code.is_empty():
		return code
	if GameSettings != null:
		return GameSettings.get_effective_tts_locale()
	return TranslationServer.get_locale()


func _get_recorded_prompt_catalog_path() -> String:
	return _get_localized_recorded_prompt_catalog_path()


func _get_localized_recorded_prompt_catalog_path() -> String:
	var locale_code := _get_preferred_language_code()
	if locale_code.is_empty():
		locale_code = TranslationServer.get_locale()
	var localized_paths := [
		"res://sounds/voice_over/locales/%s/voice_lines.json" % locale_code,
		"res://sounds/voice_over/locales/%s.json" % locale_code,
	]
	for path in localized_paths:
		if FileAccess.file_exists(path):
			return path
	return recorded_prompt_catalog_path


func _load_prompt_catalog_into(catalog_path: String, paths: Dictionary, aliases: Dictionary, texts: Dictionary) -> void:
	paths.clear()
	aliases.clear()
	texts.clear()
	if catalog_path.is_empty() or not FileAccess.file_exists(catalog_path):
		return
	var file := FileAccess.open(catalog_path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	var catalog := parsed as Dictionary

	var lines = catalog.get("lines", [])
	if lines is Array:
		for line in lines:
			if not (line is Dictionary):
				continue
			var line_data := line as Dictionary
			var key := str(line_data.get("key", "")).strip_edges()
			var path := str(line_data.get("path", "")).strip_edges()
			if key.is_empty() or path.is_empty():
				continue
			paths[key] = path
			texts[key] = str(line_data.get("text", "")).strip_edges()

	var catalog_aliases = catalog.get("aliases", {})
	if catalog_aliases is Dictionary:
		for alias_key in catalog_aliases.keys():
			var target_key := str(catalog_aliases[alias_key]).strip_edges()
			if target_key.is_empty():
				continue
			aliases[str(alias_key)] = target_key


func _resolve_prompt_key_in_catalog(prompt_key: String, paths: Dictionary, aliases: Dictionary) -> String:
	var current_key := prompt_key
	var seen_keys: Dictionary = {}
	for _index in range(8):
		if paths.has(current_key):
			return current_key
		if not aliases.has(current_key) or seen_keys.has(current_key):
			break
		seen_keys[current_key] = true
		current_key = str(aliases[current_key])
	return ""


func _get_recorded_prompt_path(prompt_key: String, use_localized_catalog: bool) -> String:
	var paths := _localized_prompt_paths if use_localized_catalog else _shared_prompt_paths
	if not paths.has(prompt_key):
		return ""
	var path := str(paths[prompt_key]).strip_edges()
	if use_localized_catalog:
		path = _resolve_localized_prompt_path(path)
	return path


func _resolve_localized_prompt_path(path: String) -> String:
	if path.is_empty():
		return ""
	var locale_code := _get_preferred_language_code()
	if locale_code.is_empty() or locale_code == "en":
		return path
	var localized_prefix := "res://sounds/voice_over/locales/%s/" % locale_code
	if path.begins_with(localized_prefix):
		return path
	var shared_prefix := "res://sounds/voice_over/"
	if path.begins_with(shared_prefix) and not path.begins_with("res://sounds/voice_over/locales/"):
		var localized_path := localized_prefix + path.get_file()
		if ResourceLoader.exists(localized_path) or FileAccess.file_exists(localized_path):
			return localized_path
	return path


func _get_recorded_stream_from_path(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if _recorded_stream_cache.has(path):
		return _recorded_stream_cache[path] as AudioStream
	if not ResourceLoader.exists(path):
		return null
	var stream := ResourceLoader.load(path) as AudioStream
	if stream != null:
		_recorded_stream_cache[path] = stream
	return stream


func _get_recorded_stream_by_convention(prompt_key: String) -> AudioStream:
	var locale_code := _get_preferred_language_code()
	if not locale_code.is_empty() and locale_code != "en":
		var localized_base_path := "res://sounds/voice_over/locales/%s/%s" % [locale_code, prompt_key]
		for localized_ext in [".wav", ".ogg"]:
			var localized_stream := _get_recorded_stream_from_path(localized_base_path + localized_ext)
			if localized_stream != null:
				return localized_stream
	var base_path := "res://sounds/voice_over/%s" % prompt_key
	var extensions: Array[String] = [".wav", ".ogg"]
	for ext in extensions:
		var stream := _get_recorded_stream_from_path(base_path + ext)
		if stream != null:
			return stream
	return null


func _is_on_cooldown(key: String, cooldown_seconds: float) -> bool:
	if not _last_spoken_msec_by_key.has(key):
		return false
	var elapsed_msec := Time.get_ticks_msec() - int(_last_spoken_msec_by_key[key])
	return elapsed_msec < int(cooldown_seconds * 1000.0)


func _clean_text(text: String) -> String:
	var cleaned := text.strip_edges()
	cleaned = cleaned.replace("\n", ". ")
	cleaned = cleaned.replace("  ", " ")
	cleaned = cleaned.replace("/", " out of ")
	cleaned = cleaned.replace(":", ".")
	return cleaned
