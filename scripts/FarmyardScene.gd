extends Node2D

const ChoreCompletionFlowScript := preload("res://scripts/core/ChoreCompletionFlow.gd")
const PROGRESSION_DESIGN_PLAYER_PLACED := "player_placed_rewards"
const PROGRESSION_DESIGN_AREA_EVOLUTION := "farm_area_evolution"
const PROGRESSION_DESIGN_REWARD_MOMENTS := "reward_unlock_moments"
# Curated reward slots keep farm improvements off paths, hotspots, animals, and UI.
const REWARD_SLOT_RECTS := {
	"fence_flowers": Rect2(1120, 350, 240, 95),
	"lower_left_flower_edge": Rect2(650, 760, 245, 180),
	"left_fence_hay_corner": Rect2(70, 585, 230, 160),
	"spring_geese_pond": Rect2(540, 220, 230, 130),
	"right_pond_edge": Rect2(1740, 540, 180, 150),
	"upper_orchard_corner": Rect2(1080, 164, 240, 190),
	"windmill_hill": Rect2(1760, 197, 150, 170),
}
const REWARD_SLOT_POSITIONS := {
	"fence_flowers": Vector2(1450, 430),
	"lower_left_flower_edge": Vector2(770.99994, 854.99994),
	"left_fence_hay_corner": Vector2(180, 650),
	"spring_geese_pond": Vector2(653, 301),
	"right_pond_edge": Vector2(1820, 600),
	"upper_orchard_corner": Vector2(1180, 264),
	"windmill_hill": Vector2(1830, 267),
}
const DEFAULT_REWARD_SLOTS := {
	"flower_bed": "lower_left_flower_edge",
	"prettier_fence": "fence_flowers",
	"hay_bales": "left_fence_hay_corner",
	"geese_pond": "spring_geese_pond",
	"duck_pond": "right_pond_edge",
	"rainbow_tree": "upper_orchard_corner",
	"windmill": "windmill_hill",
}
const REWARD_SLOT_REWARD_IDS := {
	"fence_flowers": "prettier_fence",
	"lower_left_flower_edge": "flower_bed",
	"left_fence_hay_corner": "hay_bales",
	"spring_geese_pond": "geese_pond",
	"right_pond_edge": "duck_pond",
	"upper_orchard_corner": "rainbow_tree",
	"windmill_hill": "windmill",
}
const REWARD_ALLOWED_SLOTS := {
	"flower_bed": ["lower_left_flower_edge"],
	"prettier_fence": ["fence_flowers"],
	"hay_bales": ["left_fence_hay_corner"],
	"geese_pond": ["spring_geese_pond"],
	"duck_pond": ["right_pond_edge"],
	"rainbow_tree": ["upper_orchard_corner"],
	"windmill": ["windmill_hill"],
}
const LEGACY_REWARD_SLOT_MIGRATIONS := {
	"path_left": "left_fence_hay_corner",
	"path_center": "lower_left_flower_edge",
	"path_right": "right_pond_edge",
	"barn_corner": "left_fence_hay_corner",
	"upper_tree": "upper_orchard_corner",
	"right_yard": "fence_flowers",
	"upper_right_fence": "fence_flowers",
}
const VISUAL_REWARD_IDS: Array[String] = [
	"flower_bed",
	"prettier_fence",
	"hay_bales",
	"geese_pond",
	"duck_pond",
	"rainbow_tree",
	"windmill",
]
const SEASONAL_BASE_TEXTURE_PATHS := {
	"spring": "res://art/backgrounds/farmyard_layers/farmyard_base_spring.png",
	"summer": "res://art/backgrounds/farmyard_layers/farmyard_base_summer.png",
	"fall": "res://art/backgrounds/farmyard_layers/farmyard_base_fall.png",
	"winter": "res://art/backgrounds/farmyard_layers/farmyard_base_winter.png",
}
const SEASONAL_ICON_TEXTURE_PATHS := {
	"chicken": {
		"spring": "res://art/props/chicken_coop_spring.png",
		"summer": "res://art/props/chicken_coop_summer.png",
		"fall": "res://art/props/chicken_coop_fall.png",
		"winter": "res://art/props/chicken_coop_winter.png",
	},
	"milking": {
		"spring": "res://art/props/hub_milking_stall_cow_spring.png",
		"summer": "res://art/props/hub_milking_stall_cow_summer.png",
		"fall": "res://art/props/hub_milking_stall_cow_fall.png",
		"winter": "res://art/props/hub_milking_stall_cow_winter.png",
	},
	"feeding": {
		"spring": "res://art/props/hub_feed_pen_spring.png",
		"summer": "res://art/props/hub_feed_pen_summer.png",
		"fall": "res://art/props/hub_feed_pen_fall.png",
		"winter": "res://art/props/hub_feed_pen_winter.png",
	},
	"brushing": {
		"spring": "res://art/props/hub_grooming_stalls_spring.png",
		"summer": "res://art/props/hub_grooming_stalls_summer.png",
		"fall": "res://art/props/hub_grooming_stalls_fall.png",
		"winter": "res://art/props/hub_grooming_stalls_winter.png",
	},
	"garden_fence": {
		"spring": "res://art/props/hub_garden_fenced_spring.png",
		"summer": "res://art/props/hub_garden_fenced_summer.png",
		"fall": "res://art/props/hub_garden_fenced_fall.png",
		"winter": "res://art/props/hub_garden_fenced_winter.png",
	},
	"rainbow_tree": {
		"spring": "res://art/props/decoration_orchard_tree_spring.png",
		"summer": "res://art/props/decoration_orchard_tree_summer.png",
		"fall": "res://art/props/decoration_orchard_tree_fall.png",
		"winter": "res://art/props/decoration_orchard_tree_winter.png",
	},
	"flower_bed": {
		"spring": "res://art/props/decoration_flower_path.png",
		"summer": "res://art/props/decoration_flower_path.png",
		"fall": "res://art/props/decoration_flower_path_fall.png",
		"winter": "res://art/props/decoration_flower_path_winter.png",
	},
	"windmill": {
		"spring": "res://art/props/decoration_windmill_spring.png",
		"summer": "res://art/props/decoration_windmill_summer.png",
		"fall": "res://art/props/decoration_windmill_fall.png",
		"winter": "res://art/props/decoration_windmill_winter.png",
	},
}

@export_enum("player_placed_rewards", "farm_area_evolution", "reward_unlock_moments") var progression_design := PROGRESSION_DESIGN_AREA_EVOLUTION
@export var season_tint: NodePath
@export var day_label: NodePath
@export var season_label: NodePath
@export var season_icon: NodePath
@export var spring_season_icon: Texture2D
@export var summer_season_icon: Texture2D
@export var fall_season_icon: Texture2D
@export var winter_season_icon: Texture2D
@export var summary_label: NodePath
@export var next_day_button: NodePath
@export var feedback_label: NodePath
@export var settings_button: NodePath
@export var settings_panel: NodePath
@export var chicken_badge: NodePath
@export var milking_badge: NodePath
@export var garden_badge: NodePath
@export var feeding_badge: NodePath
@export var brushing_badge: NodePath
@export var flower_bed_node: NodePath
@export var goat_node: NodePath
@export var prettier_fence_node: NodePath
@export var hay_bales_node: NodePath
@export var duck_pond_node: NodePath
@export var rainbow_tree_node: NodePath
@export var windmill_node: NodePath
@export var brushing_duck_stall_node: NodePath
@export var brushing_dirty_overlays: Array[NodePath] = []
@export var brushing_clean_sparkles: Array[NodePath] = []
@export var brushing_animal_ids: Array[String] = ["pony", "cow", "sheep", "duck"]
@export var chicken_visual: NodePath
@export var milking_visual: NodePath
@export var garden_visual: NodePath
@export var feeding_visual: NodePath
@export var brushing_visual: NodePath
@export var chicken_hotspot: NodePath
@export var milking_hotspot: NodePath
@export var garden_hotspot: NodePath
@export var feeding_hotspot: NodePath
@export var brushing_hotspot: NodePath
@export var mole_garden_hotspot: NodePath
@export var next_day_sound: AudioStream
@export var egg_scene: PackedScene
@export var milking_scene: PackedScene
@export var garden_scene: PackedScene
@export var feeding_scene: PackedScene
@export var brushing_scene: PackedScene
@export var duck_pond_music_scene: PackedScene
@export var hotspot_touch_margin := 18.0
@export var hub_interactable_touch_margin := 28.0
@export var hub_route_failed_taps := 4
@export var hub_route_delay := 5.0
@export var return_input_cooldown_seconds := 0.75
@export var chore_entry_cooldown_seconds := 3.0
@export var world_fit_enabled := false
@export var design_viewport_size := Vector2(1920.0, 1080.0)
@export var ambient_chicken_root: NodePath
@export var ambient_cow_root: NodePath
@export var bee_root: NodePath
@export var butterfly_root: NodePath
@export var spring_geese_root: NodePath
@export var duck_pond_play_root: NodePath
@export var santa_flyer_root: NodePath
@export var seasonal_surprises_root: NodePath
@export var night_transition_root: NodePath
@export var next_day_transition_enabled := true
@export var seasonal_base_visual: NodePath
@export var seasonal_spring_overlay: NodePath
@export var seasonal_summer_overlay: NodePath
@export var seasonal_fall_overlay: NodePath
@export var seasonal_winter_overlay: NodePath
@export var garden_fence_visual: NodePath
@export var garden_preview_plot_nodes: Array[NodePath] = []
@export var garden_preview_plant_nodes: Array[NodePath] = []
@export var garden_preview_seed_texture: Texture2D
@export var garden_preview_sprout_texture: Texture2D
@export var garden_preview_growing_texture: Texture2D
@export var garden_preview_ready_texture: Texture2D
@export var garden_preview_harvested_texture: Texture2D
@export var animal_greet_cooldown_seconds := 0.55

