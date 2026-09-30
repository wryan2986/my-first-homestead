extends Node

const SAVE_PATH := "user://farm_chore_friends_game_settings.json"
const DEFAULT_LOCALE := "en"
const DEFAULT_TIMER_SECONDS := 120.0
const MIN_TIMER_SECONDS := 60.0
const MAX_TIMER_SECONDS := 1800.0
const LOCALE_FILES := {
	"en": "res://localization/translations/en.json",
	"es": "res://localization/translations/es.json",
	"fr": "res://localization/translations/fr.json",
	"pt-BR": "res://localization/translations/pt_br.json",
	"de": "res://localization/translations/de.json",
	"it": "res://localization/translations/it.json",
	"zh-CN": "res://localization/translations/zh_cn.json",
	"ja": "res://localization/translations/ja.json",
	"ko": "res://localization/translations/ko.json",
	"ar": "res://localization/translations/ar.json",
	"hi": "res://localization/translations/hi.json",
}
const VOICE_PROMPT_FILES := {
	"en": "res://localization/voice_prompts/en.json",
	"es": "res://localization/voice_prompts/es.json",
	"fr": "res://localization/voice_prompts/fr.json",
	"pt-BR": "res://localization/voice_prompts/pt_br.json",
	"de": "res://localization/voice_prompts/de.json",
	"it": "res://localization/voice_prompts/it.json",
	"zh-CN": "res://localization/voice_prompts/zh_cn.json",
	"ja": "res://localization/voice_prompts/ja.json",
	"ko": "res://localization/voice_prompts/ko.json",
	"ar": "res://localization/voice_prompts/ar.json",
	"hi": "res://localization/voice_prompts/hi.json",
}
const SUPPORTED_LOCALES: Array[Dictionary] = [
	{"code": "en", "name": "English", "native_name": "English"},
	{"code": "es", "name": "Spanish", "native_name": "Espa\u00f1ol"},
	{"code": "fr", "name": "French", "native_name": "Fran\u00e7ais"},
	{"code": "pt-BR", "name": "Portuguese", "native_name": "Portugu\u00eas"},
	{"code": "de", "name": "German", "native_name": "Deutsch"},
	{"code": "it", "name": "Italian", "native_name": "Italiano"},
	{"code": "zh-CN", "name": "Simplified Chinese", "native_name": "\u7b80\u4f53\u4e2d\u6587"},
	{"code": "ja", "name": "Japanese", "native_name": "\u65e5\u672c\u8a9e"},
	{"code": "ko", "name": "Korean", "native_name": "\ud55c\uad6d\uc5b4"},
	{"code": "ar", "name": "Arabic", "native_name": "\u0627\u0644\u0639\u0631\u0628\u064a\u0629"},
	{"code": "hi", "name": "Hindi", "native_name": "\u0939\u093f\u0928\u094d\u0926\u0940"},
]
var duck_pond_time_limit_enabled := false
var duck_pond_time_limit_seconds := DEFAULT_TIMER_SECONDS
var tap_anywhere_chore_return_enabled := true
var mole_garden_time_limit_enabled := false
var mole_garden_time_limit_seconds := DEFAULT_TIMER_SECONDS
var use_system_locale := true
var preferred_locale := DEFAULT_LOCALE
var active_locale := DEFAULT_LOCALE
var active_tts_locale := DEFAULT_LOCALE
var _translations_loaded := false

signal locale_changed(locale: String)
signal tts_locale_changed(locale: String)


func _ready() -> void:
	_load_translations()
	load_game_settings()
	_apply_locale(false)


func set_duck_pond_time_limit_enabled(enabled: bool) -> void:
	duck_pond_time_limit_enabled = enabled
	save_game_settings()


func is_duck_pond_time_limit_enabled() -> bool:
	return duck_pond_time_limit_enabled


func set_duck_pond_time_limit_seconds(seconds: float) -> void:
	duck_pond_time_limit_seconds = _clamp_timer_seconds(seconds)
	save_game_settings()


func get_duck_pond_time_limit_seconds() -> float:
	return duck_pond_time_limit_seconds


