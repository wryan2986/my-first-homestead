class_name GardenPlot
extends Area2D

signal tapped(plot: GardenPlot)

@export var plot_index := 0
@export var plot_name := "Plot"
@export var soil_sprite: NodePath
@export var plant_sprite: NodePath
@export var title_label: NodePath
@export var status_label: NodePath
@export var water_icon: NodePath
@export var wet_overlay: NodePath
@export var sparkle_sprite: NodePath
@export var plot_texture: Texture2D
@export var seed_texture: Texture2D
@export var plant_texture: Texture2D
@export var harvest_texture: Texture2D
@export var turnip_texture: Texture2D
@export var carrot_texture: Texture2D
@export var corn_texture: Texture2D
@export var pumpkin_texture: Texture2D
@export var tomato_texture: Texture2D
@export var strawberry_texture: Texture2D
@export var sunflower_texture: Texture2D
@export var lettuce_texture: Texture2D
@export var turnip_harvest_item_texture: Texture2D
@export var carrot_harvest_item_texture: Texture2D
@export var corn_harvest_item_texture: Texture2D
@export var pumpkin_harvest_item_texture: Texture2D
@export var tomato_harvest_item_texture: Texture2D
@export var strawberry_harvest_item_texture: Texture2D
@export var sunflower_harvest_item_texture: Texture2D
@export var lettuce_harvest_item_texture: Texture2D
@export var wet_soil_texture: Texture2D

var _plot_state := FarmState.PLOT_EMPTY
var _crop_name := ""
var _cared_today := false
@onready var _soil_sprite: Sprite2D = get_node_or_null(soil_sprite) as Sprite2D
@onready var _plant_sprite: Sprite2D = get_node_or_null(plant_sprite) as Sprite2D
@onready var _title_label: Label = get_node_or_null(title_label) as Label
@onready var _status_label: Label = get_node_or_null(status_label) as Label
@onready var _water_icon: CanvasItem = get_node_or_null(water_icon) as CanvasItem
@onready var _wet_overlay: Sprite2D = get_node_or_null(wet_overlay) as Sprite2D
@onready var _sparkle_sprite: CanvasItem = get_node_or_null(sparkle_sprite) as CanvasItem


func _ready() -> void:
	input_pickable = true
	if _title_label != null:
		FarmFeedback.hide_label(_title_label)
	if _soil_sprite != null and plot_texture != null:
		_soil_sprite.texture = plot_texture
	if _wet_overlay != null:
		if wet_soil_texture != null:
			_wet_overlay.texture = wet_soil_texture
		_wet_overlay.visible = false
	if _sparkle_sprite != null:
		_sparkle_sprite.visible = false


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		get_viewport().set_input_as_handled()
		emit_signal("tapped", self)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		emit_signal("tapped", self)


func apply_plot_data(plot_data: Dictionary, season: String) -> void:
	_plot_state = String(plot_data.get("state", FarmState.PLOT_EMPTY))
	_crop_name = String(plot_data.get("crop", ""))
	var watered_today := bool(plot_data.get("watered_today", false))
	_cared_today = bool(plot_data.get("cared_today", false))

	if _water_icon != null:
		_water_icon.visible = watered_today
	if _wet_overlay != null:
		_wet_overlay.visible = watered_today
		_wet_overlay.modulate.a = 1.0

	if _title_label != null:
		FarmFeedback.hide_label(_title_label)
	if _status_label != null:
		FarmFeedback.hide_label(_status_label)

	if _soil_sprite != null:
		_soil_sprite.modulate = _get_soil_color(season, watered_today)
	if _plant_sprite != null:
		# The circular soil tile is the harvested visual. Keeping the separate
		# square dirt sprite visible made the finished plot look like a placeholder.
		_plant_sprite.visible = _plot_state not in [FarmState.PLOT_EMPTY, FarmState.PLOT_HARVESTED]
		_plant_sprite.texture = _get_plant_texture()
		_plant_sprite.modulate = _get_plant_color(season)
		_plant_sprite.scale = _get_plant_scale()


func play_success(action: String) -> void:
	FarmFeedback.pulse(self, 1.08)
	if action in ["seed", "water", "care", "grow"]:
		_show_wet_feedback()
		_show_sparkle_feedback()
	if action in ["grow", "harvest", "seed", "water"]:
		var bounce_target: Node2D = _plant_sprite if _plant_sprite != null and _plant_sprite.visible else self
		FarmFeedback.bounce(bounce_target, 20.0, 0.08)
	FarmFeedback.flash(self, Color(1.08, 1.1, 1.08, 1.0), 0.08)


func get_plant_feedback_texture() -> Texture2D:
	if _plant_sprite == null or not _plant_sprite.visible:
		return null
	return _plant_sprite.texture


func get_harvest_basket_texture() -> Texture2D:
	var crop_texture := _get_harvest_item_texture()
	return crop_texture if crop_texture != null else get_plant_feedback_texture()


func get_harvest_basket_scale() -> Vector2:
	match _crop_name:
		"tomato", "strawberry":
			return Vector2(0.36, 0.36)
		"carrot", "turnip", "lettuce":
			return Vector2(0.34, 0.34)
		"corn", "sunflower":
			return Vector2(0.32, 0.32)
		"pumpkin":
			return Vector2(0.34, 0.34)
		_:
			return Vector2(0.34, 0.34)