var _hub_failed_taps := 0
var _hub_started_msec := 0
var _hub_has_highlighted := false
var _known_reward_ids: Array[String] = []
var _selected_placeable_reward_id := ""
var _reward_tray_button: Button
var _placement_zone_root: Node2D
var _placement_zone_items: Dictionary = {}
var _reward_default_positions: Dictionary = {}
var _reward_default_scales: Dictionary = {}
var _reward_default_modulates: Dictionary = {}
var _default_seasonal_visual_textures: Dictionary = {}
var _seasonal_texture_cache: Dictionary = {}
var _original_background_layer_visibility: Dictionary = {}
var _world_fit_root_transforms: Dictionary = {}
var _day_transition_active := false
var _chore_entry_unlocked_msec := 0
var _last_animal_greet_msec := -1000000
var _sticker_badge: Label

@onready var _season_tint: ColorRect = get_node_or_null(season_tint) as ColorRect
@onready var _day_label: Label = get_node_or_null(day_label) as Label
@onready var _season_label: Label = get_node_or_null(season_label) as Label
@onready var _season_icon: TextureRect = get_node_or_null(season_icon) as TextureRect
@onready var _summary_label: Label = get_node_or_null(summary_label) as Label
@onready var _next_day_button: Button = get_node_or_null(next_day_button) as Button
@onready var _feedback_label: Label = get_node_or_null(feedback_label) as Label
@onready var _settings_button: Button = get_node_or_null(settings_button) as Button
@onready var _settings_panel: Control = get_node_or_null(settings_panel) as Control
@onready var _chicken_badge: CanvasItem = get_node_or_null(chicken_badge) as CanvasItem
@onready var _milking_badge: CanvasItem = get_node_or_null(milking_badge) as CanvasItem
@onready var _garden_badge: CanvasItem = get_node_or_null(garden_badge) as CanvasItem
@onready var _feeding_badge: CanvasItem = get_node_or_null(feeding_badge) as CanvasItem
@onready var _brushing_badge: CanvasItem = get_node_or_null(brushing_badge) as CanvasItem
@onready var _flower_bed_node: CanvasItem = get_node_or_null(flower_bed_node) as CanvasItem
@onready var _goat_node: CanvasItem = get_node_or_null(goat_node) as CanvasItem
@onready var _prettier_fence_node: CanvasItem = get_node_or_null(prettier_fence_node) as CanvasItem
@onready var _hay_bales_node: CanvasItem = get_node_or_null(hay_bales_node) as CanvasItem
@onready var _duck_pond_node: CanvasItem = get_node_or_null(duck_pond_node) as CanvasItem
@onready var _rainbow_tree_node: CanvasItem = get_node_or_null(rainbow_tree_node) as CanvasItem
@onready var _windmill_node: CanvasItem = get_node_or_null(windmill_node) as CanvasItem
@onready var _brushing_duck_stall_node: CanvasItem = get_node_or_null(brushing_duck_stall_node) as CanvasItem
@onready var _chicken_visual: CanvasItem = get_node_or_null(chicken_visual) as CanvasItem
@onready var _milking_visual: CanvasItem = get_node_or_null(milking_visual) as CanvasItem
@onready var _garden_visual: CanvasItem = get_node_or_null(garden_visual) as CanvasItem
@onready var _feeding_visual: CanvasItem = get_node_or_null(feeding_visual) as CanvasItem
@onready var _brushing_visual: CanvasItem = get_node_or_null(brushing_visual) as CanvasItem
@onready var _chicken_hotspot: SceneHotspot = get_node_or_null(chicken_hotspot) as SceneHotspot
@onready var _milking_hotspot: SceneHotspot = get_node_or_null(milking_hotspot) as SceneHotspot
@onready var _garden_hotspot: SceneHotspot = get_node_or_null(garden_hotspot) as SceneHotspot
@onready var _feeding_hotspot: SceneHotspot = get_node_or_null(feeding_hotspot) as SceneHotspot
@onready var _brushing_hotspot: SceneHotspot = get_node_or_null(brushing_hotspot) as SceneHotspot
@onready var _mole_garden_hotspot: SceneHotspot = get_node_or_null(mole_garden_hotspot) as SceneHotspot
@onready var _ambient_chicken_root: Node = get_node_or_null(ambient_chicken_root)
@onready var _ambient_cow_root: Node = get_node_or_null(ambient_cow_root)
@onready var _bee_root: Node2D = get_node_or_null(bee_root) as Node2D
@onready var _butterfly_root: Node2D = get_node_or_null(butterfly_root) as Node2D
@onready var _spring_geese_root: Node = get_node_or_null(spring_geese_root)
@onready var _duck_pond_play_root: Node = get_node_or_null(duck_pond_play_root)
@onready var _santa_flyer_root: Node = get_node_or_null(santa_flyer_root)
@onready var _seasonal_surprises_root: Node = get_node_or_null(seasonal_surprises_root)
@onready var _night_transition_root: Node = get_node_or_null(night_transition_root)
@onready var _seasonal_base_visual: Sprite2D = get_node_or_null(seasonal_base_visual) as Sprite2D
@onready var _garden_fence_visual: CanvasItem = get_node_or_null(garden_fence_visual) as CanvasItem
@onready var _original_background_layers: Array[CanvasItem] = [
	get_node_or_null("BackgroundLayers/Sky") as CanvasItem,
	get_node_or_null("BackgroundLayers/GroundBase") as CanvasItem,
	get_node_or_null("BackgroundLayers/Paths") as CanvasItem,
	get_node_or_null("BackgroundLayers/DecorativeProps") as CanvasItem,
	get_node_or_null("BackgroundLayers/CowAreaArt") as CanvasItem,
	get_node_or_null("BackgroundLayers/GardenAreaArt") as CanvasItem,
]
@onready var _seasonal_overlays := {
	"spring": get_node_or_null(seasonal_spring_overlay) as CanvasItem,
	"summer": get_node_or_null(seasonal_summer_overlay) as CanvasItem,
	"fall": get_node_or_null(seasonal_fall_overlay) as CanvasItem,
	"winter": get_node_or_null(seasonal_winter_overlay) as CanvasItem,
}

var _brushing_dirty_items: Array[CanvasItem] = []
var _brushing_clean_items: Array[CanvasItem] = []
var _garden_preview_plots: Array[Sprite2D] = []
var _garden_preview_plants: Array[Sprite2D] = []
var _garden_preview_plot_base_modulates: Array[Color] = []
var _garden_preview_plant_base_scales: Array[Vector2] = []


func _ready() -> void:
	SceneNavigator.register_farmyard(self)
	if ChoreCompletionFlowScript.is_farmyard_input_locked():
		ChoreCompletionFlowScript.lock_farmyard_input(return_input_cooldown_seconds)
	FarmState.set_progression_design(progression_design)
	_hub_started_msec = Time.get_ticks_msec()
	_chore_entry_unlocked_msec = _hub_started_msec + int(maxf(0.0, chore_entry_cooldown_seconds) * 1000.0)
	_known_reward_ids = FarmState.get_reward_event_ids()
	_cache_brushing_stall_state_nodes()
	_cache_garden_preview_nodes()
	_cache_reward_node_defaults()
	_cache_original_background_layer_visibility()
	_cache_seasonal_visual_defaults()
	_cache_world_fit_transforms()
	_apply_world_fit()
	_build_reward_placement_ui()
	if FarmState.STICKERS_ENABLED:
		_build_sticker_badge()
	_cache_world_fit_transforms()
	_apply_world_fit()
	_connect_ambient_critters()
	_prepare_manual_hotspot_routing()
	MusicManager.play_farmyard_music()
	if GameSettings.has_signal("locale_changed") and not GameSettings.locale_changed.is_connected(_refresh_hub):
		GameSettings.locale_changed.connect(_refresh_hub)
	if _next_day_button != null:
		_next_day_button.pressed.connect(_advance_day)
	if _settings_button != null:
		_settings_button.pressed.connect(_open_settings)
	if _settings_panel != null:
		if _settings_panel.has_method("set_tester_tools_enabled"):
			_settings_panel.call("set_tester_tools_enabled", OS.is_debug_build())
		if _settings_panel.has_signal("tester_action_requested"):
			_settings_panel.connect("tester_action_requested", _on_tester_action_requested)
		_settings_panel.call("close")

	FarmState.farm_state_changed.connect(_refresh_hub)
	FarmState.day_changed.connect(_refresh_hub)
	FarmState.year_changed.connect(_refresh_hub)
	FarmState.season_changed.connect(_refresh_hub)
	FarmState.garden_plot_changed.connect(_on_garden_plot_changed)
	FarmState.unlocks_changed.connect(_on_unlocks_changed)
	FarmState.chore_completed.connect(_on_chore_completed)
	if FarmState.STICKERS_ENABLED:
		FarmState.sticker_awarded.connect(_on_sticker_awarded)

	_register_scene_navigator_routes()
	_refresh_hub()
	_restore_farmyard_runtime_state()
	if world_fit_enabled and not get_viewport().size_changed.is_connected(_apply_world_fit):
		get_viewport().size_changed.connect(_apply_world_fit)


