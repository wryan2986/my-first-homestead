extends Node

const DEFAULT_FONT_PATH := "res://art/fonts/NotoSans-Variable.ttf"
const LOCALE_FONT_PATHS := {
	"en": DEFAULT_FONT_PATH,
	"es": DEFAULT_FONT_PATH,
	"fr": DEFAULT_FONT_PATH,
	"pt-BR": DEFAULT_FONT_PATH,
	"de": DEFAULT_FONT_PATH,
	"it": DEFAULT_FONT_PATH,
	"ar": "res://art/fonts/NotoSansArabic-Variable.ttf",
	"hi": "res://art/fonts/NotoSansDevanagari-Variable.ttf",
	"zh-CN": "res://art/fonts/NotoSansSC-Variable.ttf",
	"ja": "res://art/fonts/NotoSansJP-Variable.ttf",
	"ko": "res://art/fonts/NotoSansKR-Variable.ttf",
}

var _font_cache: Dictionary = {}
var _fallback_chain: Array[Font] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if GameSettings != null and GameSettings.has_signal("locale_changed"):
		if not GameSettings.locale_changed.is_connected(_on_locale_changed):
			GameSettings.locale_changed.connect(_on_locale_changed)
	_on_locale_changed(GameSettings.get_active_locale() if GameSettings != null else TranslationServer.get_locale())


func _on_locale_changed(locale: String) -> void:
	var font := _get_font_for_locale(locale)
	if font == null:
		return
	ThemeDB.fallback_font = font
	ThemeDB.fallback_font_size = 16


func _get_font_for_locale(locale: String) -> FontFile:
	var normalized := _normalize_locale_code(locale)
	var font_path := String(LOCALE_FONT_PATHS.get(normalized, DEFAULT_FONT_PATH))
	if font_path.is_empty():
		font_path = DEFAULT_FONT_PATH
	if _font_cache.has(font_path):
		return _font_cache[font_path] as FontFile
	if not ResourceLoader.exists(font_path):
		return null
	var font := ResourceLoader.load(font_path) as FontFile
	if font == null:
		return null
	font.allow_system_fallback = true
	font.fallbacks = _get_fallback_chain(font_path)
	_font_cache[font_path] = font
	return font


func _get_fallback_chain(primary_font_path: String) -> Array[Font]:
	if _fallback_chain.is_empty():
		for font_path in _get_unique_font_paths():
			if not ResourceLoader.exists(font_path):
				continue
			var fallback_font := ResourceLoader.load(font_path) as FontFile
			if fallback_font == null:
				continue
			fallback_font.allow_system_fallback = true
			_fallback_chain.append(fallback_font)
	var chain: Array[Font] = []
	for fallback_font in _fallback_chain:
		if fallback_font == null:
			continue
		if fallback_font.resource_path == primary_font_path:
			continue
		chain.append(fallback_font)
	return chain


func _get_unique_font_paths() -> Array[String]:
	var paths: Array[String] = []
	for raw_path in LOCALE_FONT_PATHS.values():
		var font_path := String(raw_path)
		if font_path.is_empty() or paths.has(font_path):
			continue
		paths.append(font_path)
	return paths


func _normalize_locale_code(locale_code: String) -> String:
	var cleaned := locale_code.strip_edges()
	if cleaned.is_empty():
		return "en"
	if LOCALE_FONT_PATHS.has(cleaned):
		return cleaned
	var normalized := cleaned.replace("_", "-")
	if LOCALE_FONT_PATHS.has(normalized):
		return normalized
	var language := normalized.split("-")[0]
	for candidate in LOCALE_FONT_PATHS.keys():
		if String(candidate).split("-")[0] == language:
			return String(candidate)
	return "en"
