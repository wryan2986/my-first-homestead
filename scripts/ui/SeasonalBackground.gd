extends "res://scripts/ui/ResponsiveCoverSprite2D.gd"

@export var spring_texture: Texture2D
@export var summer_texture: Texture2D
@export var fall_texture: Texture2D
@export var winter_texture: Texture2D
@export_file("*.png", "*.webp", "*.jpg", "*.jpeg") var spring_texture_path := ""
@export_file("*.png", "*.webp", "*.jpg", "*.jpeg") var summer_texture_path := ""
@export_file("*.png", "*.webp", "*.jpg", "*.jpeg") var fall_texture_path := ""
@export_file("*.png", "*.webp", "*.jpg", "*.jpeg") var winter_texture_path := ""

var _default_texture: Texture2D
var _loaded_texture: Texture2D
var _loaded_season := ""


func _ready() -> void:
	_default_texture = texture
	_apply_season_texture()
	super._ready()
	if FarmState != null and not FarmState.season_changed.is_connected(_on_season_changed):
		FarmState.season_changed.connect(_on_season_changed)


func _exit_tree() -> void:
	if FarmState != null and FarmState.season_changed.is_connected(_on_season_changed):
		FarmState.season_changed.disconnect(_on_season_changed)


func _on_season_changed(_new_season: String) -> void:
	_apply_season_texture()


func _apply_season_texture() -> void:
	var seasonal_texture := _get_texture_for_season(FarmState.current_season if FarmState != null else "spring")
	texture = seasonal_texture if seasonal_texture != null else _default_texture
	apply_cover()


func _get_texture_for_season(season: String) -> Texture2D:
	var assigned_texture: Texture2D
	match season:
		"spring":
			assigned_texture = spring_texture
		"summer":
			assigned_texture = summer_texture
		"fall":
			assigned_texture = fall_texture
		"winter":
			assigned_texture = winter_texture
		_:
			return null
	if assigned_texture != null:
		return assigned_texture
	if _loaded_texture != null and _loaded_season == season:
		return _loaded_texture
	var texture_path := _get_texture_path_for_season(season)
	if texture_path.is_empty():
		return null
	_loaded_texture = ResourceLoader.load(texture_path) as Texture2D
	_loaded_season = season if _loaded_texture != null else ""
	if _loaded_texture == null:
		push_warning("Could not load seasonal background: %s" % texture_path)
	return _loaded_texture


func _get_texture_path_for_season(season: String) -> String:
	match season:
		"spring":
			return spring_texture_path
		"summer":
			return summer_texture_path
		"fall":
			return fall_texture_path
		"winter":
			return winter_texture_path
		_:
			return ""