func refresh_after_activity_return() -> void:
	_hub_started_msec = Time.get_ticks_msec()
	_chore_entry_unlocked_msec = _hub_started_msec + int(maxf(0.0, chore_entry_cooldown_seconds) * 1000.0)
	_refresh_hub()
	_restore_farmyard_runtime_state()


func prepare_for_activity_launch() -> void:
	_save_farmyard_runtime_state()


func _register_scene_navigator_routes() -> void:
	SceneNavigator.register_activity_routes({
		FarmState.CHORE_EGGS: egg_scene,
		FarmState.CHORE_MILKING: milking_scene,
		FarmState.CHORE_GARDEN: garden_scene,
		FarmState.CHORE_FEEDING: feeding_scene,
		FarmState.CHORE_BRUSHING: brushing_scene,
		FarmState.DAILY_ACTIVITY_DUCK_POND: duck_pond_music_scene,
		FarmState.DAILY_ACTIVITY_MOLE_GARDEN: _get_mole_garden_scene(),
	})


func _process(_delta: float) -> void:
	if _settings_panel != null and _settings_panel.visible:
		return
	if _hub_has_highlighted or FarmState.are_all_daily_chores_completed():
		return
	if _seconds_since_hub_started() >= hub_route_delay:
		_highlight_next_unfinished_chore(false)


func _on_tester_action_requested(action: String, payload: Variant) -> void:
	match action:
		"step_day":
			FarmState.debug_step_day(int(payload))
		"season":
			FarmState.debug_set_farm_date(String(payload), FarmState.get_day_in_season(), FarmState.current_year)
		"season_day":
			FarmState.debug_set_farm_date(FarmState.current_season, int(payload), FarmState.current_year)
		"complete_next":
			FarmState.debug_complete_next_chore()
		"complete_all":
			FarmState.debug_complete_all_chores()
		"unlock_everything":
			FarmState.debug_unlock_everything()
		"reset_today":
			FarmState.debug_reset_today()
		"duck_visited":
			FarmState.debug_mark_duck_pond_visited()
		"reset_farm":
			FarmState.reset_all_state()
	_refresh_hub()


func _unhandled_input(event: InputEvent) -> void:
	if not ChoreCompletionFlowScript.is_tap_event(event):
		return
	if ChoreCompletionFlowScript.is_farmyard_input_locked():
		get_viewport().set_input_as_handled()
		return
	if _day_transition_active:
		get_viewport().set_input_as_handled()
		return
	if _settings_panel != null and _settings_panel.visible:
		get_viewport().set_input_as_handled()
		return
	if _handle_hub_interactable_tap(event):
		return
	if _handle_reward_placement_tap(event):
		return
	if _handle_mole_garden_tap(event):
		return
	var tapped_hotspot := _get_tapped_hotspot(event)
	if tapped_hotspot != null:
		if _handle_completed_chore_hotspot(tapped_hotspot):
			return
		var chore_id := _get_chore_for_hotspot(tapped_hotspot)
		_try_enter_chore_scene(chore_id, _get_scene_for_chore(chore_id))
		return
	get_viewport().set_input_as_handled()
	if not _is_event_inside_design_safe_area(event):
		_highlight_next_unfinished_chore(true)
		return
	_handle_background_tap()


func _refresh_hub(_value = null) -> void:
	if _day_label != null:
		_day_label.text = tr("Year %d - Day %d") % [FarmState.current_year, FarmState.current_day]
	if _season_label != null:
		_season_label.text = FarmState.get_season_display_name()
	if _season_icon != null:
		_season_icon.texture = _get_season_icon()
	if _summary_label != null:
		var completed_count := FarmState.get_completed_chore_count()
		_summary_label.text = tr("Chores: %d/5") % completed_count
	if FarmState.STICKERS_ENABLED and _sticker_badge != null:
		_sticker_badge.text = tr("Stickers: %d") % FarmState.get_total_sticker_count()
		_sticker_badge.visible = FarmState.get_total_sticker_count() > 0 or FarmState.are_all_daily_chores_completed()

	if _next_day_button != null:
		_next_day_button.disabled = false
		_next_day_button.text = ""

	if _chicken_badge != null:
		_chicken_badge.visible = FarmState.is_chore_completed(FarmState.CHORE_EGGS)
	if _milking_badge != null:
		_milking_badge.visible = FarmState.is_chore_completed(FarmState.CHORE_MILKING)
	if _garden_badge != null:
		_garden_badge.visible = FarmState.is_chore_completed(FarmState.CHORE_GARDEN)
	if _feeding_badge != null:
		_feeding_badge.visible = FarmState.is_chore_completed(FarmState.CHORE_FEEDING)
	if _brushing_badge != null:
		_brushing_badge.visible = FarmState.is_chore_completed(FarmState.CHORE_BRUSHING)

	_set_visual_tint(_chicken_visual, FarmState.is_chore_completed(FarmState.CHORE_EGGS))
	_set_visual_tint(_milking_visual, FarmState.is_chore_completed(FarmState.CHORE_MILKING))
	_set_visual_tint(_garden_visual, FarmState.is_chore_completed(FarmState.CHORE_GARDEN))
	_set_visual_tint(_feeding_visual, FarmState.is_chore_completed(FarmState.CHORE_FEEDING))
	_set_visual_tint(_brushing_visual, FarmState.is_chore_completed(FarmState.CHORE_BRUSHING))
	_refresh_reward_progression_visuals()
	if _duck_pond_node != null and FarmState.is_duck_pond_visited_today():
		_duck_pond_node.modulate = Color("b7ffb0")
	if _mole_garden_hotspot != null and FarmState.is_mole_garden_visited_today():
		_mole_garden_hotspot.modulate = Color("b7ffb0")

	if _goat_node != null:
		_goat_node.visible = FarmState.has_unlock("goat_friend")

	_refresh_brushing_stall_feedback()
	_refresh_garden_preview()
	_apply_seasonal_visuals()
	_refresh_winter_decoration_visibility()
	_refresh_ambient_life()

	if _season_tint != null:
		_season_tint.color = _get_season_color()

	_check_for_new_reward_events()


func _on_chore_completed(chore_id: String) -> void:
	FarmFeedback.flash_label(_feedback_label, _get_chore_completion_message(chore_id), Color("fef6a6"), 1.0)
	var visual := _get_visual_for_chore(chore_id)
	if visual is Node2D:
		FarmFeedback.celebrate(self, (visual as Node2D).global_position, 16)
	_refresh_hub()


func _on_sticker_awarded(sticker_id: String) -> void:
	var sticker_name := FarmState.get_sticker_name(sticker_id)
	FarmFeedback.flash_label(_feedback_label, tr("You earned a %s sticker!") % sticker_name, Color("fff2b3"), 1.3)
	if _sticker_badge != null:
		_sticker_badge.visible = true
		FarmFeedback.pulse(_sticker_badge, 1.08, 0.16)
	FarmFeedback.celebrate(self, Vector2(960.0, 220.0), 18)


func _on_unlocks_changed() -> void:
	_refresh_hub()


func _on_garden_plot_changed(_plot_index: int, _plot_data: Dictionary) -> void:
	_refresh_garden_preview()


func _on_ambient_chicken_tapped(chicken: BouncyCritter) -> void:
	if chicken == null or not is_instance_valid(chicken):
		return
	if _is_descendant_of(chicken, _ambient_cow_root):
		chicken.hop()
		return
	var now := Time.get_ticks_msec()
	if float(now - _last_animal_greet_msec) / 1000.0 < animal_greet_cooldown_seconds:
		return
	_last_animal_greet_msec = now
	chicken.hop()
	if _feedback_label != null:
		var name := chicken.critter_name
		if name.is_empty():
			name = "farm friend"
		FarmFeedback.flash_label(_feedback_label, tr("Hello, %s!") % name, Color("e8ffd1"), 0.65)


func _is_descendant_of(node: Node, possible_parent: Node) -> bool:
	if node == null or possible_parent == null:
		return false
	var current := node
	while current != null:
		if current == possible_parent:
			return true
		current = current.get_parent()
	return false


func _prepare_manual_hotspot_routing() -> void:
	# FarmyardScene routes hotspots after hub-life objects, so overlapping critters
	# can consume taps before a broad toddler-friendly hotspot claims them.
	for hotspot in _get_hotspots():
		hotspot.input_pickable = false
		_set_descendant_controls_mouse_filter(hotspot, Control.MOUSE_FILTER_IGNORE)


func _handle_hub_interactable_tap(event: InputEvent) -> bool:
	if _handle_spring_geese_tap(event):
		return true
	if _handle_santa_tap(event):
		return true
	if _handle_duck_pond_tap(event):
		return true
	if _handle_rainbow_tree_tap(event):
		return true
	if _handle_windmill_tap(event):
		return true
	if _handle_interactable_area_tap(_ambient_chicken_root, event):
		return true
	if _handle_interactable_area_tap(_ambient_cow_root, event):
		return true
	if _handle_interactable_area_tap(_bee_root, event):
		return true
	if _handle_interactable_area_tap(_butterfly_root, event):
		return true
	return false


