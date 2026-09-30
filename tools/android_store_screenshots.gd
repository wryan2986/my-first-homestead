extends SceneTree

const OUTPUT_DIR := "res://_qa_previews/android_store_screenshots"
const DESIGN_SIZE := Vector2i(1920, 1080)
const FARM_STATE_NODE := "/root/FarmState"
const GAME_SETTINGS_NODE := "/root/GameSettings"
const CHORE_EGGS := "eggs"
const CHORE_MILKING := "milking"
const CHORE_GARDEN := "garden"
const CHORE_FEEDING := "feeding"
const CHORE_BRUSHING := "brushing"
const DAILY_ACTIVITY_DUCK_POND := "duck_pond"
const PLOT_EMPTY := "empty"
const PLOT_SEEDED := "seeded"
const PLOT_SPROUTING := "sprouting"
const PLOT_GROWING := "growing"
const PLOT_READY_TO_HARVEST := "ready_to_harvest"
const PLOT_HARVESTED := "harvested"

const SCENARIOS := [
	{
		"id": "01_start_screen",
		"scene": "res://scenes/StartScene.tscn",
		"setup": "_setup_start_screen",
	},
	{
		"id": "02_farmyard_overview",
		"scene": "res://scenes/FarmyardScene.tscn",
		"setup": "_setup_farmyard_overview",
	},
	{
		"id": "03_egg_hunt",
		"scene": "res://scenes/EggCollectingScene.tscn",
		"setup": "_setup_egg_hunt",
	},
	{
		"id": "04_milking_time",
		"scene": "res://scenes/MilkingScene.tscn",
		"setup": "_setup_milking_time",
	},
	{
		"id": "05_garden_care",
		"scene": "res://scenes/WateringScene.tscn",
		"setup": "_setup_garden_care",
	},
	{
		"id": "06_feeding_friends",
		"scene": "res://scenes/FeedingScene.tscn",
		"setup": "_setup_feeding_friends",
	},
	{
		"id": "07_brushing_barn",
		"scene": "res://scenes/BrushingScene.tscn",
		"setup": "_setup_brushing_barn",
	},
	{
		"id": "08_duck_pond",
		"scene": "res://scenes/DuckPondMusicScene.tscn",
		"setup": "_setup_duck_pond",
	},
	{
		"id": "09_mole_game",
		"scene": "res://scenes/MoleGardenScene.tscn",
		"setup": "_setup_mole_game",
	},
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for scenario in SCENARIOS:
		_prepare_state(String(scenario["setup"]))
		var packed := load(String(scenario["scene"])) as PackedScene
		if packed == null:
			push_error("Could not load %s" % String(scenario["scene"]))
			continue
		await _capture_scene(String(scenario["id"]), packed)
		packed = null
	_clear_scene_navigator_cache()
	await process_frame
	print("ANDROID_STORE_SCREENSHOTS_OK")
	quit()


func _capture_scene(scenario_id: String, packed: PackedScene) -> void:
	var viewport := SubViewport.new()
	viewport.size = DESIGN_SIZE
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	root.add_child(viewport)

	var scene := packed.instantiate()
	viewport.add_child(scene)

	for _i in 5:
		await process_frame

	var image := viewport.get_texture().get_image()
	var output_path := ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, scenario_id])
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Could not save %s: %s" % [output_path, error])

	viewport.queue_free()
	await process_frame


func _clear_scene_navigator_cache() -> void:
	var scene_navigator := root.get_node_or_null("SceneNavigator")
	if scene_navigator != null and scene_navigator.has_method("clear_activity_cache"):
		scene_navigator.call("clear_activity_cache")


func _prepare_state(setup_method: String) -> void:
	_reset_state()
	call(setup_method)
	var farm_state: Node = _farm_state()
	if farm_state == null:
		return
	farm_state.emit_signal("farm_state_changed")
	farm_state.emit_signal("day_changed", farm_state.get("current_day"))
	farm_state.emit_signal("year_changed", farm_state.get("current_year"))
	farm_state.emit_signal("season_changed", farm_state.get("current_season"))
	farm_state.emit_signal("unlocks_changed")


