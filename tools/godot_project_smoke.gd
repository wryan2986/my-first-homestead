extends SceneTree

const MAIN_SCENES: Array[String] = [
	"res://scenes/StartScene.tscn",
	"res://scenes/FarmyardScene.tscn",
	"res://scenes/EggCollectingScene.tscn",
	"res://scenes/MilkingScene.tscn",
	"res://scenes/WateringScene.tscn",
	"res://scenes/FeedingScene.tscn",
	"res://scenes/BrushingScene.tscn",
	"res://scenes/DuckPondMusicScene.tscn",
	"res://scenes/MoleGardenScene.tscn",
]

const SHARED_SCENES: Array[String] = [
	"res://scenes/shared/AmbientChasePair.tscn",
	"res://scenes/shared/BeeCritter.tscn",
	"res://scenes/shared/BouncyCritter.tscn",
	"res://scenes/shared/ButterflyCritter.tscn",
	"res://scenes/shared/DuckPondPlay.tscn",
	"res://scenes/shared/Egg.tscn",
	"res://scenes/shared/EggBasketFill.tscn",
	"res://scenes/shared/FarmAnimalCard.tscn",
	"res://scenes/shared/FeedingAnimalStation.tscn",
	"res://scenes/shared/FarmNightTransition.tscn",
	"res://scenes/shared/GardenBasketFill.tscn",
	"res://scenes/shared/GardenPlot.tscn",
	"res://scenes/shared/MusicManager.tscn",
	"res://scenes/shared/SantaSleighFlyer.tscn",
	"res://scenes/shared/SeasonalTapSurprises.tscn",
	"res://scenes/shared/SpringPondGeese.tscn",
]

const REQUIRED_AUTOLOADS: Array[String] = [
	"FarmState",
	"GameSettings",
	"MusicManager",
	"VoiceOverManager",
]

var _failures: Array[String] = []


func _initialize() -> void:
	await process_frame
	_check_autoloads()
	_check_scene_loads()
	_check_voice_over_catalog()
	_check_music_playlists()
	_check_seasonal_content_sets()
	_simulate_farm_state_progression()
	_check_farm_state_edge_cases()
	_report_and_quit()


func _check_autoloads() -> void:
	for autoload_name in REQUIRED_AUTOLOADS:
		if root.get_node_or_null(autoload_name) == null:
			_fail("Missing autoload: %s" % autoload_name)


func _check_scene_loads() -> void:
	for scene_path in MAIN_SCENES + SHARED_SCENES:
		_check_scene(scene_path)


func _check_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		_fail("Scene path does not exist: %s" % scene_path)
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_fail("Scene failed to load as PackedScene: %s" % scene_path)
		return
	var instance := packed.instantiate()
	if instance == null:
		_fail("Scene failed to instantiate: %s" % scene_path)
		return
	_check_exported_node_paths(scene_path, instance)
	instance.queue_free()


func _check_exported_node_paths(scene_path: String, instance: Node) -> void:
	for property in instance.get_property_list():
		var usage := int(property.get("usage", 0))
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue
		var property_name := String(property.get("name", ""))
		var value = instance.get(property_name)
		if value is NodePath:
			_check_node_path_value(scene_path, instance, property_name, value)
		elif value is Array:
			var index := 0
			for item in value:
				if item is NodePath:
					_check_node_path_value(scene_path, instance, "%s[%d]" % [property_name, index], item)
				index += 1


func _check_node_path_value(scene_path: String, instance: Node, property_name: String, node_path: NodePath) -> void:
	if node_path.is_empty():
		return
	if instance.get_node_or_null(node_path) == null:
		_fail("%s has missing NodePath export %s = %s" % [scene_path, property_name, str(node_path)])