func _handle_interactable_area_tap(node: Node, event: InputEvent) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	var canvas_item := node as CanvasItem
	if canvas_item != null and not canvas_item.is_visible_in_tree():
		return false

	var area := node as Area2D
	if area != null:
		if ChoreCompletionFlowScript.is_event_inside_area(event, area, self, hub_interactable_touch_margin):
			if area.has_method("handle_tap"):
				area.call("handle_tap")
			else:
				get_viewport().set_input_as_handled()
			return true

	for child in node.get_children():
		if _handle_interactable_area_tap(child, event):
			return true
	return false


func _handle_santa_tap(event: InputEvent) -> bool:
	if _santa_flyer_root == null or not is_instance_valid(_santa_flyer_root):
		return false
	var santa_item := _santa_flyer_root as CanvasItem
	if santa_item != null and not santa_item.is_visible_in_tree():
		return false
	if not _handle_interactable_area_tap(_santa_flyer_root, event):
		return false
	if _santa_flyer_root.has_method("handle_tap"):
		_santa_flyer_root.call("handle_tap")
	return true


func _handle_mole_garden_tap(event: InputEvent) -> bool:
	if _mole_garden_hotspot == null or not is_instance_valid(_mole_garden_hotspot):
		return false
	if not _mole_garden_hotspot.is_visible_in_tree():
		return false
	if not _hotspot_contains_position(_mole_garden_hotspot, _get_tap_world_position(event)):
		return false
	get_viewport().set_input_as_handled()
	if FarmState.is_mole_garden_visited_today():
		FarmFeedback.flash_label(_feedback_label, tr("The mole garden was visited today."), Color("e8ffd1"), 0.9)
		FarmFeedback.pulse(_mole_garden_hotspot, 1.04, 0.12)
		return true
	if SceneNavigator.go_to_activity(FarmState.DAILY_ACTIVITY_MOLE_GARDEN, _get_mole_garden_scene()):
		return true
	_mole_garden_hotspot.call("handle_tap")
	return true


func _handle_windmill_tap(event: InputEvent) -> bool:
	if _windmill_node == null or not is_instance_valid(_windmill_node):
		return false
	if not _windmill_node.is_visible_in_tree():
		return false
	if not _canvas_item_contains_tap(_windmill_node, event, 28.0):
		return false
	get_viewport().set_input_as_handled()
	if _windmill_node.has_method("handle_tap"):
		_windmill_node.call("handle_tap")
	else:
		FarmFeedback.pulse(_windmill_node, 1.02, 0.08)
		FarmFeedback.flash(_windmill_node, Color(1.08, 1.08, 1.02, 1.0), 0.08)
	return true


func _handle_rainbow_tree_tap(event: InputEvent) -> bool:
	if _rainbow_tree_node == null or not is_instance_valid(_rainbow_tree_node):
		return false
	if not _rainbow_tree_node.is_visible_in_tree():
		return false
	if not _canvas_item_contains_tap(_rainbow_tree_node, event, 34.0):
		return false
	get_viewport().set_input_as_handled()
	if _rainbow_tree_node.has_method("handle_tap"):
		_rainbow_tree_node.call("handle_tap")
	else:
		FarmFeedback.pulse(_rainbow_tree_node, 1.02, 0.08)
		FarmFeedback.flash(_rainbow_tree_node, Color(1.08, 1.08, 1.02, 1.0), 0.08)
	return true


func _set_descendant_controls_mouse_filter(node: Node, mouse_filter: int) -> void:
	for child in node.get_children():
		var control := child as Control
		if control != null:
			control.mouse_filter = mouse_filter
		_set_descendant_controls_mouse_filter(child, mouse_filter)


func _get_world_fit_roots() -> Array[Node2D]:
	var roots: Array[Node2D] = []
	for path in ["BackgroundLayers", "ActivityAreas", "Decorations", "AmbientLife"]:
		var root := get_node_or_null(path) as Node2D
		if root != null:
			roots.append(root)
	if _placement_zone_root != null and is_instance_valid(_placement_zone_root):
		roots.append(_placement_zone_root)
	return roots


func _cache_world_fit_transforms() -> void:
	for root in _get_world_fit_roots():
		if root == null or _world_fit_root_transforms.has(root):
			continue
		_world_fit_root_transforms[root] = {
			"position": root.position,
			"scale": root.scale,
		}


func _apply_world_fit() -> void:
	if not world_fit_enabled:
		_restore_world_fit_transforms()
		return
	if design_viewport_size.x <= 0.0 or design_viewport_size.y <= 0.0:
		return

	var visible_size := get_viewport_rect().size
	if visible_size.x <= 0.0 or visible_size.y <= 0.0:
		return

	var scale_factor := maxf(
		visible_size.x / design_viewport_size.x,
		visible_size.y / design_viewport_size.y
	)
	var visible_center := visible_size * 0.5
	var design_center := design_viewport_size * 0.5

	for root in _get_world_fit_roots():
		if root == null or not is_instance_valid(root):
			continue
		if not _world_fit_root_transforms.has(root):
			_world_fit_root_transforms[root] = {
				"position": root.position,
				"scale": root.scale,
			}
		var original: Dictionary = _world_fit_root_transforms[root]
		var original_position := original.get("position", root.position) as Vector2
		var original_scale := original.get("scale", root.scale) as Vector2
		root.scale = original_scale * scale_factor
		root.position = visible_center - (design_center - original_position) * scale_factor


func _restore_world_fit_transforms() -> void:
	for root in _world_fit_root_transforms.keys():
		if root == null or not is_instance_valid(root):
			continue
		var original: Dictionary = _world_fit_root_transforms[root]
		root.position = original.get("position", root.position)
		root.scale = original.get("scale", root.scale)


func _advance_day() -> void:
	if _day_transition_active:
		return
	if not FarmState.are_all_daily_chores_completed():
		var remaining_chore := FarmState.get_next_unfinished_chore_id()
		FarmFeedback.flash_label(_feedback_label, tr("Let's finish today's chores first!"), Color("fff2b3"), 1.0)
		_highlight_next_unfinished_chore(true)
		if not remaining_chore.is_empty():
			FarmFeedback.pulse(_get_visual_for_chore(remaining_chore), 1.04, 0.16)
		return

	var previous_year := FarmState.current_year
	if next_day_transition_enabled and _night_transition_root != null and _night_transition_root.has_method("play_transition"):
		_day_transition_active = true
		_set_night_mode_active(true)
		if _next_day_button != null:
			_next_day_button.disabled = true
		_night_transition_root.call("play_transition", FarmState.get_day_in_season())
		var transition_duration := 4.2
		if _night_transition_root.has_method("get_transition_duration"):
			transition_duration = float(_night_transition_root.call("get_transition_duration"))
		await get_tree().create_timer(transition_duration).timeout
		_set_night_mode_active(false)
		_day_transition_active = false

	_finish_advance_day(previous_year)


func _finish_advance_day(previous_year: int) -> void:
	if not FarmState.advance_day():
		if _next_day_button != null:
			_next_day_button.disabled = false
		return

	_hub_failed_taps = 0
	_hub_started_msec = Time.get_ticks_msec()
	_hub_has_highlighted = false
	FarmFeedback.play_one_shot(self, next_day_sound, -4.0)
	var message := "A brand new farm day begins!"
	if FarmState.current_year > previous_year:
		message = "Year %d begins with a bright spring farm!" % FarmState.current_year
	FarmFeedback.flash_label(_feedback_label, message, Color("d7fbff"), 1.0)
	FarmFeedback.pulse(_next_day_button, 1.04, 0.16)
	FarmFeedback.celebrate(self, Vector2(960.0, 300.0), 14)


func _handle_background_tap() -> void:
	if not GameSettings.is_tap_anywhere_chore_return_enabled():
		return
	if FarmState.are_all_daily_chores_completed():
		_advance_day()
		return

	_hub_failed_taps += 1
	if not _hub_has_highlighted:
		_highlight_next_unfinished_chore(false)
		return

	if _hub_failed_taps >= hub_route_failed_taps or _seconds_since_hub_started() >= hub_route_delay:
		_route_to_next_unfinished_chore()
	else:
		_highlight_next_unfinished_chore(_hub_failed_taps >= 2)


func _route_to_next_unfinished_chore() -> void:
	var chore_id := FarmState.get_next_unfinished_chore_id()
	if chore_id.is_empty():
		_advance_day()
		return

	var target_scene := _get_scene_for_chore(chore_id)
	if target_scene == null:
		_advance_day()
		return
	_try_enter_chore_scene(chore_id, target_scene)


func _handle_completed_chore_hotspot(hotspot: SceneHotspot) -> bool:
	var chore_id := _get_chore_for_hotspot(hotspot)
	if chore_id.is_empty() or not FarmState.is_chore_completed(chore_id):
		return false
	get_viewport().set_input_as_handled()
	var target := _get_visual_for_chore(chore_id)
	var feedback_target: CanvasItem = target if target != null else hotspot
	FarmFeedback.pulse(feedback_target, 1.04, 0.14)
	FarmFeedback.flash(feedback_target, Color("e8ffd1"), 0.1)
	FarmFeedback.flash_label(_feedback_label, tr("That chore is done for today."), Color("e8ffd1"), 0.8)
	return true