func _reset_state() -> void:
	var farm_state: Node = _farm_state()
	if farm_state == null:
		return
	farm_state.set("current_season", "spring")
	farm_state.set("current_day", 1)
	farm_state.set("current_year", 1)
	farm_state.set("total_chore_completions", 0)
	farm_state.set("progression_design", "farm_area_evolution")
	farm_state.set("reward_inventory", [])
	farm_state.set("placed_rewards", {})
	farm_state.set("sticker_collection", {})
	farm_state.set("daily_sticker_awarded", false)
	farm_state.set("today_completion_history", [])
	farm_state.set("farmyard_runtime_state", {})
	farm_state.set("unlock_progress", {
		"flower_bed": false,
		"prettier_fence": false,
		"goat_friend": false,
		"hay_bales": false,
		"geese_pond": false,
		"strawberry_crop": false,
		"duck_pond": false,
		"rainbow_tree": false,
		"windmill": false,
	})
	farm_state.set("daily_chore_states", {
		CHORE_EGGS: false,
		CHORE_MILKING: false,
		CHORE_GARDEN: false,
		CHORE_FEEDING: false,
		CHORE_BRUSHING: false,
	})
	farm_state.set("daily_activity_states", {
		DAILY_ACTIVITY_DUCK_POND: false,
	})
	farm_state.set("daily_progress", {
		CHORE_EGGS: {"collected": []},
		CHORE_MILKING: {"amount": 0},
		CHORE_GARDEN: {"actions": 0, "winter_rest_checked": false},
		CHORE_FEEDING: {"fed_animals": []},
		CHORE_BRUSHING: {"brushed_animals": []},
	})
	farm_state.set("garden_plots", _make_empty_garden())


func _setup_start_screen() -> void:
	var farm_state: Node = _farm_state()
	if farm_state == null:
		return
	farm_state.set("current_season", "spring")
	farm_state.set("current_day", 1)
	farm_state.set("current_year", 1)
	farm_state.set("garden_plots", _make_empty_garden())


func _setup_farmyard_overview() -> void:
	var farm_state: Node = _farm_state()
	if farm_state == null:
		return
	farm_state.set("current_season", "summer")
	farm_state.set("current_day", 6)
	farm_state.set("current_year", 1)
	farm_state.set("progression_design", "player_placed_rewards")
	farm_state.set("total_chore_completions", 60)
	farm_state.set("daily_chore_states", {
		CHORE_EGGS: true,
		CHORE_MILKING: true,
		CHORE_GARDEN: true,
		CHORE_FEEDING: false,
		CHORE_BRUSHING: false,
	})
	farm_state.set("today_completion_history", [
		CHORE_EGGS,
		CHORE_MILKING,
		CHORE_GARDEN,
	])
	farm_state.set("unlock_progress", {
		"flower_bed": true,
		"prettier_fence": true,
		"goat_friend": true,
		"hay_bales": true,
		"geese_pond": true,
		"strawberry_crop": true,
		"duck_pond": true,
		"rainbow_tree": true,
		"windmill": true,
	})
	farm_state.set("placed_rewards", {
		"flower_bed": "lower_left_flower_edge",
		"prettier_fence": "fence_flowers",
		"hay_bales": "left_fence_hay_corner",
		"geese_pond": "spring_geese_pond",
		"duck_pond": "right_pond_edge",
		"rainbow_tree": "upper_orchard_corner",
		"windmill": "windmill_hill",
	})
	farm_state.set("garden_plots", [
		_make_plot(0, PLOT_SEEDED, "carrot", false, false),
		_make_plot(1, PLOT_GROWING, "tomato", true, false),
		_make_plot(2, PLOT_READY_TO_HARVEST, "corn", true, true),
		_make_plot(3, PLOT_HARVESTED, "turnip", false, true),
	])


func _setup_egg_hunt() -> void:
	var farm_state: Node = _farm_state()
	if farm_state == null:
		return
	farm_state.set("current_season", "spring")
	farm_state.set("current_day", 1)
	farm_state.set("current_year", 1)
	var daily_progress: Dictionary = farm_state.get("daily_progress")
	daily_progress[CHORE_EGGS] = {"collected": ["nest_a", "nest_b"]}
	farm_state.set("daily_progress", daily_progress)
	farm_state.set("garden_plots", _make_empty_garden())


func _setup_milking_time() -> void:
	var farm_state: Node = _farm_state()
	if farm_state == null:
		return
	farm_state.set("current_season", "summer")
	farm_state.set("current_day", 2)
	farm_state.set("current_year", 1)
	var daily_progress: Dictionary = farm_state.get("daily_progress")
	daily_progress[CHORE_MILKING] = {"amount": 2}
	farm_state.set("daily_progress", daily_progress)
	farm_state.set("garden_plots", _make_empty_garden())