func get_plant_feedback_origin() -> Vector2:
	if _plant_sprite == null or not _plant_sprite.visible:
		return global_position + Vector2(0.0, -86.0)
	return _plant_sprite.global_position


func get_plant_feedback_scale() -> Vector2:
	if _plant_sprite == null or not _plant_sprite.visible:
		return Vector2(0.24, 0.24)
	return _plant_sprite.global_scale


func get_plant_feedback_modulate() -> Color:
	if _plant_sprite == null or not _plant_sprite.visible:
		return Color.WHITE
	return _plant_sprite.modulate


func set_plant_feedback_visible(visible: bool) -> void:
	if _plant_sprite != null:
		_plant_sprite.visible = visible


func _show_wet_feedback() -> void:
	if _wet_overlay == null:
		return
	_wet_overlay.visible = true
	_wet_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_wet_overlay, "modulate:a", 1.0, 0.14)


func _show_sparkle_feedback() -> void:
	if _sparkle_sprite == null:
		return
	_sparkle_sprite.visible = true
	_sparkle_sprite.modulate.a = 0.0
	_sparkle_sprite.scale = Vector2(0.14, 0.14)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_sparkle_sprite, "modulate:a", 1.0, 0.12)
	tween.tween_property(_sparkle_sprite, "scale", Vector2(0.24, 0.24), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_interval(0.22)
	tween.tween_property(_sparkle_sprite, "modulate:a", 0.0, 0.22)
	tween.tween_callback(func() -> void:
		if _sparkle_sprite != null:
			_sparkle_sprite.visible = false
	)


func _get_status_text(season: String) -> String:
	if _cared_today and _plot_state != FarmState.PLOT_HARVESTED:
		return "Cared today"
	match _plot_state:
		FarmState.PLOT_EMPTY:
			return _get_empty_plot_status(season)
		FarmState.PLOT_SEEDED:
			return "Seeds in soil"
		FarmState.PLOT_SPROUTING:
			return "Little sprout"
		FarmState.PLOT_GROWING:
			return "Growing %s" % _crop_name
		FarmState.PLOT_READY_TO_HARVEST:
			return "Harvest %s" % _crop_name
		FarmState.PLOT_HARVESTED:
			return "Picked today"
		_:
			return "Happy garden"


func _get_empty_plot_status(season: String) -> String:
	match FarmState.get_day_in_season():
		1:
			return "Tap to plant"
		2:
			return "Growing soon"
		3:
			return "Ready next season"
		_:
			return "Happy soil"


func _get_soil_color(season: String, watered_today: bool) -> Color:
	if watered_today:
		return Color("75513b")
	match season:
		"spring":
			return Color("8b5a3c")
		"summer":
			return Color("5e381dff")
		"fall":
			return Color("492a15ff")
		_:
			return Color("adc5da")


func _get_plant_texture() -> Texture2D:
	match _plot_state:
		FarmState.PLOT_SEEDED:
			return seed_texture if seed_texture != null else plant_texture
		FarmState.PLOT_READY_TO_HARVEST:
			var crop_texture := _get_crop_texture()
			return crop_texture if crop_texture != null else harvest_texture
		_:
			return plant_texture


func _get_plant_scale() -> Vector2:
	match _plot_state:
		FarmState.PLOT_SEEDED:
			return Vector2(0.18, 0.18)
		FarmState.PLOT_SPROUTING:
			return Vector2(0.22, 0.22)
		FarmState.PLOT_GROWING:
			return Vector2(0.27, 0.27)
		FarmState.PLOT_READY_TO_HARVEST:
			return Vector2(0.3, 0.3)
		_:
			return Vector2.ONE


func _get_plant_color(season: String) -> Color:
	if _plot_state == FarmState.PLOT_READY_TO_HARVEST and _get_crop_texture() != null:
		return Color.WHITE

	match _crop_name:
		"turnip":
			return Color("90db7d")
		"carrot":
			return Color("ffb35c")
		"pea":
			return Color("72d66f")
		"corn":
			return Color("f2d65c")
		"tomato":
			return Color("ff6b5f")
		"strawberry":
			return Color("ff6f7b")
		"pumpkin":
			return Color("ff9b42")
		"sunflower":
			return Color("ffd85a")
		"lettuce":
			return Color("b8e889")
		_:
			return Color("79d86f") if season != "winter" else Color("dfe8f2")


func _get_crop_texture() -> Texture2D:
	match _crop_name:
		"turnip":
			return turnip_texture
		"carrot":
			return carrot_texture
		"corn":
			return corn_texture
		"pumpkin":
			return pumpkin_texture
		"tomato":
			return tomato_texture
		"strawberry":
			return strawberry_texture
		"sunflower":
			return sunflower_texture
		"lettuce":
			return lettuce_texture
		_:
			return null


func _get_harvest_item_texture() -> Texture2D:
	match _crop_name:
		"turnip":
			return turnip_harvest_item_texture
		"carrot":
			return carrot_harvest_item_texture
		"corn":
			return corn_harvest_item_texture
		"pumpkin":
			return pumpkin_harvest_item_texture
		"tomato":
			return tomato_harvest_item_texture
		"strawberry":
			return strawberry_harvest_item_texture
		"sunflower":
			return sunflower_harvest_item_texture
		"lettuce":
			return lettuce_harvest_item_texture
		_:
			return null