func _try_enter_chore_scene(chore_id: String, target_scene: PackedScene) -> bool:
	get_viewport().set_input_as_handled()
	if chore_id.is_empty() or target_scene == null:
		return false
	if _is_chore_entry_cooling_down():
		return false
	_save_farmyard_runtime_state()
	FarmState.save_state()
	if SceneNavigator.go_to_activity(chore_id, target_scene):
		return true
	get_tree().change_scene_to_packed(target_scene)
	return true


func _is_chore_entry_cooling_down() -> bool:
	return Time.get_ticks_msec() < _chore_entry_unlocked_msec


func _save_farmyard_runtime_state() -> void:
	var state := {
		"current_day": FarmState.current_day,
		"current_year": FarmState.current_year,
		"current_season": FarmState.current_season,
		"saved_msec": Time.get_ticks_msec(),
		"ambient_chase": _get_node_runtime_state(get_node_or_null("AmbientLife/CatMouseChase")),
		"santa": _get_node_runtime_state(_santa_flyer_root),
	}
	FarmState.set_farmyard_runtime_state(state)


func _restore_farmyard_runtime_state() -> void:
	var state := FarmState.get_farmyard_runtime_state()
	if state.is_empty():
		return
	if int(state.get("current_day", -1)) != FarmState.current_day:
		FarmState.clear_farmyard_runtime_state()
		return
	if int(state.get("current_year", -1)) != FarmState.current_year:
		FarmState.clear_farmyard_runtime_state()
		return
	if String(state.get("current_season", "")) != FarmState.current_season:
		FarmState.clear_farmyard_runtime_state()
		return
	_apply_node_runtime_state(get_node_or_null("AmbientLife/CatMouseChase"), state.get("ambient_chase", {}))
	_apply_node_runtime_state(_santa_flyer_root, state.get("santa", {}))


func _get_node_runtime_state(node: Node) -> Dictionary:
	if node == null or not is_instance_valid(node) or not node.has_method("get_runtime_state"):
		return {}
	return node.call("get_runtime_state") as Dictionary


func _apply_node_runtime_state(node: Node, raw_state: Variant) -> void:
	if node == null or not is_instance_valid(node) or not node.has_method("apply_runtime_state"):
		return
	if not (raw_state is Dictionary):
		return
	node.call("apply_runtime_state", raw_state)


func _get_chore_for_hotspot(hotspot: SceneHotspot) -> String:
	if hotspot == _chicken_hotspot:
		return FarmState.CHORE_EGGS
	if hotspot == _milking_hotspot:
		return FarmState.CHORE_MILKING
	if hotspot == _garden_hotspot:
		return FarmState.CHORE_GARDEN
	if hotspot == _feeding_hotspot:
		return FarmState.CHORE_FEEDING
	if hotspot == _brushing_hotspot:
		return FarmState.CHORE_BRUSHING
	return ""


func _highlight_next_unfinished_chore(strong: bool) -> void:
	var chore_id := FarmState.get_next_unfinished_chore_id()
	if chore_id.is_empty():
		FarmFeedback.assist_hint(_next_day_button, strong)
		return

	var target := _get_visual_for_chore(chore_id)
	if target != null:
		FarmFeedback.assist_hint(target, strong)
	_hub_has_highlighted = true


func _open_settings() -> void:
	if _settings_panel == null:
		return
	_settings_panel.call("open")


func _get_scene_for_chore(chore_id: String) -> PackedScene:
	match chore_id:
		FarmState.CHORE_EGGS:
			return egg_scene
		FarmState.CHORE_MILKING:
			return milking_scene
		FarmState.CHORE_GARDEN:
			return garden_scene
		FarmState.CHORE_FEEDING:
			return feeding_scene
		FarmState.CHORE_BRUSHING:
			return brushing_scene
		_:
			return null


func _get_mole_garden_scene() -> PackedScene:
	if _mole_garden_hotspot != null:
		return _mole_garden_hotspot.target_scene
	return null


func _get_visual_for_chore(chore_id: String) -> CanvasItem:
	match chore_id:
		FarmState.CHORE_EGGS:
			return _chicken_visual
		FarmState.CHORE_MILKING:
			return _milking_visual
		FarmState.CHORE_GARDEN:
			return _garden_visual
		FarmState.CHORE_FEEDING:
			return _feeding_visual
		FarmState.CHORE_BRUSHING:
			return _brushing_visual
		_:
			return null


func _get_chore_completion_message(chore_id: String) -> String:
	return FarmState.get_chore_completion_message(chore_id)


func _celebrate_reward_unlock(reward_id: String) -> void:
	var reward_node := _get_reward_node(reward_id)
	var origin := Vector2(960.0, 540.0)
	if reward_node is Node2D:
		origin = (reward_node as Node2D).global_position
	FarmFeedback.celebrate(self, origin, 18)
	FarmFeedback.flash_label(_feedback_label, _get_reward_message(reward_id), Color("e8ffd1"), 1.2)


func _get_reward_node(reward_id: String) -> CanvasItem:
	match reward_id:
		"flower_bed":
			return _flower_bed_node
		"prettier_fence":
			return _prettier_fence_node
		"goat_friend":
			return _goat_node
		"hay_bales":
			return _hay_bales_node
		"geese_pond":
			return _spring_geese_root as CanvasItem
		"duck_pond":
			return _duck_pond_node
		"rainbow_tree":
			return _rainbow_tree_node
		"windmill":
			return _windmill_node
		_:
			return null


func _cache_reward_node_defaults() -> void:
	for reward_id in VISUAL_REWARD_IDS:
		var reward_node := _get_reward_node(reward_id)
		if reward_node == null:
			continue
		_reward_default_modulates[reward_id] = reward_node.modulate
		if reward_node is Node2D:
			var node_2d := reward_node as Node2D
			_reward_default_positions[reward_id] = node_2d.position
			_reward_default_scales[reward_id] = node_2d.scale


func _build_reward_placement_ui() -> void:
	_placement_zone_root = Node2D.new()
	_placement_zone_root.name = "RewardPlacementZones"
	_placement_zone_root.z_index = 85
	add_child(_placement_zone_root)

	for slot_id in REWARD_SLOT_RECTS.keys():
		var rect: Rect2 = REWARD_SLOT_RECTS[slot_id]
		var zone := Polygon2D.new()
		zone.name = "RewardZone_%s" % slot_id
		zone.polygon = PackedVector2Array([
			rect.position,
			rect.position + Vector2(rect.size.x, 0.0),
			rect.position + rect.size,
			rect.position + Vector2(0.0, rect.size.y),
		])
		zone.color = Color(1.0, 0.92, 0.35, 0.25)
		zone.visible = false
		_placement_zone_root.add_child(zone)
		_placement_zone_items[slot_id] = zone

		var outline := Line2D.new()
		outline.name = "Outline"
		outline.points = PackedVector2Array([
			rect.position,
			rect.position + Vector2(rect.size.x, 0.0),
			rect.position + rect.size,
			rect.position + Vector2(0.0, rect.size.y),
			rect.position,
		])
		outline.width = 6.0
		outline.default_color = Color(1.0, 0.78, 0.18, 0.72)
		zone.add_child(outline)

	var hud := get_node_or_null("Hud") as CanvasLayer
	if hud == null:
		return

	_reward_tray_button = Button.new()
	_reward_tray_button.name = "RewardTrayButton"
	_reward_tray_button.offset_left = 56.0
	_reward_tray_button.offset_top = 840.0
	_reward_tray_button.offset_right = 440.0
	_reward_tray_button.offset_bottom = 930.0
	_reward_tray_button.focus_mode = Control.FOCUS_NONE
	_reward_tray_button.visible = false
	_reward_tray_button.text = tr("Reward Tray")
	_reward_tray_button.add_theme_font_size_override("font_size", 28)
	_reward_tray_button.pressed.connect(_select_next_pending_reward)
	hud.add_child(_reward_tray_button)


func _build_sticker_badge() -> void:
	var hud := get_node_or_null("Hud") as CanvasLayer
	if hud == null:
		return
	_sticker_badge = Label.new()
	_sticker_badge.name = "DailyStickerBadge"
	_sticker_badge.offset_left = 60.0
	_sticker_badge.offset_top = 318.0
	_sticker_badge.offset_right = 360.0
	_sticker_badge.offset_bottom = 364.0
	_sticker_badge.visible = false
	_sticker_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sticker_badge.add_theme_color_override("font_color", Color("6b3f24"))
	_sticker_badge.add_theme_color_override("font_outline_color", Color("fff4cf"))
	_sticker_badge.add_theme_constant_override("outline_size", 5)
	_sticker_badge.add_theme_font_size_override("font_size", 28)
	hud.add_child(_sticker_badge)


func _refresh_reward_progression_visuals() -> void:
	_reset_reward_visuals()
	match FarmState.progression_design:
		PROGRESSION_DESIGN_PLAYER_PLACED:
			_refresh_player_placed_rewards()
		PROGRESSION_DESIGN_REWARD_MOMENTS:
			_refresh_reward_moment_visuals()
		_:
			_refresh_area_evolution_visuals()