func set_mole_garden_time_limit_enabled(enabled: bool) -> void:
	mole_garden_time_limit_enabled = enabled
	save_game_settings()


func is_mole_garden_time_limit_enabled() -> bool:
	return mole_garden_time_limit_enabled


func set_mole_garden_time_limit_seconds(seconds: float) -> void:
	mole_garden_time_limit_seconds = _clamp_timer_seconds(seconds)
	save_game_settings()


func get_mole_garden_time_limit_seconds() -> float:
	return mole_garden_time_limit_seconds


func set_tap_anywhere_chore_return_enabled(enabled: bool) -> void:
	tap_anywhere_chore_return_enabled = enabled
	save_game_settings()


func is_tap_anywhere_chore_return_enabled() -> bool:
	return tap_anywhere_chore_return_enabled


func set_use_system_locale(enabled: bool) -> void:
	if use_system_locale and not enabled:
		preferred_locale = _normalize_locale_code(active_locale)
		if preferred_locale.is_empty():
			preferred_locale = DEFAULT_LOCALE
	use_system_locale = enabled
	_apply_locale(true)


func is_using_system_locale() -> bool:
	return use_system_locale


func set_preferred_locale(locale_code: String) -> void:
	var normalized := _normalize_locale_code(locale_code)
	if normalized.is_empty():
		normalized = DEFAULT_LOCALE
	preferred_locale = normalized
	use_system_locale = false
	_apply_locale(true)


func get_preferred_locale() -> String:
	return preferred_locale


func get_active_locale() -> String:
	return active_locale


func get_effective_locale() -> String:
	if use_system_locale:
		return _normalize_locale_code(_get_device_locale())
	return _normalize_locale_code(preferred_locale)


func set_tts_use_app_locale(enabled: bool) -> void:
	# Compatibility wrapper for old saved/settings UI paths. Voice-over now
	# always follows the app language so text and voice cannot diverge.
	if not enabled:
		set_use_system_locale(false)
	_apply_tts_locale(true)


func is_tts_using_app_locale() -> bool:
	return true


func set_preferred_tts_locale(locale_code: String) -> void:
	set_preferred_locale(locale_code)


func get_preferred_tts_locale() -> String:
	return preferred_locale


func get_active_tts_locale() -> String:
	return active_tts_locale


func get_effective_tts_locale() -> String:
	return get_effective_locale()


func get_tts_locale_choices() -> Array[Dictionary]:
	return get_locale_choices()


func get_supported_locales() -> Array[Dictionary]:
	return SUPPORTED_LOCALES.duplicate(true)


func get_locale_display_name(locale_code: String) -> String:
	var normalized := _normalize_locale_code(locale_code)
	if normalized.is_empty():
		return tr("Use device language")
	for locale_data in SUPPORTED_LOCALES:
		if String(locale_data.get("code", "")) == normalized:
			var native_name := String(locale_data.get("native_name", locale_data.get("name", normalized)))
			if not native_name.is_empty():
				return native_name
			return String(locale_data.get("name", normalized))
	return normalized


func get_locale_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	choices.append({
		"code": "",
		"name": tr("Use device language"),
		"native_name": tr("Use device language"),
	})
	for locale_data in SUPPORTED_LOCALES:
		choices.append({
			"code": String(locale_data.get("code", "")),
			"name": String(locale_data.get("name", "")),
			"native_name": String(locale_data.get("native_name", locale_data.get("name", "")))
		})
	return choices


func apply_locale() -> void:
	_apply_locale(true)


func save_game_settings() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"duck_pond_time_limit_enabled": duck_pond_time_limit_enabled,
		"duck_pond_time_limit_seconds": duck_pond_time_limit_seconds,
		"mole_garden_time_limit_enabled": mole_garden_time_limit_enabled,
		"mole_garden_time_limit_seconds": mole_garden_time_limit_seconds,
		"tap_anywhere_chore_return_enabled": tap_anywhere_chore_return_enabled,
		"use_system_locale": use_system_locale,
		"preferred_locale": preferred_locale,
	}, "\t"))