func _check_voice_over_catalog() -> void:
	var catalog_path := "res://sounds/voice_over/voice_lines.json"
	if not ResourceLoader.exists(catalog_path) and not FileAccess.file_exists(catalog_path):
		_fail("Missing voice-over catalog: %s" % catalog_path)
		return
	var file := FileAccess.open(catalog_path, FileAccess.READ)
	if file == null:
		_fail("Could not open voice-over catalog: %s" % catalog_path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Voice-over catalog is not a dictionary.")
		return
	var data := parsed as Dictionary
	var entries: Array = []
	if data.get("lines", []) is Array:
		entries = data.get("lines", [])
	else:
		for key in data.keys():
			var value = data[key]
			if value is Dictionary and (value as Dictionary).has("path"):
				entries.append(value)
	if entries.is_empty():
		_fail("Voice-over catalog has no line entries.")
	for entry in entries:
		if not (entry is Dictionary):
			_fail("Voice-over line entry is not a dictionary.")
			continue
		var key := String((entry as Dictionary).get("key", ""))
		var path := String((entry as Dictionary).get("path", ""))
		if path.is_empty():
			_fail("Voice-over entry has no path: %s" % key)
		elif not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
			_fail("Voice-over clip missing for %s: %s" % [key, path])
	var aliases = data.get("aliases", {})
	if aliases is Dictionary:
		var known_keys: Array[String] = []
		for entry in entries:
			if entry is Dictionary:
				known_keys.append(String((entry as Dictionary).get("key", "")))
		for alias_key in (aliases as Dictionary).keys():
			var target_key := String((aliases as Dictionary)[alias_key])
			if not known_keys.has(target_key):
				_fail("Voice-over alias points to unknown key: %s -> %s" % [alias_key, target_key])


func _check_music_playlists() -> void:
	var music_manager := root.get_node_or_null("MusicManager")
	if music_manager == null:
		return
	for property_name in [
		"farmyard_playlist",
		"chore_playlist",
		"spring_playlist",
		"summer_playlist",
		"fall_playlist",
		"winter_playlist",
	]:
		var playlist: Array = music_manager.get(property_name)
		if playlist.is_empty():
			_fail("Music playlist is empty: %s" % property_name)
		for stream in playlist:
			if stream == null:
				_fail("Music playlist contains null stream: %s" % property_name)


func _check_seasonal_content_sets() -> void:
	var seasonal_background_groups := {
		"brushing_barn_background": "res://art/backgrounds/brushing_barn_background_%s.png",
		"chicken_coop_background": "res://art/backgrounds/chicken_coop_background_%s.png",
		"feeding_yard_background": "res://art/backgrounds/feeding_yard_background_%s.png",
		"mole_garden_background": "res://art/backgrounds/mole_garden_background_%s.png",
		"garden_care_background": "res://art/backgrounds/garden_care_background_%s.png",
		"milking_barn_background": "res://art/backgrounds/milking_barn_background_%s.png",
	}
	for group_name in seasonal_background_groups.keys():
		_check_season_paths("seasonal background %s" % group_name, seasonal_background_groups[group_name])

	var seasonal_prop_groups := {
		"chicken_coop": "res://art/props/chicken_coop_%s.png",
		"hub_feed_pen": "res://art/props/hub_feed_pen_%s.png",
		"hub_garden_fenced": "res://art/props/hub_garden_fenced_%s.png",
		"hub_grooming_stalls": "res://art/props/hub_grooming_stalls_%s.png",
		"hub_milking_stall_cow": "res://art/props/hub_milking_stall_cow_%s.png",
	}
	for group_name in seasonal_prop_groups.keys():
		_check_season_paths("seasonal prop %s" % group_name, seasonal_prop_groups[group_name])


func _check_season_paths(label: String, template: String) -> void:
	for season in ["spring", "summer", "fall", "winter"]:
		var path := template % season
		if not ResourceLoader.exists(path):
			_fail("Missing %s: %s" % [label, path])


func _simulate_farm_state_progression() -> void:
	var farm_state := root.get_node_or_null("FarmState")
	if farm_state == null:
		return
	farm_state.reset_all_state()
	_assert_eq("initial season", farm_state.current_season, "spring")
	_assert_eq("initial day", farm_state.current_day, 1)

	for day_number in range(1, 14):
		_complete_all_chores_for_day(farm_state)
		if not farm_state.are_all_daily_chores_completed():
			_fail("FarmState did not complete all chores on day %d" % day_number)
			return
		if day_number < 13 and not farm_state.advance_day():
			_fail("FarmState could not advance after completed chores on day %d" % day_number)
			return

	_assert_eq("day after simulation", farm_state.current_day, 13)
	_assert_eq("year after one season loop", farm_state.current_year, 2)
	_assert_eq("season after one season loop", farm_state.current_season, "spring")


func _check_farm_state_edge_cases() -> void:
	var farm_state := root.get_node_or_null("FarmState")
	if farm_state == null:
		return
	farm_state.reset_all_state()
	_check_duck_pond_optional(farm_state)
	_check_garden_debug_dates(farm_state)
	_check_save_cleanup_shapes(farm_state)
	_check_tester_helpers(farm_state)
	_check_reward_unlock_timing(farm_state)


func _check_duck_pond_optional(farm_state: Node) -> void:
	farm_state.reset_all_state()
	_complete_all_chores_for_day(farm_state)
	_assert_eq("duck pond starts unvisited", farm_state.is_duck_pond_visited_today(), false)
	_assert_eq("duck pond not required for day advance", farm_state.can_advance_day(), true)
	farm_state.mark_duck_pond_visited_today()
	_assert_eq("duck pond marks visited", farm_state.is_duck_pond_visited_today(), true)
	farm_state.advance_day()
	_assert_eq("duck pond resets next day", farm_state.is_duck_pond_visited_today(), false)


func _check_garden_debug_dates(farm_state: Node) -> void:
	farm_state.debug_set_farm_date("spring", 1, 1)
	_assert_eq("debug spring day 1", farm_state.current_day, 1)
	_assert_eq("debug spring day 1 plot empty", String(farm_state.get_plot_data(0).get("state", "")), farm_state.PLOT_EMPTY)
	farm_state.debug_set_farm_date("summer", 2, 1)
	_assert_eq("debug summer season", farm_state.current_season, "summer")
	_assert_eq("debug summer day in season", farm_state.get_day_in_season(), 2)
	_assert_eq("debug summer day 2 plot seeded", String(farm_state.get_plot_data(0).get("state", "")), farm_state.PLOT_SEEDED)
	farm_state.debug_set_farm_date("fall", 3, 1)
	_assert_eq("debug fall day 3 plot harvest-ready", String(farm_state.get_plot_data(0).get("state", "")), farm_state.PLOT_READY_TO_HARVEST)
	farm_state.debug_set_farm_date("winter", 1, 1)
	_assert_eq("debug winter plot empty", String(farm_state.get_plot_data(0).get("state", "")), farm_state.PLOT_EMPTY)
	farm_state.debug_set_farm_date("winter", 2, 1)
	_assert_eq("debug winter day 2 plot seeded", String(farm_state.get_plot_data(0).get("state", "")), farm_state.PLOT_SEEDED)
	_assert_eq("debug winter day 2 crop lettuce", String(farm_state.get_plot_data(0).get("crop", "")), "lettuce")
	farm_state.debug_set_farm_date("winter", 3, 1)
	_assert_eq("debug winter day 3 plot harvest-ready", String(farm_state.get_plot_data(0).get("state", "")), farm_state.PLOT_READY_TO_HARVEST)
	_assert_eq("debug winter day 3 crop lettuce", String(farm_state.get_plot_data(0).get("crop", "")), "lettuce")


func _check_save_cleanup_shapes(farm_state: Node) -> void:
	var normalized_plot: Dictionary = farm_state.call("_normalize_plot", {
		"plot_index": 0,
		"state": farm_state.PLOT_GROWING,
		"crop": "apple",
		"watered_today": true,
	}, 0)
	_assert_eq("old apple plot normalizes to pumpkin", String(normalized_plot.get("crop", "")), "pumpkin")

	farm_state.daily_chore_states = {"unknown": true, farm_state.CHORE_EGGS: "yes"}
	farm_state.daily_activity_states = {"old_activity": true}
	farm_state.daily_progress = {
		farm_state.CHORE_MILKING: {"amount": 999},
		farm_state.CHORE_FEEDING: {"fed_animals": "cow"},
	}
	farm_state.placed_rewards = {"unknown_reward": "slot_a", "flower_bed": "slot_a", "duck_pond": "slot_a"}
	farm_state.reward_inventory.clear()
	farm_state.reward_inventory.append("duck_pond")
	farm_state.reward_inventory.append("duck_pond")
	farm_state.reward_inventory.append("unknown_reward")
	farm_state.call("_ensure_daily_state_shape")
	_assert_eq("clean unknown chore removed", farm_state.daily_chore_states.has("unknown"), false)
	_assert_eq("duck activity shape retained", farm_state.daily_activity_states.has(farm_state.DAILY_ACTIVITY_DUCK_POND), true)
	_assert_eq("milking amount clamped", int(farm_state.daily_progress[farm_state.CHORE_MILKING].get("amount", 0)), farm_state.MILK_GOAL)
	_assert_eq("unknown reward placement removed", farm_state.placed_rewards.has("unknown_reward"), false)


func _check_tester_helpers(farm_state: Node) -> void:
	farm_state.reset_all_state()
	_assert_eq("debug complete next chore id", farm_state.debug_complete_next_chore(), farm_state.CHORE_EGGS)
	_assert_eq("debug complete next count", farm_state.get_completed_chore_count(), 1)
	farm_state.debug_complete_all_chores()
	_assert_eq("debug complete all", farm_state.are_all_daily_chores_completed(), true)
	farm_state.debug_reset_today()
	_assert_eq("debug reset today", farm_state.get_completed_chore_count(), 0)
	farm_state.debug_mark_duck_pond_visited()
	_assert_eq("debug duck visited", farm_state.is_duck_pond_visited_today(), true)
	farm_state.debug_step_day(1)
	_assert_eq("debug step day", farm_state.current_day, 2)


func _check_reward_unlock_timing(farm_state: Node) -> void:
	farm_state.reset_all_state()
	_assert_eq("stickers remain archived", farm_state.STICKERS_ENABLED, false)
	farm_state.debug_set_farm_date("spring", 2, 1)
	_assert_eq("goat locked before day 6", farm_state.has_unlock("goat_friend"), false)
	farm_state.debug_set_farm_date("summer", 3, 1)
	_assert_eq("goat unlocks by day 6", farm_state.has_unlock("goat_friend"), true)

	farm_state.reset_all_state()
	for index in range(34):
		farm_state.total_chore_completions = index + 1
		farm_state.call("_refresh_unlocks")
	_assert_eq("geese pond locked before 35 chores", farm_state.has_unlock("geese_pond"), false)
	farm_state.total_chore_completions = 35
	farm_state.call("_refresh_unlocks")
	_assert_eq("geese pond unlocks at 35 chores", farm_state.has_unlock("geese_pond"), true)

	farm_state.total_chore_completions = 39
	farm_state.call("_refresh_unlocks")
	_assert_eq("strawberry locked before 40 chores", farm_state.has_unlock("strawberry_crop"), false)
	farm_state.total_chore_completions = 40
	farm_state.call("_refresh_unlocks")
	_assert_eq("strawberry unlocks at 40 chores", farm_state.has_unlock("strawberry_crop"), true)

	farm_state.total_chore_completions = 54
	farm_state.call("_refresh_unlocks")
	_assert_eq("duck pond locked before chore threshold on early day", farm_state.has_unlock("duck_pond"), false)
	farm_state.total_chore_completions = 55
	farm_state.call("_refresh_unlocks")
	_assert_eq("duck pond unlocks at 55 chores", farm_state.has_unlock("duck_pond"), true)

	farm_state.reset_all_state()
	farm_state.debug_set_farm_date("winter", 3, 1)
	_assert_eq("geese pond unlocks by day 12", farm_state.has_unlock("geese_pond"), true)
	_assert_eq("duck pond also unlocks by day 12 compatibility", farm_state.has_unlock("duck_pond"), true)
	farm_state.debug_set_farm_date("summer", 2, 3)
	_assert_eq("rainbow tree area milestone locked without chores", farm_state.get_unlocked_reward_ids().has("rainbow_tree"), false)
	farm_state.total_chore_completions = 120
	farm_state.call("_refresh_unlocks")
	_assert_eq("rainbow tree reward unlocks at 120 chores", farm_state.get_unlocked_reward_ids().has("rainbow_tree"), true)


func _complete_all_chores_for_day(farm_state: Node) -> void:
	for index in range(farm_state.EGG_GOAL):
		farm_state.collect_egg("egg_%d" % index)
	for index in range(farm_state.MILK_GOAL):
		farm_state.add_milk()
	for animal_id in ["cow", "chicken", "pig", "goat", "duck"]:
		farm_state.feed_animal(animal_id)
		farm_state.brush_animal(animal_id)
	var guard := 0
	while not farm_state.is_chore_completed(farm_state.CHORE_GARDEN) and guard < 12:
		farm_state.interact_with_next_garden_plot()
		guard += 1
	if not farm_state.is_chore_completed(farm_state.CHORE_GARDEN):
		_fail("Garden could not complete in progression simulation.")


func _assert_eq(label: String, actual, expected) -> void:
	if actual != expected:
		_fail("%s expected %s, got %s" % [label, str(expected), str(actual)])


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report_and_quit() -> void:
	if _failures.is_empty():
		print("PROJECT_SMOKE_OK")
		quit(0)
		return
	print("PROJECT_SMOKE_FAILED: %d issue(s)" % _failures.size())
	for failure in _failures:
		print("- %s" % failure)
	quit(1)