func _reset_reward_visuals() -> void:
	for reward_id in VISUAL_REWARD_IDS:
		var reward_node := _get_reward_node(reward_id)
		if reward_node == null:
			continue
		reward_node.visible = false
		reward_node.modulate = _reward_default_modulates.get(reward_id, Color.WHITE)
		if reward_node is Node2D:
			var node_2d := reward_node as Node2D
			node_2d.position = _reward_default_positions.get(reward_id, node_2d.position)
			node_2d.scale = _reward_default_scales.get(reward_id, node_2d.scale)


func _refresh_player_placed_rewards() -> void:
	var placed_rewards := FarmState.get_placed_rewards()
	for reward_id in placed_rewards.keys():
		_show_reward_at_slot(String(reward_id), String(placed_rewards[reward_id]))
	_refresh_reward_tray_button()


func _refresh_area_evolution_visuals() -> void:
	for reward_id in FarmState.get_unlocked_reward_ids():
		_show_reward_at_default_slot(reward_id)
	_refresh_reward_tray_button(false)


func _refresh_reward_moment_visuals() -> void:
	for reward_id in FarmState.get_unlocked_reward_ids():
		_show_reward_at_default_slot(reward_id)
	_refresh_reward_tray_button(false)


func _show_reward_at_default_slot(reward_id: String) -> void:
	var slot_id := String(DEFAULT_REWARD_SLOTS.get(reward_id, ""))
	if slot_id.is_empty():
		var reward_node := _get_reward_node(reward_id)
		if reward_node != null:
			reward_node.visible = true
		return
	_show_reward_at_slot(reward_id, slot_id)


func _show_reward_at_slot(reward_id: String, slot_id: String) -> void:
	var reward_node := _get_reward_node(reward_id)
	if reward_node == null:
		return

	var safe_slot_id := _get_safe_reward_slot(reward_id, slot_id)
	reward_node.visible = true
	if reward_node is Node2D:
		(reward_node as Node2D).position = _get_reward_slot_position(safe_slot_id)


func _refresh_reward_tray_button(force_hidden := false) -> void:
	_show_placement_zones(false)
	if _reward_tray_button == null:
		return

	var pending_rewards := FarmState.get_pending_placeable_reward_ids()
	var should_show := (
		not force_hidden
		and FarmState.progression_design == PROGRESSION_DESIGN_PLAYER_PLACED
		and not pending_rewards.is_empty()
	)
	_reward_tray_button.visible = should_show
	if not should_show:
		_selected_placeable_reward_id = ""
		return

	if _selected_placeable_reward_id.is_empty():
		_reward_tray_button.text = tr("Reward Tray (%d)") % pending_rewards.size()
	else:
		_reward_tray_button.text = tr("Placing: %s") % FarmState.get_reward_name(_selected_placeable_reward_id)
		_show_placement_zones(true)


func _select_next_pending_reward() -> void:
	var pending_rewards := FarmState.get_pending_placeable_reward_ids()
	if pending_rewards.is_empty():
		_selected_placeable_reward_id = ""
		_refresh_reward_tray_button()
		FarmFeedback.flash_label(_feedback_label, tr("The reward tray is resting for now."), Color("fff2b3"), 0.9)
		return

	var current_index := pending_rewards.find(_selected_placeable_reward_id)
	_selected_placeable_reward_id = pending_rewards[(current_index + 1) % pending_rewards.size()]
	_refresh_reward_tray_button()
	FarmFeedback.flash_label(
		_feedback_label,
		tr("Tap a glowing farm spot for %s.") % FarmState.get_reward_name(_selected_placeable_reward_id),
		Color("e8ffd1"),
		1.0
	)


func _handle_reward_placement_tap(event: InputEvent) -> bool:
	if FarmState.progression_design != PROGRESSION_DESIGN_PLAYER_PLACED:
		return false
	if _selected_placeable_reward_id.is_empty():
		return false

	var tap_position := _get_tap_world_position(event)
	if tap_position == Vector2.INF:
		return false

	get_viewport().set_input_as_handled()
	var slot_id := _get_reward_slot_at_position(tap_position)
	if slot_id.is_empty():
		FarmFeedback.flash_label(_feedback_label, tr("Pick one of the glowing farm spots."), Color("fff2b3"), 0.9)
		_show_placement_zones(true)
		return true

	if FarmState.place_reward(_selected_placeable_reward_id, slot_id):
		var reward_name := FarmState.get_reward_name(_selected_placeable_reward_id)
		var celebration_position := _get_reward_slot_position(slot_id)
		FarmFeedback.flash_label(_feedback_label, tr("%s found a cozy spot!") % reward_name, Color("e8ffd1"), 1.1)
		FarmFeedback.celebrate(self, celebration_position, 16)
		_selected_placeable_reward_id = ""
		_refresh_hub()
	else:
		FarmFeedback.flash_label(_feedback_label, tr("That cozy spot is already full."), Color("fff2b3"), 0.9)
		_show_placement_zones(true)
	return true


func _handle_spring_geese_tap(event: InputEvent) -> bool:
	if FarmState.current_season != "spring" or _spring_geese_root == null:
		return false
	if not _spring_geese_root.has_method("try_handle_tap"):
		return false
	return bool(_spring_geese_root.call("try_handle_tap", event))


func _handle_duck_pond_tap(event: InputEvent) -> bool:
	if duck_pond_music_scene == null:
		return false
	if not FarmState.has_unlock("duck_pond") or _duck_pond_node == null or not _duck_pond_node.is_visible_in_tree():
		return false
	if not _canvas_item_contains_tap(_duck_pond_node, event, 34.0):
		return false
	get_viewport().set_input_as_handled()
	if FarmState.is_duck_pond_visited_today():
		FarmFeedback.flash_label(_feedback_label, tr("The ducks are cared for today."), Color("e8ffd1"), 0.9)
		FarmFeedback.pulse(_duck_pond_node, 1.04, 0.12)
		return true
	if SceneNavigator.go_to_activity(FarmState.DAILY_ACTIVITY_DUCK_POND, duck_pond_music_scene):
		return true
	get_tree().change_scene_to_packed(duck_pond_music_scene)
	return true


func _handle_seasonal_surprise_tap(event: InputEvent) -> bool:
	if _seasonal_surprises_root == null or not _seasonal_surprises_root.has_method("try_handle_tap"):
		return false
	return bool(_seasonal_surprises_root.call("try_handle_tap", event))


func _get_reward_slot_at_position(global_position: Vector2) -> String:
	for slot_id in REWARD_SLOT_RECTS.keys():
		if not _can_place_reward_in_slot(_selected_placeable_reward_id, String(slot_id)):
			continue
		var rect: Rect2 = REWARD_SLOT_RECTS[slot_id]
		if rect.has_point(global_position):
			return String(slot_id)
	return ""


func _show_placement_zones(visible: bool) -> void:
	for slot_id in _placement_zone_items.keys():
		var zone := _placement_zone_items[slot_id] as CanvasItem
		if zone == null:
			continue
		zone.visible = (
			visible
			and _can_place_reward_in_slot(_selected_placeable_reward_id, String(slot_id))
			and not _is_reward_slot_used(String(slot_id))
		)


func _is_reward_slot_used(slot_id: String) -> bool:
	var normalized_slot_id := _normalize_reward_slot_id(slot_id)
	var placed_rewards := FarmState.get_placed_rewards()
	for reward_id in placed_rewards.keys():
		if not VISUAL_REWARD_IDS.has(String(reward_id)):
			continue
		var used_slot := _get_safe_reward_slot(String(reward_id), String(placed_rewards[reward_id]))
		if used_slot == normalized_slot_id:
			return true
	return false


func _can_place_reward_in_slot(reward_id: String, slot_id: String) -> bool:
	if reward_id.is_empty():
		return false
	var normalized_slot_id := _normalize_reward_slot_id(slot_id)
	if not _has_reward_slot(normalized_slot_id):
		return false
	var allowed_slots: Array = Array(REWARD_ALLOWED_SLOTS.get(reward_id, []))
	return allowed_slots.is_empty() or allowed_slots.has(normalized_slot_id)


func _get_safe_reward_slot(reward_id: String, slot_id: String) -> String:
	var normalized_slot_id := _normalize_reward_slot_id(slot_id)
	if _can_place_reward_in_slot(reward_id, normalized_slot_id):
		return normalized_slot_id
	return String(DEFAULT_REWARD_SLOTS.get(reward_id, normalized_slot_id))


func _normalize_reward_slot_id(slot_id: String) -> String:
	return String(LEGACY_REWARD_SLOT_MIGRATIONS.get(slot_id, slot_id))


func _has_reward_slot(slot_id: String) -> bool:
	return REWARD_SLOT_POSITIONS.has(slot_id) or REWARD_SLOT_REWARD_IDS.has(slot_id)


func _get_reward_slot_position(slot_id: String) -> Vector2:
	var normalized_slot_id := _normalize_reward_slot_id(slot_id)
	var reward_id := String(REWARD_SLOT_REWARD_IDS.get(normalized_slot_id, ""))
	if not reward_id.is_empty() and _reward_default_positions.has(reward_id):
		return _reward_default_positions[reward_id]
	return REWARD_SLOT_POSITIONS.get(normalized_slot_id, Vector2(960.0, 540.0))