func _setup_garden_care() -> void:
	var farm_state: Node = _farm_state()
	if farm_state == null:
		return
	farm_state.set("current_season", "summer")
	farm_state.set("current_day", 2)
	farm_state.set("current_year", 1)
	var daily_progress: Dictionary = farm_state.get("daily_progress")
	daily_progress[CHORE_GARDEN] = {"actions": 2, "winter_rest_checked": false}
	farm_state.set("daily_progress", daily_progress)
	farm_state.set("garden_plots", [
		_make_plot(0, PLOT_SEEDED, "carrot", false, false),
		_make_plot(1, PLOT_SPROUTING, "tomato", false, false),
		_make_plot(2, PLOT_GROWING, "corn", true, false),
		_make_plot(3, PLOT_READY_TO_HARVEST, "sunflower", true, false),
	])


func _setup_feeding_friends() -> void:
	var farm_state: Node = _farm_state()
	if farm_state == null:
		return
	farm_state.set("current_season", "summer")
	farm_state.set("current_day", 4)
	farm_state.set("current_year", 1)
	var unlock_progress: Dictionary = farm_state.get("unlock_progress")
	unlock_progress["goat_friend"] = true
	farm_state.set("unlock_progress", unlock_progress)
	var daily_progress: Dictionary = farm_state.get("daily_progress")
	daily_progress[CHORE_FEEDING] = {"fed_animals": ["chicken"]}
	farm_state.set("daily_progress", daily_progress)
	farm_state.set("garden_plots", _make_empty_garden())


func _setup_brushing_barn() -> void:
	var farm_state: Node = _farm_state()
	if farm_state == null:
		return
	farm_state.set("current_season", "fall")
	farm_state.set("current_day", 7)
	farm_state.set("current_year", 1)
	var unlock_progress: Dictionary = farm_state.get("unlock_progress")
	unlock_progress["duck_pond"] = true
	farm_state.set("unlock_progress", unlock_progress)
	var daily_progress: Dictionary = farm_state.get("daily_progress")
	daily_progress[CHORE_BRUSHING] = {"brushed_animals": ["pony", "cow"]}
	farm_state.set("daily_progress", daily_progress)
	farm_state.set("garden_plots", _make_empty_garden())


func _setup_duck_pond() -> void:
	var farm_state: Node = _farm_state()
	if farm_state == null:
		return
	farm_state.set("current_season", "summer")
	farm_state.set("current_day", 24)
	farm_state.set("current_year", 1)
	farm_state.set("daily_activity_states", {
		DAILY_ACTIVITY_DUCK_POND: false,
	})
	var unlock_progress: Dictionary = farm_state.get("unlock_progress")
	unlock_progress["duck_pond"] = true
	farm_state.set("unlock_progress", unlock_progress)
	var game_settings: Node = _game_settings()
	if game_settings != null:
		game_settings.call("set_duck_pond_time_limit_enabled", false)
	farm_state.set("garden_plots", _make_empty_garden())


func _setup_mole_game() -> void:
	var farm_state: Node = _farm_state()
	if farm_state == null:
		return
	farm_state.set("current_season", "fall")
	farm_state.set("current_day", 18)
	farm_state.set("current_year", 1)
	var game_settings: Node = _game_settings()
	if game_settings != null:
		game_settings.call("set_duck_pond_time_limit_enabled", false)
	farm_state.set("garden_plots", _make_empty_garden())


func _make_empty_garden() -> Array:
	return [
		_make_plot(0, PLOT_EMPTY, "", false, false),
		_make_plot(1, PLOT_EMPTY, "", false, false),
		_make_plot(2, PLOT_EMPTY, "", false, false),
		_make_plot(3, PLOT_EMPTY, "", false, false),
	]


func _make_plot(plot_index: int, state: String, crop: String, watered_today: bool, cared_today: bool) -> Dictionary:
	return {
		"plot_index": plot_index,
		"state": state,
		"crop": crop,
		"watered_today": watered_today,
		"cared_today": cared_today,
	}


func _farm_state() -> Node:
	return root.get_node_or_null(FARM_STATE_NODE)


func _game_settings() -> Node:
	return root.get_node_or_null(GAME_SETTINGS_NODE)