func load_game_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	var data := parsed as Dictionary
	duck_pond_time_limit_enabled = _read_bool(data.get("duck_pond_time_limit_enabled", duck_pond_time_limit_enabled), duck_pond_time_limit_enabled)
	duck_pond_time_limit_seconds = _clamp_timer_seconds(_read_float(data.get("duck_pond_time_limit_seconds", duck_pond_time_limit_seconds), duck_pond_time_limit_seconds))
	mole_garden_time_limit_enabled = _read_bool(data.get("mole_garden_time_limit_enabled", duck_pond_time_limit_enabled), duck_pond_time_limit_enabled)
	mole_garden_time_limit_seconds = _clamp_timer_seconds(_read_float(data.get("mole_garden_time_limit_seconds", mole_garden_time_limit_seconds), mole_garden_time_limit_seconds))
	tap_anywhere_chore_return_enabled = _read_bool(data.get("tap_anywhere_chore_return_enabled", tap_anywhere_chore_return_enabled), tap_anywhere_chore_return_enabled)
	use_system_locale = _read_bool(data.get("use_system_locale", use_system_locale), use_system_locale)
	preferred_locale = _normalize_locale_code(str(data.get("preferred_locale", preferred_locale)))
	if preferred_locale.is_empty():
		preferred_locale = DEFAULT_LOCALE
	_apply_locale(false)


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


func _clamp_timer_seconds(seconds: float) -> float:
	return clampf(seconds, MIN_TIMER_SECONDS, MAX_TIMER_SECONDS)


func _load_translations() -> void:
	if _translations_loaded:
		return
	_translations_loaded = true
	for locale_code in LOCALE_FILES.keys():
		var messages := _load_translation_messages(str(LOCALE_FILES[locale_code]), str(VOICE_PROMPT_FILES.get(locale_code, "")))
		if messages.is_empty():
			continue
		var translation := Translation.new()
		translation.locale = String(locale_code)
		for source_text in messages.keys():
			var translated_text := str(messages[source_text])
			if translated_text.is_empty():
				continue
			translation.add_message(str(source_text), translated_text)
		TranslationServer.add_translation(translation)


func _load_translation_messages(primary_path: String, secondary_path: String) -> Dictionary:
	var messages: Dictionary = {}
	_merge_translation_file(messages, primary_path)
	_merge_translation_file(messages, secondary_path)
	return messages


func _merge_translation_file(messages: Dictionary, path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	for source_text in (parsed as Dictionary).keys():
		var translated_text := str((parsed as Dictionary)[source_text])
		if translated_text.is_empty():
			continue
		messages[str(source_text)] = translated_text


func _apply_locale(save_settings: bool) -> void:
	var target_locale := get_effective_locale()
	if target_locale.is_empty():
		target_locale = DEFAULT_LOCALE
	TranslationServer.set_locale(target_locale)
	active_locale = target_locale
	emit_signal("locale_changed", active_locale)
	_apply_tts_locale(false)
	if save_settings:
		save_game_settings()


func _apply_tts_locale(save_settings: bool) -> void:
	var target_tts_locale := get_effective_tts_locale()
	if target_tts_locale.is_empty():
		target_tts_locale = DEFAULT_LOCALE
	active_tts_locale = target_tts_locale
	emit_signal("tts_locale_changed", active_tts_locale)
	if save_settings:
		save_game_settings()


func _normalize_locale_code(locale_code: String) -> String:
	var cleaned := locale_code.strip_edges()
	if cleaned.is_empty():
		return ""
	if LOCALE_FILES.has(cleaned):
		return cleaned
	var normalized := cleaned.replace("_", "-")
	if LOCALE_FILES.has(normalized):
		return normalized
	var language := normalized.split("-")[0]
	for candidate in LOCALE_FILES.keys():
		if String(candidate).split("-")[0] == language:
			return String(candidate)
	return DEFAULT_LOCALE


func _get_device_locale() -> String:
	if OS.has_method("get_locale"):
		return str(OS.get_locale())
	if OS.has_method("get_locale_language"):
		return str(OS.get_locale_language())
	return DEFAULT_LOCALE