func _check_for_new_reward_events() -> void:
	var reward_ids := FarmState.get_reward_event_ids()
	var new_reward_ids: Array[String] = []
	for reward_id in reward_ids:
		if not _known_reward_ids.has(reward_id):
			new_reward_ids.append(reward_id)
	_known_reward_ids = reward_ids
	for reward_id in new_reward_ids:
		_celebrate_reward_unlock(reward_id)


func _cache_brushing_stall_state_nodes() -> void:
	_brushing_dirty_items.clear()
	_brushing_clean_items.clear()
	for path in brushing_dirty_overlays:
		var item := get_node_or_null(path) as CanvasItem
		if item != null:
			_brushing_dirty_items.append(item)
	for path in brushing_clean_sparkles:
		var item := get_node_or_null(path) as CanvasItem
		if item != null:
			_brushing_clean_items.append(item)


func _cache_garden_preview_nodes() -> void:
	_garden_preview_plots.clear()
	_garden_preview_plants.clear()
	_garden_preview_plot_base_modulates.clear()
	_garden_preview_plant_base_scales.clear()

	for path in garden_preview_plot_nodes:
		var plot := get_node_or_null(path) as Sprite2D
		if plot == null:
			continue
		_garden_preview_plots.append(plot)
		_garden_preview_plot_base_modulates.append(plot.modulate)

	for path in garden_preview_plant_nodes:
		var plant := get_node_or_null(path) as Sprite2D
		if plant == null:
			continue
		_garden_preview_plants.append(plant)
		_garden_preview_plant_base_scales.append(plant.scale)


func _connect_ambient_critters() -> void:
	_connect_bouncy_critter_root(_ambient_chicken_root)
	_connect_bouncy_critter_root(_ambient_cow_root)


func _connect_bouncy_critter_root(root: Node) -> void:
	if root == null:
		return
	for child in root.get_children():
		var critter := child as BouncyCritter
		if critter == null:
			continue
		if not critter.tapped.is_connected(_on_ambient_chicken_tapped):
			critter.tapped.connect(_on_ambient_chicken_tapped)


func _refresh_brushing_stall_feedback() -> void:
	for index in _brushing_dirty_items.size():
		var animal_id := _get_brushing_animal_id(index)
		var unlocked := animal_id != "duck" or FarmState.has_unlock("duck_pond")
		var brushed := FarmState.is_animal_brushed(animal_id)
		_brushing_dirty_items[index].visible = unlocked and not brushed

	for index in _brushing_clean_items.size():
		var animal_id := _get_brushing_animal_id(index)
		var unlocked := animal_id != "duck" or FarmState.has_unlock("duck_pond")
		var brushed := FarmState.is_animal_brushed(animal_id)
		_brushing_clean_items[index].visible = unlocked and brushed

	if _brushing_duck_stall_node != null:
		_brushing_duck_stall_node.visible = FarmState.has_unlock("duck_pond")


func _refresh_garden_preview() -> void:
	for index in _garden_preview_plots.size():
		var plot_data := FarmState.get_plot_data(index)
		var state := String(plot_data.get("state", FarmState.PLOT_EMPTY))
		var watered_today := bool(plot_data.get("watered_today", false))
		var plot := _garden_preview_plots[index]
		plot.modulate = _get_garden_preview_soil_color(state, watered_today)

		if index >= _garden_preview_plants.size():
			continue
		var plant := _garden_preview_plants[index]
		var texture := _get_garden_preview_plant_texture(state)
		plant.visible = texture != null
		if texture != null:
			plant.texture = texture
		plant.modulate = _get_garden_preview_plant_color(state)
		if index < _garden_preview_plant_base_scales.size():
			plant.scale = _garden_preview_plant_base_scales[index] * _get_garden_preview_scale_multiplier(state)


func _apply_seasonal_visuals() -> void:
	var using_seasonal_base := _apply_seasonal_base_texture()
	_apply_seasonal_icon_textures()

	for season in _seasonal_overlays.keys():
		var overlay := _seasonal_overlays[season] as CanvasItem
		if overlay != null:
			# The generated seasonal base art is now the primary seasonal read.
			# Legacy overlays remain as a fallback if that texture cannot load.
			overlay.visible = not using_seasonal_base and String(season) == FarmState.current_season


func _cache_seasonal_visual_defaults() -> void:
	_cache_default_texture("chicken", _chicken_visual)
	_cache_default_texture("milking", _milking_visual)
	_cache_default_texture("feeding", _feeding_visual)
	_cache_default_texture("brushing", _brushing_visual)
	_cache_default_texture("garden_fence", _garden_fence_visual)
	_cache_default_texture("rainbow_tree", _rainbow_tree_node)
	_cache_default_texture("flower_bed", _flower_bed_node)
	_cache_default_texture("windmill", _windmill_node)


func _cache_default_texture(key: String, item: CanvasItem) -> void:
	var sprite := item as Sprite2D
	if sprite == null or sprite.texture == null:
		return
	_default_seasonal_visual_textures[key] = sprite.texture


func _apply_seasonal_base_texture() -> bool:
	if _seasonal_base_visual == null:
		_set_original_background_layers_visible(true)
		return false

	var texture := _load_seasonal_texture(String(SEASONAL_BASE_TEXTURE_PATHS.get(FarmState.current_season, "")))
	if texture == null:
		_seasonal_base_visual.visible = false
		_set_original_background_layers_visible(true)
		return false

	_seasonal_base_visual.texture = texture
	_seasonal_base_visual.visible = true
	_set_original_background_layers_visible(false)
	return true


func _set_original_background_layers_visible(is_visible: bool) -> void:
	for layer in _original_background_layers:
		if layer != null:
			layer.visible = is_visible and bool(_original_background_layer_visibility.get(layer, layer.visible))


func _cache_original_background_layer_visibility() -> void:
	for layer in _original_background_layers:
		if layer != null:
			_original_background_layer_visibility[layer] = layer.visible


func _apply_seasonal_icon_textures() -> void:
	_apply_seasonal_icon_texture("chicken", _chicken_visual)
	_apply_seasonal_icon_texture("milking", _milking_visual)
	_apply_seasonal_icon_texture("feeding", _feeding_visual)
	_apply_seasonal_icon_texture("brushing", _brushing_visual)
	_apply_seasonal_icon_texture("garden_fence", _garden_fence_visual)
	_apply_seasonal_icon_texture("rainbow_tree", _rainbow_tree_node)
	_apply_seasonal_icon_texture("flower_bed", _flower_bed_node)
	_apply_seasonal_icon_texture("windmill", _windmill_node)


func _apply_seasonal_icon_texture(key: String, item: CanvasItem) -> void:
	var sprite := item as Sprite2D
	if sprite == null:
		return

	var season_paths := SEASONAL_ICON_TEXTURE_PATHS.get(key, {}) as Dictionary
	var texture := _load_seasonal_texture(String(season_paths.get(FarmState.current_season, "")))
	if texture == null:
		texture = _default_seasonal_visual_textures.get(key, sprite.texture) as Texture2D
	if texture != null:
		sprite.texture = texture


func _load_seasonal_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _seasonal_texture_cache.has(path):
		return _seasonal_texture_cache[path] as Texture2D

	var texture := load(path) as Texture2D
	_seasonal_texture_cache[path] = texture
	return texture


func _refresh_ambient_life() -> void:
	var bees_enabled := FarmState.current_season != "winter"
	if _bee_root != null:
		_bee_root.visible = bees_enabled
		for child in _bee_root.get_children():
			if child is Area2D:
				(child as Area2D).input_pickable = bees_enabled
			child.set_process(bees_enabled)

	var butterflies_enabled := FarmState.current_season != "winter"
	if _butterfly_root != null:
		_butterfly_root.visible = butterflies_enabled
		for child in _butterfly_root.get_children():
			if child is Area2D:
				(child as Area2D).input_pickable = butterflies_enabled
			child.set_process(butterflies_enabled)

	var geese_pond_unlocked := FarmState.has_unlock("geese_pond")
	if FarmState.progression_design == PROGRESSION_DESIGN_PLAYER_PLACED:
		geese_pond_unlocked = FarmState.get_placed_reward_ids().has("geese_pond")
	var geese_enabled := FarmState.current_season == "spring" and geese_pond_unlocked
	if _spring_geese_root != null:
		_spring_geese_root.call("set_enabled", geese_enabled)
		if _spring_geese_root.has_method("set_pond_visible"):
			_spring_geese_root.call("set_pond_visible", geese_enabled)

	var duck_pond_unlocked := FarmState.has_unlock("duck_pond")
	var ducks_enabled := duck_pond_unlocked and not geese_enabled
	if _duck_pond_play_root != null:
		if _duck_pond_play_root is Node2D and _duck_pond_node is Node2D:
			(_duck_pond_play_root as Node2D).global_position = (_duck_pond_node as Node2D).global_position
		if _duck_pond_play_root.has_method("set_enabled"):
			_duck_pond_play_root.call("set_enabled", ducks_enabled)
		if _duck_pond_play_root.has_method("set_winter_resting"):
			_duck_pond_play_root.call("set_winter_resting", FarmState.current_season == "winter")

	if _santa_flyer_root != null and _santa_flyer_root.has_method("set_enabled"):
		_santa_flyer_root.call("set_enabled", FarmState.current_season == "winter")

	if _seasonal_surprises_root != null and _seasonal_surprises_root.has_method("set_season"):
		_seasonal_surprises_root.call("set_season", FarmState.current_season)

	if _duck_pond_node != null:
		_duck_pond_node.visible = duck_pond_unlocked


func _refresh_winter_decoration_visibility() -> void:
	if _prettier_fence_node != null and FarmState.current_season == "winter":
		_prettier_fence_node.visible = false


func _set_night_mode_active(active: bool) -> void:
	_set_ambient_root_sleeping(_ambient_chicken_root, active)
	_set_ambient_root_sleeping(_ambient_cow_root, active)
	_set_ambient_root_sleeping(_duck_pond_play_root, active)
	_set_ambient_root_sleeping(_spring_geese_root, active)
	if _bee_root != null:
		_bee_root.visible = false if active else FarmState.current_season != "winter"
		_set_ambient_root_process(_bee_root, not active and FarmState.current_season != "winter")
	if _butterfly_root != null:
		_butterfly_root.visible = false if active else FarmState.current_season != "winter"
		_set_ambient_root_process(_butterfly_root, not active and FarmState.current_season != "winter")
	if _seasonal_surprises_root != null:
		_seasonal_surprises_root.visible = not active and FarmState.current_season != "summer"
		_set_ambient_root_process(_seasonal_surprises_root, not active)
	if not active:
		_refresh_ambient_life()


func _set_ambient_root_sleeping(root: Node, sleeping: bool) -> void:
	if root == null:
		return
	var canvas_item := root as CanvasItem
	if canvas_item != null:
		canvas_item.modulate = Color(0.55, 0.62, 0.82, 1.0) if sleeping else Color.WHITE
	_set_ambient_root_process(root, not sleeping)


func _set_ambient_root_process(root: Node, enabled: bool) -> void:
	if root == null:
		return
	root.set_process(enabled)
	for child in root.get_children():
		child.set_process(enabled)
		if child is Area2D:
			(child as Area2D).input_pickable = enabled
		_set_ambient_root_process(child, enabled)


func _get_garden_preview_soil_color(state: String, watered_today: bool) -> Color:
	if FarmState.current_season == "winter":
		return Color("dfe9f2") if state == FarmState.PLOT_EMPTY else Color("c8d9e6")
	if watered_today:
		return Color("9ec5b7")
	match state:
		FarmState.PLOT_HARVESTED:
			return Color("d6b08a")
		FarmState.PLOT_READY_TO_HARVEST:
			return Color("f2c08d")
		_:
			match FarmState.current_season:
				"summer":
					return Color("f0b982")
				"fall":
					return Color("dda56f")
				_:
					return Color("f3c79a")


func _get_garden_preview_plant_texture(state: String) -> Texture2D:
	match state:
		FarmState.PLOT_SEEDED:
			return garden_preview_seed_texture
		FarmState.PLOT_SPROUTING:
			return garden_preview_sprout_texture
		FarmState.PLOT_GROWING:
			return garden_preview_growing_texture
		FarmState.PLOT_READY_TO_HARVEST:
			return garden_preview_ready_texture
		FarmState.PLOT_HARVESTED:
			return garden_preview_harvested_texture
		_:
			return null


func _get_garden_preview_plant_color(state: String) -> Color:
	if FarmState.current_season == "winter":
		return Color("e7f0f6")
	if FarmState.current_season == "fall" and state in [FarmState.PLOT_GROWING, FarmState.PLOT_READY_TO_HARVEST]:
		return Color("ffd08a")
	return Color.WHITE


func _get_garden_preview_scale_multiplier(state: String) -> float:
	match state:
		FarmState.PLOT_SEEDED:
			return 0.72
		FarmState.PLOT_GROWING:
			return 1.08
		FarmState.PLOT_READY_TO_HARVEST:
			return 1.16
		FarmState.PLOT_HARVESTED:
			return 0.9
		_:
			return 1.0


func _get_brushing_animal_id(index: int) -> String:
	if index >= 0 and index < brushing_animal_ids.size():
		return brushing_animal_ids[index]
	return ""


func _get_reward_message(reward_id: String) -> String:
	if FarmState.progression_design == PROGRESSION_DESIGN_PLAYER_PLACED:
		return "A new reward is waiting in the tray: %s!" % FarmState.get_reward_name(reward_id)
	if FarmState.progression_design == PROGRESSION_DESIGN_REWARD_MOMENTS:
		return "%s is ready for the farm!" % FarmState.get_reward_name(reward_id)

	match reward_id:
		"flower_bed":
			return "A flower bed bloomed by the grass!"
		"prettier_fence":
			return "Flowers bloomed along the farm fence!"
		"goat_friend":
			return "A gentle goat friend joined the farm!"
		"hay_bales":
			return "Cozy hay bales are stacked by the fence!"
		"geese_pond":
			return "A little spring pond is ready for geese!"
		"duck_pond":
			return "The pond looks ready for duck friends!"
		"rainbow_tree":
			return "A cheerful tree is growing on the farm!"
		"windmill":
			return "A bright windmill is turning today!"
		_:
			return "The farm got a happy new touch!"


func _get_tapped_hotspot(event: InputEvent) -> SceneHotspot:
	var tap_position := _get_tap_world_position(event)
	if tap_position == Vector2.INF:
		return null

	for hotspot in _get_hotspots():
		if _hotspot_contains_position(hotspot, tap_position):
			return hotspot
	return null


func _get_hotspots() -> Array[SceneHotspot]:
	var hotspots: Array[SceneHotspot] = []
	for hotspot in [_chicken_hotspot, _milking_hotspot, _garden_hotspot, _feeding_hotspot, _brushing_hotspot]:
		if hotspot != null and is_instance_valid(hotspot):
			hotspots.append(hotspot)
	return hotspots


func _get_tap_world_position(event: InputEvent) -> Vector2:
	var viewport_position := ChoreCompletionFlowScript.get_event_position(event)
	if viewport_position == Vector2.INF:
		return Vector2.INF
	return get_canvas_transform().affine_inverse() * viewport_position


func _is_event_inside_design_safe_area(event: InputEvent) -> bool:
	var viewport_position := ChoreCompletionFlowScript.get_event_position(event)
	if viewport_position == Vector2.INF:
		return false
	var visible_size := get_viewport_rect().size
	var safe_rect := Rect2((visible_size - design_viewport_size) * 0.5, design_viewport_size)
	return safe_rect.has_point(viewport_position)


func _hotspot_contains_position(hotspot: SceneHotspot, global_position: Vector2) -> bool:
	if hotspot == null or not hotspot.is_visible_in_tree():
		return false

	for child in hotspot.get_children():
		var collision_shape := child as CollisionShape2D
		if collision_shape == null or collision_shape.disabled or collision_shape.shape == null:
			continue
		if _shape_contains_position(collision_shape, global_position):
			return true
	return false


func _shape_contains_position(collision_shape: CollisionShape2D, global_position: Vector2) -> bool:
	var local_position := collision_shape.to_local(global_position)
	var shape := collision_shape.shape
	if shape is RectangleShape2D:
		var rectangle := shape as RectangleShape2D
		var half_size := rectangle.size * 0.5 + Vector2.ONE * hotspot_touch_margin
		return absf(local_position.x) <= half_size.x and absf(local_position.y) <= half_size.y
	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		return local_position.length() <= circle.radius + hotspot_touch_margin
	return false


func _canvas_item_contains_tap(item: CanvasItem, event: InputEvent, margin: float) -> bool:
	var tap_position := _get_tap_world_position(event)
	if tap_position == Vector2.INF:
		return false
	var sprite := item as Sprite2D
	if sprite != null and sprite.texture != null:
		var local_position := sprite.to_local(tap_position)
		var size := sprite.texture.get_size()
		var centered_position := local_position + size * 0.5
		return Rect2(Vector2.ZERO, size).grow(margin).has_point(centered_position)
	var node_2d := item as Node2D
	if node_2d != null:
		return node_2d.global_position.distance_to(tap_position) <= margin
	return false


func _seconds_since_hub_started() -> float:
	return float(Time.get_ticks_msec() - _hub_started_msec) / 1000.0


func _set_visual_tint(item: CanvasItem, completed: bool) -> void:
	if item == null:
		return
	var completion_color := Color("ffffff") if not completed else Color("b7ffb0")
	var season_color := _get_area_season_modulate()
	item.modulate = Color(
		completion_color.r * season_color.r,
		completion_color.g * season_color.g,
		completion_color.b * season_color.b,
		completion_color.a
	)


func _get_area_season_modulate() -> Color:
	match FarmState.current_season:
		"summer":
			return Color(1.04, 1.0, 0.92, 1.0)
		"fall":
			return Color(1.05, 0.92, 0.78, 1.0)
		"winter":
			return Color(0.88, 0.94, 1.05, 1.0)
		_:
			return Color(1.0, 1.04, 0.98, 1.0)


func _get_season_color() -> Color:
	match FarmState.current_season:
		"spring":
			return Color(0.82, 1.0, 0.85, 0.16)
		"summer":
			return Color(1.0, 0.96, 0.65, 0.12)
		"fall":
			return Color(1.0, 0.82, 0.58, 0.16)
		_:
			return Color(0.84, 0.92, 1.0, 0.22)


func _get_season_icon() -> Texture2D:
	match FarmState.current_season:
		"spring":
			return spring_season_icon
		"summer":
			return summer_season_icon
		"fall":
			return fall_season_icon
		_:
			return winter_season_icon
