extends Node

signal season_changed(new_season: String)
signal day_changed(new_day: int)
signal year_changed(new_year: int)
signal farm_state_changed
signal chore_completed(chore_id: String)
signal sticker_awarded(sticker_id: String)
signal unlocks_changed
signal garden_plot_changed(plot_index: int, plot_data: Dictionary)

const SEASON_ORDER: Array[String] = ["spring", "summer", "fall", "winter"]
const DAYS_PER_SEASON := 3
const SAVE_PATH := "user://farm_chore_friends_state.json"
const PROGRESSION_DESIGN_PLAYER_PLACED := "player_placed_rewards"
const PROGRESSION_DESIGN_AREA_EVOLUTION := "farm_area_evolution"
const PROGRESSION_DESIGN_REWARD_MOMENTS := "reward_unlock_moments"
const DEFAULT_PROGRESSION_DESIGN := PROGRESSION_DESIGN_AREA_EVOLUTION
const STICKERS_ENABLED := false
const VISUAL_REWARD_IDS: Array[String] = [
	"flower_bed",
	"prettier_fence",
	"hay_bales",
	"geese_pond",
	"duck_pond",
	"rainbow_tree",
	"windmill",
]
const DEFAULT_REWARD_SLOTS := {
	"flower_bed": "lower_left_flower_edge",
	"prettier_fence": "fence_flowers",
	"hay_bales": "left_fence_hay_corner",
	"geese_pond": "spring_geese_pond",
	"duck_pond": "right_pond_edge",
	"rainbow_tree": "upper_orchard_corner",
	"windmill": "windmill_hill",
}
const PLACEABLE_REWARD_MILESTONES := [
	{"id": "flower_bed", "chores": 10, "name": "Flower Bed"},
	{"id": "hay_bales", "chores": 25, "name": "Cozy Hay Bales"},
	{"id": "geese_pond", "chores": 35, "name": "Geese Pond"},
	{"id": "prettier_fence", "chores": 45, "name": "Fence Flowers"},
	{"id": "duck_pond", "chores": 70, "name": "Pond Decoration"},
	{"id": "rainbow_tree", "chores": 100, "name": "Farm Tree"},
	{"id": "windmill", "chores": 135, "name": "Windmill"},
]
const AREA_EVOLUTION_MILESTONES := [
	{"id": "prettier_fence", "area": "fence", "level": 1, "day": 8, "name": "Fence Flowers"},
	{"id": "flower_bed", "area": "garden_edge", "level": 1, "chores": 15, "name": "Flower Bed"},
	{"id": "geese_pond", "area": "pond_edge", "level": 1, "day": 12, "name": "Geese Pond"},
	{"id": "hay_bales", "area": "hay_corner", "level": 1, "chores": 40, "name": "Cozy Hay Bales"},
	{"id": "duck_pond", "area": "pond_edge", "level": 2, "day": 24, "name": "Pond Decoration"},
	{"id": "rainbow_tree", "area": "orchard_corner", "level": 1, "chores": 120, "name": "Farm Tree"},
	{"id": "windmill", "area": "windmill_hill", "level": 1, "day": 36, "name": "Windmill"},
]
const REWARD_MOMENT_MILESTONES := [
	{"id": "prettier_fence", "day": 8, "name": "Fence Flowers"},
	{"id": "flower_bed", "day": 12, "name": "Flower Bed"},
	{"id": "geese_pond", "day": 12, "name": "Geese Pond"},
	{"id": "hay_bales", "day": 18, "name": "Cozy Hay Bales"},
	{"id": "duck_pond", "day": 24, "name": "Pond Decoration"},
	{"id": "rainbow_tree", "day": 32, "name": "Farm Tree"},
	{"id": "windmill", "day": 45, "name": "Windmill"},
]

const CHORE_EGGS := "eggs"
const CHORE_MILKING := "milking"
const CHORE_GARDEN := "garden"
const CHORE_FEEDING := "feeding"
const CHORE_BRUSHING := "brushing"
const DAILY_ACTIVITY_DUCK_POND := "duck_pond"
const DAILY_ACTIVITY_MOLE_GARDEN := "mole_garden"
const DAILY_CHORES: Array[String] = [
	CHORE_EGGS,
	CHORE_MILKING,
	CHORE_GARDEN,
	CHORE_FEEDING,
	CHORE_BRUSHING,
]

const PLOT_EMPTY := "empty"
const PLOT_SEEDED := "seeded"
const PLOT_SPROUTING := "sprouting"
const PLOT_GROWING := "growing"
const PLOT_READY_TO_HARVEST := "ready_to_harvest"
const PLOT_HARVESTED := "harvested"

const DEFAULT_PLOT_COUNT := 4
const EGG_GOAL := 6
const MILK_GOAL := 4
const SPRING_CROPS: Array[String] = ["turnip", "carrot", "pea"]
const SUMMER_CROPS: Array[String] = ["corn", "tomato"]
const FALL_CROPS: Array[String] = ["pumpkin", "sunflower"]
const WINTER_CROPS: Array[String] = ["lettuce"]
const DAILY_ENCOURAGEMENTS: Array[String] = [
	"The farm is waking up with you.",
	"Every helper tap makes the farm brighter.",
	"The animals are ready for gentle care.",
	"Sunny Farm has a fresh little surprise today.",
	"Helping hands make this a happy farm.",
]
const DAILY_STICKER_IDS: Array[String] = [
	"sunny_star",
	"happy_apple",
	"gentle_cow",
	"garden_bloom",
	"cozy_egg",
]
const ALL_UNLOCK_IDS: Array[String] = [
	"flower_bed",
	"prettier_fence",
	"goat_friend",
	"hay_bales",
	"geese_pond",
	"strawberry_crop",
	"duck_pond",
	"rainbow_tree",
	"windmill",
]
const DAILY_STICKER_NAMES := {
	"sunny_star": "Sunny Star",
	"happy_apple": "Happy Apple",
	"gentle_cow": "Gentle Cow",
	"garden_bloom": "Garden Bloom",
	"cozy_egg": "Cozy Egg",
}

var current_season: String = "spring"
var current_day := 1
var current_year := 1
var garden_plots: Array[Dictionary] = []
var daily_chore_states: Dictionary = {}
var daily_activity_states: Dictionary = {}
var daily_progress: Dictionary = {}
var daily_assist_memory: Dictionary = {}
var unlock_progress: Dictionary = {}
var progression_design: String = DEFAULT_PROGRESSION_DESIGN
var reward_inventory: Array[String] = []
var placed_rewards: Dictionary = {}
var sticker_collection: Dictionary = {}
var daily_sticker_awarded := false
var today_completion_history: Array[String] = []
var total_chore_completions := 0
var farmyard_runtime_state: Dictionary = {}


func _ready() -> void:
	if garden_plots.is_empty():
		if not load_state():
			reset_all_state()


func reset_all_state() -> void:
	current_day = 1
	current_year = 1
	current_season = "spring"
	total_chore_completions = 0
	progression_design = DEFAULT_PROGRESSION_DESIGN
	reward_inventory.clear()
	placed_rewards.clear()
	sticker_collection.clear()
	daily_sticker_awarded = false
	today_completion_history.clear()
	farmyard_runtime_state.clear()
	unlock_progress = {}
	for unlock_id in ALL_UNLOCK_IDS:
		unlock_progress[unlock_id] = false
	_initialize_garden()
	_reset_daily_progress()
	_refresh_unlocks()
	emit_signal("farm_state_changed")
	emit_signal("day_changed", current_day)
	emit_signal("year_changed", current_year)
	emit_signal("season_changed", current_season)
	save_state()


func _initialize_garden() -> void:
	garden_plots.clear()
	for index in DEFAULT_PLOT_COUNT:
		garden_plots.append({
			"plot_index": index,
			"state": PLOT_EMPTY,
			"watered_today": false,
			"cared_today": false,
			"crop": "",
		})


func _reset_daily_progress() -> void:
	daily_chore_states = {}
	for chore_id in DAILY_CHORES:
		daily_chore_states[chore_id] = false
	daily_activity_states = {
		DAILY_ACTIVITY_DUCK_POND: false,
		DAILY_ACTIVITY_MOLE_GARDEN: false,
	}

	daily_progress = {
		CHORE_EGGS: {"collected": []},
		CHORE_MILKING: {"amount": 0},
		CHORE_GARDEN: {"actions": 0, "winter_rest_checked": false},
		CHORE_FEEDING: {"fed_animals": []},
		CHORE_BRUSHING: {"brushed_animals": []},
	}
	daily_assist_memory = {}
	daily_sticker_awarded = false
	today_completion_history.clear()


func get_season_display_name() -> String:
	match current_season:
		"spring":
			return tr("Spring")
		"summer":
			return tr("Summer")
		"fall":
			return tr("Fall")
		"winter":
			return tr("Winter")
	return tr(current_season.capitalize())


func get_date_display_name() -> String:
	return tr("Year %d - Farm Day %d") % [current_year, current_day]


func get_daily_variant_index(key: String, option_count: int) -> int:
	if option_count <= 0:
		return 0
	var hash_key := "%s:%s:%d:%d" % [key, current_season, current_year, current_day]
	return absi(hash(hash_key)) % option_count


func get_daily_encouragement() -> String:
	return tr(DAILY_ENCOURAGEMENTS[get_daily_variant_index("daily_encouragement", DAILY_ENCOURAGEMENTS.size())])


func get_daily_sticker_id() -> String:
	return DAILY_STICKER_IDS[get_daily_variant_index("daily_sticker", DAILY_STICKER_IDS.size())]


func get_sticker_name(sticker_id: String) -> String:
	return tr(str(DAILY_STICKER_NAMES.get(sticker_id, sticker_id.replace("_", " ").capitalize())))


func get_sticker_count(sticker_id: String) -> int:
	return max(0, _read_int(sticker_collection.get(sticker_id, 0), 0))


func get_total_sticker_count() -> int:
	var total := 0
	for value in sticker_collection.values():
		total += max(0, _read_int(value, 0))
	return total


func was_daily_sticker_awarded() -> bool:
	return daily_sticker_awarded


func get_chore_completion_feedback(chore_id: String) -> Dictionary:
	var options := _get_chore_completion_options(chore_id)
	var index := get_daily_variant_index("completion_%s" % chore_id, options.size())
	return {
		"text": tr(options[index]),
		"voice_key": "%s_complete_%d" % [_get_chore_voice_prefix(chore_id), index],
	}


func get_chore_completion_message(chore_id: String) -> String:
	return str(get_chore_completion_feedback(chore_id).get("text", "Great helping! The farm feels cared for."))


func _get_chore_completion_options(chore_id: String) -> Array[String]:
	var options: Array[String] = []
	match chore_id:
		CHORE_EGGS:
			options = [
				"Great helping! The chickens are happy.",
				"Nice work! The eggs are safe.",
				"Thank you! The coop feels cozy.",
				"Good job! The basket is full.",
				"Happy hens! You helped so much.",
			]
		CHORE_MILKING:
			options = [
				"Nice work! The cow feels cared for.",
				"Great helping! The milk bucket is full.",
				"Thank you! The cow is happy.",
				"Good job! Fresh milk is ready.",
				"Lovely helping! The barn feels calm.",
			]
		CHORE_FEEDING:
			options = [
				"Yum! The animals loved their snack.",
				"Great helping! Every animal had food.",
				"Nice work! Happy munching time.",
				"Thank you! The animals are full.",
				"Good job! The pen feels happy.",
			]
		CHORE_BRUSHING:
			options = [
				"All clean! The animals feel better.",
				"Nice work! Everyone is brushed.",
				"Great helping! Soft and shiny coats.",
				"Thank you! The animals feel cozy.",
				"Good job! The barn friends are clean.",
			]
		CHORE_GARDEN:
			options = [
				"Great gardening! The plants are cared for.",
				"Nice work! The garden feels happy.",
				"Thank you! Every plot got care.",
				"Good job! The plants look bright.",
				"Lovely helping! The garden is cozy.",
			]
	if options.is_empty():
		options = ["Great helping! The farm feels cared for."]
	return options


func _get_chore_voice_prefix(chore_id: String) -> String:
	match chore_id:
		CHORE_EGGS:
			return "eggs"
		CHORE_MILKING:
			return "milking"
		CHORE_FEEDING:
			return "feeding"
		CHORE_BRUSHING:
			return "brushing"
		CHORE_GARDEN:
			return "garden"
	return "farm"


func get_completed_chore_count() -> int:
	var total := 0
	for chore_id in DAILY_CHORES:
		if bool(daily_chore_states.get(chore_id, false)):
			total += 1
	return total


func get_completed_chores_today() -> Array[String]:
	var result: Array[String] = []
	for chore_id in DAILY_CHORES:
		if bool(daily_chore_states.get(chore_id, false)):
			result.append(chore_id)
	return result


func get_next_unfinished_chore_id() -> String:
	for chore_id in DAILY_CHORES:
		if not bool(daily_chore_states.get(chore_id, false)):
			return chore_id
	return ""


func are_all_daily_chores_completed() -> bool:
	return get_next_unfinished_chore_id().is_empty()


func can_advance_day() -> bool:
	return are_all_daily_chores_completed()


func is_daily_activity_completed(activity_id: String) -> bool:
	return _read_bool(daily_activity_states.get(activity_id, false))


func complete_daily_activity(activity_id: String) -> bool:
	if activity_id.is_empty() or is_daily_activity_completed(activity_id):
		return false
	daily_activity_states[activity_id] = true
	emit_signal("farm_state_changed")
	save_state()
	return true


func is_duck_pond_visited_today() -> bool:
	return is_daily_activity_completed(DAILY_ACTIVITY_DUCK_POND)


func mark_duck_pond_visited_today() -> bool:
	return complete_daily_activity(DAILY_ACTIVITY_DUCK_POND)


func is_mole_garden_visited_today() -> bool:
	return is_daily_activity_completed(DAILY_ACTIVITY_MOLE_GARDEN)


func mark_mole_garden_visited_today() -> bool:
	return complete_daily_activity(DAILY_ACTIVITY_MOLE_GARDEN)


func set_progression_design(design_id: String) -> void:
	if not [PROGRESSION_DESIGN_PLAYER_PLACED, PROGRESSION_DESIGN_AREA_EVOLUTION, PROGRESSION_DESIGN_REWARD_MOMENTS].has(design_id):
		design_id = DEFAULT_PROGRESSION_DESIGN
	if progression_design == design_id:
		return
	progression_design = design_id
	_refresh_unlocks()
	emit_signal("farm_state_changed")
	save_state()


func get_progression_design_display_name(design_id: String = "") -> String:
	var id := progression_design if design_id.is_empty() else design_id
	match id:
		PROGRESSION_DESIGN_PLAYER_PLACED:
			return "Player Placed Rewards"
		PROGRESSION_DESIGN_REWARD_MOMENTS:
			return "Reward Unlock Moments"
		_:
			return "Farm Area Evolution"


func get_assist_memory(chore_id: String) -> Dictionary:
	return _read_dictionary(daily_assist_memory.get(chore_id, {}))


func save_assist_memory(chore_id: String, memory: Dictionary) -> void:
	if chore_id.is_empty():
		return
	daily_assist_memory[chore_id] = memory.duplicate(true)
	save_state()


func is_chore_completed(chore_id: String) -> bool:
	return _read_bool(daily_chore_states.get(chore_id, false))


func complete_chore(chore_id: String) -> bool:
	if is_chore_completed(chore_id):
		return false

	daily_chore_states[chore_id] = true
	total_chore_completions += 1
	today_completion_history.append(chore_id)
	_refresh_unlocks()
	var awarded_sticker := ""
	if STICKERS_ENABLED and are_all_daily_chores_completed():
		awarded_sticker = _award_daily_sticker()
	emit_signal("chore_completed", chore_id)
	if not awarded_sticker.is_empty():
		emit_signal("sticker_awarded", awarded_sticker)
	emit_signal("farm_state_changed")
	save_state()
	return true


func _award_daily_sticker() -> String:
	if daily_sticker_awarded:
		return ""
	var sticker_id := get_daily_sticker_id()
	sticker_collection[sticker_id] = get_sticker_count(sticker_id) + 1
	daily_sticker_awarded = true
	return sticker_id


func advance_day() -> bool:
	if not can_advance_day():
		return false

	_apply_end_of_day_garden_progress()
	var previous_season := current_season
	var previous_year := current_year
	current_day += 1
	current_season = _get_season_for_day(current_day)
	if previous_season == "winter" and current_season == "spring":
		current_year += 1
	_reset_daily_progress()
	_refresh_unlocks()

	if previous_year != current_year:
		emit_signal("year_changed", current_year)
	if previous_season != current_season:
		emit_signal("season_changed", current_season)
	emit_signal("day_changed", current_day)
	emit_signal("farm_state_changed")
	save_state()
	return true


func _get_season_for_day(day_number: int) -> String:
	var season_index := int(floor(float(day_number - 1) / float(DAYS_PER_SEASON))) % SEASON_ORDER.size()
	return SEASON_ORDER[season_index]


func _get_year_for_day(day_number: int) -> int:
	var days_per_year := DAYS_PER_SEASON * SEASON_ORDER.size()
	return int(floor(float(max(1, day_number) - 1) / float(days_per_year))) + 1


func get_day_in_season() -> int:
	return ((current_day - 1) % DAYS_PER_SEASON) + 1


func debug_set_farm_date(season: String, day_in_season: int, year: int = -1) -> void:
	if not SEASON_ORDER.has(season):
		season = current_season if SEASON_ORDER.has(current_season) else "spring"
	var clean_year: int = max(1, current_year if year < 1 else year)
	var clean_day_in_season: int = clampi(day_in_season, 1, DAYS_PER_SEASON)
	var season_index := SEASON_ORDER.find(season)
	var day_number := ((clean_year - 1) * SEASON_ORDER.size() * DAYS_PER_SEASON) + (season_index * DAYS_PER_SEASON) + clean_day_in_season
	var previous_day := current_day
	var previous_year := current_year
	var previous_season := current_season

	current_day = max(1, day_number)
	current_year = _get_year_for_day(current_day)
	current_season = _get_season_for_day(current_day)
	_reset_daily_progress()
	_initialize_garden()
	_debug_prepare_garden_for_current_date()
	_refresh_unlocks()

	if previous_year != current_year:
		emit_signal("year_changed", current_year)
	if previous_season != current_season:
		emit_signal("season_changed", current_season)
	if previous_day != current_day:
		emit_signal("day_changed", current_day)
	for index in garden_plots.size():
		emit_signal("garden_plot_changed", index, get_plot_data(index))
	emit_signal("farm_state_changed")
	save_state()


func debug_step_day(offset: int) -> void:
	var target_day: int = max(1, current_day + offset)
	var target_season := _get_season_for_day(target_day)
	var target_year := _get_year_for_day(target_day)
	var target_day_in_season := ((target_day - 1) % DAYS_PER_SEASON) + 1
	debug_set_farm_date(target_season, target_day_in_season, target_year)


func debug_reset_today() -> void:
	_reset_daily_progress()
	prepare_garden_for_current_day()
	for index in garden_plots.size():
		emit_signal("garden_plot_changed", index, get_plot_data(index))
	emit_signal("farm_state_changed")
	save_state()


func debug_complete_next_chore() -> String:
	var chore_id := get_next_unfinished_chore_id()
	if chore_id.is_empty():
		return ""
	complete_chore(chore_id)
	return chore_id


func debug_complete_all_chores() -> void:
	for chore_id in DAILY_CHORES:
		complete_chore(chore_id)


func debug_unlock_everything() -> void:
	total_chore_completions = maxi(total_chore_completions, _get_debug_unlock_chore_total())
	current_day = maxi(current_day, _get_debug_unlock_day())
	current_season = _get_season_for_day(current_day)
	current_year = _get_year_for_day(current_day)
	for unlock_id in ALL_UNLOCK_IDS:
		unlock_progress[unlock_id] = true
	if progression_design == PROGRESSION_DESIGN_PLAYER_PLACED:
		var unlocked_rewards: Array[String] = []
		for reward_id in VISUAL_REWARD_IDS:
			if not placed_rewards.has(reward_id):
				placed_rewards[reward_id] = String(DEFAULT_REWARD_SLOTS.get(reward_id, reward_id))
			if not unlocked_rewards.has(reward_id):
				unlocked_rewards.append(reward_id)
		reward_inventory = unlocked_rewards
	_refresh_unlocks()
	emit_signal("unlocks_changed")
	emit_signal("farm_state_changed")
	save_state()


func _get_debug_unlock_chore_total() -> int:
	var required_total := 0
	for milestone_group in [PLACEABLE_REWARD_MILESTONES, AREA_EVOLUTION_MILESTONES]:
		for milestone in milestone_group:
			var data: Dictionary = milestone
			required_total = maxi(required_total, int(data.get("chores", 0)))
	return required_total


func _get_debug_unlock_day() -> int:
	var required_day := 1
	for milestone_group in [AREA_EVOLUTION_MILESTONES, REWARD_MOMENT_MILESTONES]:
		for milestone in milestone_group:
			var data: Dictionary = milestone
			required_day = maxi(required_day, int(data.get("day", 1)))
	return required_day


func debug_mark_duck_pond_visited() -> void:
	mark_duck_pond_visited_today()


func _debug_prepare_garden_for_current_date() -> void:
	for index in garden_plots.size():
		var plot := garden_plots[index].duplicate(true)
		match get_day_in_season():
			1:
				plot["state"] = PLOT_EMPTY
				plot["crop"] = ""
			2:
				plot["state"] = PLOT_SEEDED
				plot["crop"] = _choose_crop_for_current_season(index)
			3:
				plot["state"] = PLOT_READY_TO_HARVEST
				plot["crop"] = _choose_crop_for_current_season(index)
		plot["watered_today"] = false
		plot["cared_today"] = false
		garden_plots[index] = plot


func prepare_garden_for_current_day() -> bool:
	if get_day_in_season() != 3:
		return false
	var changed := false
	for index in garden_plots.size():
		var plot := garden_plots[index].duplicate(true)
		var state := String(plot.get("state", PLOT_EMPTY))
		if state in [PLOT_SEEDED, PLOT_SPROUTING, PLOT_GROWING]:
			plot["state"] = PLOT_READY_TO_HARVEST
			if String(plot.get("crop", "")).is_empty():
				plot["crop"] = _choose_crop_for_current_season(index)
			garden_plots[index] = plot
			emit_signal("garden_plot_changed", index, plot.duplicate(true))
			changed = true
	if changed:
		emit_signal("farm_state_changed")
		save_state()
	return changed


func _apply_end_of_day_garden_progress() -> void:
	var ending_season := current_season
	var next_day := current_day + 1
	var next_season := _get_season_for_day(next_day)
	for index in garden_plots.size():
		var plot := garden_plots[index].duplicate(true)
		var state := String(plot.get("state", PLOT_EMPTY))

		if state == PLOT_HARVESTED or ending_season != next_season:
			plot["state"] = PLOT_EMPTY
			plot["crop"] = ""

		plot["watered_today"] = false
		plot["cared_today"] = false
		garden_plots[index] = plot
		emit_signal("garden_plot_changed", index, plot.duplicate(true))


func get_plot_data(plot_index: int) -> Dictionary:
	if plot_index < 0 or plot_index >= garden_plots.size():
		return {}
	return garden_plots[plot_index].duplicate(true)


func interact_with_plot(plot_index: int) -> Dictionary:
	if plot_index < 0 or plot_index >= garden_plots.size():
		return {
			"success": false,
			"message": "That plot is resting.",
			"action": "rest",
		}

	var plot := garden_plots[plot_index].duplicate(true)
	var result := {
		"success": false,
		"message": "",
		"action": "",
		"plot_index": plot_index,
		"state": String(plot.get("state", PLOT_EMPTY)),
		"crop": String(plot.get("crop", "")),
	}

	if bool(plot.get("cared_today", false)):
		result["message"] = "That plot already got gentle care today."
		return result

	match current_season:
		"spring":
			_handle_spring_plot_interaction(plot, result)
		"summer":
			_handle_summer_plot_interaction(plot, result)
		"fall":
			_handle_fall_plot_interaction(plot, result)
		"winter":
			_handle_winter_plot_interaction(plot, result)

	garden_plots[plot_index] = plot
	result["state"] = String(plot.get("state", PLOT_EMPTY))
	result["crop"] = String(plot.get("crop", ""))

	if bool(result.get("success", false)):
		plot["cared_today"] = true
		garden_plots[plot_index] = plot
		record_garden_action()

	emit_signal("garden_plot_changed", plot_index, plot.duplicate(true))
	emit_signal("farm_state_changed")
	if bool(result.get("success", false)):
		save_state()
	return result


func interact_with_next_garden_plot(preferred_plot_index: int = -1) -> Dictionary:
	var plot_order: Array[int] = []
	if preferred_plot_index >= 0 and preferred_plot_index < garden_plots.size():
		plot_order.append(preferred_plot_index)
	for index in garden_plots.size():
		if index != preferred_plot_index:
			plot_order.append(index)

	var fallback_result := {
		"success": false,
		"message": "The garden is cozy for now.",
		"action": "rest",
		"plot_index": -1,
	}

	for plot_index in plot_order:
		var result := interact_with_plot(plot_index)
		result["plot_index"] = plot_index
		if bool(result.get("success", false)):
			return result
		if int(fallback_result.get("plot_index", -1)) == -1:
			fallback_result = result

	return fallback_result


func get_next_interactable_garden_plot_index(preferred_plot_index: int = -1) -> int:
	var plot_order: Array[int] = []
	if preferred_plot_index >= 0 and preferred_plot_index < garden_plots.size():
		plot_order.append(preferred_plot_index)
	for index in garden_plots.size():
		if index != preferred_plot_index:
			plot_order.append(index)

	for plot_index in plot_order:
		if _plot_has_valid_interaction(garden_plots[plot_index]):
			return plot_index
	return preferred_plot_index if preferred_plot_index >= 0 and preferred_plot_index < garden_plots.size() else 0


func _plot_has_valid_interaction(plot: Dictionary) -> bool:
	var state := String(plot.get("state", PLOT_EMPTY))
	if bool(plot.get("cared_today", false)):
		return false
	if state == PLOT_HARVESTED:
		return false
	match current_season:
		"spring", "summer", "fall", "winter":
			match get_day_in_season():
				1:
					return state == PLOT_EMPTY
				2:
					return state in [PLOT_SEEDED, PLOT_SPROUTING, PLOT_GROWING]
				3:
					return state in [PLOT_SEEDED, PLOT_SPROUTING, PLOT_GROWING, PLOT_READY_TO_HARVEST]
			return false
		"winter":
			return true
		_:
			return false


func _handle_spring_plot_interaction(plot: Dictionary, result: Dictionary) -> void:
	_handle_seasonal_garden_plot_interaction(plot, result, "spring")


func _handle_summer_plot_interaction(plot: Dictionary, result: Dictionary) -> void:
	_handle_seasonal_garden_plot_interaction(plot, result, "summer")


func _handle_fall_plot_interaction(plot: Dictionary, result: Dictionary) -> void:
	_handle_seasonal_garden_plot_interaction(plot, result, "fall")


func _handle_seasonal_garden_plot_interaction(plot: Dictionary, result: Dictionary, season: String) -> void:
	var state := String(plot.get("state", PLOT_EMPTY))
	var day_in_season := get_day_in_season()
	if day_in_season == 1 and state == PLOT_EMPTY:
		_seed_plot(plot)
		result["success"] = true
		result["action"] = "seed"
		result["message"] = _get_garden_stage_message(season, "seed")
	elif state == PLOT_HARVESTED:
		result["message"] = "That crop is already gathered."
	elif day_in_season == 2 and state in [PLOT_SEEDED, PLOT_SPROUTING, PLOT_GROWING]:
		plot["state"] = PLOT_GROWING
		plot["watered_today"] = true
		result["success"] = true
		result["action"] = "grow"
		result["message"] = _get_garden_stage_message(season, "grow")
	elif day_in_season == 3 and state in [PLOT_SEEDED, PLOT_SPROUTING, PLOT_GROWING, PLOT_READY_TO_HARVEST]:
		plot["state"] = PLOT_HARVESTED
		result["success"] = true
		result["action"] = "harvest"
		result["message"] = _get_garden_stage_message(season, "harvest")
	else:
		result["message"] = _get_garden_stage_message(season, "wait")


func _get_garden_stage_message(season: String, stage: String) -> String:
	match stage:
		"seed":
			match season:
				"spring":
					return "Seeds tucked into the spring soil."
				"summer":
					return "Fresh summer seeds are in the soil."
				"fall":
					return "A cozy fall seed is tucked in."
				"winter":
					return "Lettuce seeds are cozy in the cold frame."
		"grow":
			match season:
				"spring":
					return "The spring crop is growing strong."
				"summer":
					return "That summer plant is growing fast."
				"fall":
					return "That fall crop is growing."
				"winter":
					return "The cold-frame lettuce is growing."
		"harvest":
			match season:
				"spring":
					return "Spring crops picked for the basket!"
				"summer":
					return "Crunchy crops picked for the farm!"
				"fall":
					return "A big autumn harvest for the barn!"
				"winter":
					return "Winter lettuce picked for the basket!"
		"wait":
			match get_day_in_season():
				1:
					return "This plot is ready for planting."
				2:
					return "This plot is ready for care."
				3:
					return "This plot is ready to harvest."
	return "The garden feels happy."


func _handle_winter_plot_interaction(plot: Dictionary, result: Dictionary) -> void:
	_handle_seasonal_garden_plot_interaction(plot, result, "winter")
	if bool(result.get("success", false)):
		daily_progress[CHORE_GARDEN]["winter_rest_checked"] = true


func _seed_plot(plot: Dictionary) -> void:
	plot["state"] = PLOT_SEEDED
	plot["watered_today"] = false
	plot["cared_today"] = false
	plot["crop"] = _choose_crop_for_current_season(int(plot.get("plot_index", 0)))


func _choose_crop_for_current_season(plot_index: int = 0) -> String:
	match current_season:
		"spring":
			return _choose_crop_from_options("spring_crop_%d" % plot_index, SPRING_CROPS)
		"summer":
			var summer_options := SUMMER_CROPS.duplicate()
			if has_unlock("strawberry_crop"):
				summer_options.append("strawberry")
			return _choose_crop_from_options("summer_crop_%d" % plot_index, summer_options)
		"fall":
			return _choose_crop_from_options("fall_crop_%d" % plot_index, FALL_CROPS)
		"winter":
			return _choose_crop_from_options("winter_crop_%d" % plot_index, WINTER_CROPS)
		_:
			return "turnip"


func _choose_crop_from_options(key: String, options: Array[String]) -> String:
	if options.is_empty():
		return "turnip"
	var plot_index := 0
	var key_parts := key.split("_")
	if not key_parts.is_empty():
		plot_index = int(key_parts[key_parts.size() - 1])
	return options[(get_daily_variant_index(key, options.size()) + plot_index) % options.size()]


func record_garden_action() -> void:
	daily_progress[CHORE_GARDEN]["actions"] = int(daily_progress[CHORE_GARDEN].get("actions", 0)) + 1
	if is_garden_cared_for_today():
		complete_chore(CHORE_GARDEN)


func get_garden_goal_for_today() -> int:
	return get_garden_actions_today() + get_remaining_garden_actions_today()


func get_garden_actions_today() -> int:
	return int(daily_progress[CHORE_GARDEN].get("actions", 0))


func get_remaining_garden_actions_today() -> int:
	var remaining := 0
	for plot in garden_plots:
		if _plot_has_valid_interaction(plot):
			remaining += 1
	return remaining


func is_garden_cared_for_today() -> bool:
	return get_remaining_garden_actions_today() == 0


func _calculate_garden_goal_for_today() -> int:
	return get_garden_goal_for_today()


func collect_egg(egg_id: String) -> bool:
	var collected: Array = daily_progress[CHORE_EGGS]["collected"]
	if collected.has(egg_id):
		return false
	collected.append(egg_id)
	daily_progress[CHORE_EGGS]["collected"] = collected
	if collected.size() >= EGG_GOAL:
		complete_chore(CHORE_EGGS)
	else:
		emit_signal("farm_state_changed")
		save_state()
	return true


func is_egg_collected(egg_id: String) -> bool:
	return Array(daily_progress[CHORE_EGGS]["collected"]).has(egg_id)


func get_collected_egg_count() -> int:
	return Array(daily_progress[CHORE_EGGS]["collected"]).size()


func add_milk(amount: int = 1) -> int:
	var new_amount: int = min(MILK_GOAL, int(daily_progress[CHORE_MILKING].get("amount", 0)) + amount)
	daily_progress[CHORE_MILKING]["amount"] = new_amount
	if new_amount >= MILK_GOAL:
		complete_chore(CHORE_MILKING)
	else:
		emit_signal("farm_state_changed")
		save_state()
	return new_amount


func get_milk_amount() -> int:
	return int(daily_progress[CHORE_MILKING].get("amount", 0))


func feed_animal(animal_id: String) -> bool:
	var fed_animals: Array = daily_progress[CHORE_FEEDING]["fed_animals"]
	if fed_animals.has(animal_id):
		return false
	fed_animals.append(animal_id)
	daily_progress[CHORE_FEEDING]["fed_animals"] = fed_animals
	if fed_animals.size() >= get_feeding_goal():
		complete_chore(CHORE_FEEDING)
	else:
		emit_signal("farm_state_changed")
		save_state()
	return true


func is_animal_fed(animal_id: String) -> bool:
	return Array(daily_progress[CHORE_FEEDING]["fed_animals"]).has(animal_id)


func get_feeding_goal() -> int:
	return 4 if has_unlock("goat_friend") else 3


func get_fed_animals() -> Array:
	return Array(daily_progress[CHORE_FEEDING]["fed_animals"]).duplicate()


func brush_animal(animal_id: String) -> bool:
	var brushed_animals: Array = daily_progress[CHORE_BRUSHING]["brushed_animals"]
	if brushed_animals.has(animal_id):
		return false
	brushed_animals.append(animal_id)
	daily_progress[CHORE_BRUSHING]["brushed_animals"] = brushed_animals
	if brushed_animals.size() >= get_brushing_goal():
		complete_chore(CHORE_BRUSHING)
	else:
		emit_signal("farm_state_changed")
		save_state()
	return true


func is_animal_brushed(animal_id: String) -> bool:
	return Array(daily_progress[CHORE_BRUSHING]["brushed_animals"]).has(animal_id)


func get_brushing_goal() -> int:
	return 4 if has_unlock("duck_pond") else 3


func get_brushed_animals() -> Array:
	return Array(daily_progress[CHORE_BRUSHING]["brushed_animals"]).duplicate()


func has_unlock(unlock_id: String) -> bool:
	return _read_bool(unlock_progress.get(unlock_id, false))


func get_unlocked_reward_ids() -> Array[String]:
	match progression_design:
		PROGRESSION_DESIGN_PLAYER_PLACED:
			return get_placed_reward_ids()
		PROGRESSION_DESIGN_REWARD_MOMENTS:
			return _get_milestone_reward_ids(REWARD_MOMENT_MILESTONES)
		_:
			return get_area_evolution_reward_ids()


func get_area_evolution_reward_ids() -> Array[String]:
	var selected_by_area: Dictionary = {}
	for milestone in AREA_EVOLUTION_MILESTONES:
		var data: Dictionary = milestone
		if not _is_reward_milestone_met(data):
			continue

		var area_id := String(data.get("area", ""))
		if area_id.is_empty():
			continue

		var existing: Dictionary = Dictionary(selected_by_area.get(area_id, {}))
		if existing.is_empty() or int(data.get("level", 1)) >= int(existing.get("level", 1)):
			selected_by_area[area_id] = data

	var reward_ids: Array[String] = []
	for area_id in selected_by_area.keys():
		var data: Dictionary = selected_by_area[area_id]
		var reward_id := String(data.get("id", ""))
		if not reward_id.is_empty():
			reward_ids.append(reward_id)
	return reward_ids


func get_reward_event_ids() -> Array[String]:
	if progression_design == PROGRESSION_DESIGN_PLAYER_PLACED:
		return get_pending_placeable_reward_ids()
	return get_unlocked_reward_ids()


func get_pending_placeable_reward_ids() -> Array[String]:
	var result: Array[String] = []
	for reward_id in reward_inventory:
		var clean_reward_id := String(reward_id)
		if not VISUAL_REWARD_IDS.has(clean_reward_id):
			continue
		if placed_rewards.has(clean_reward_id):
			continue
		if not result.has(clean_reward_id):
			result.append(clean_reward_id)
	return result


func get_placed_reward_ids() -> Array[String]:
	var result: Array[String] = []
	for reward_id in placed_rewards.keys():
		result.append(String(reward_id))
	return result


func get_placed_rewards() -> Dictionary:
	return placed_rewards.duplicate(true)


func place_reward(reward_id: String, slot_id: String) -> bool:
	if progression_design != PROGRESSION_DESIGN_PLAYER_PLACED:
		return false
	if not reward_inventory.has(reward_id) or slot_id.is_empty():
		return false
	if _is_reward_slot_used(slot_id):
		return false

	reward_inventory.erase(reward_id)
	placed_rewards[reward_id] = slot_id
	emit_signal("unlocks_changed")
	emit_signal("farm_state_changed")
	save_state()
	return true


func get_area_evolution_level(area_id: String) -> int:
	var level := 0
	for milestone in AREA_EVOLUTION_MILESTONES:
		var data: Dictionary = milestone
		if String(data.get("area", "")) == area_id and _is_reward_milestone_met(data):
			level = max(level, int(data.get("level", 1)))
	return level


func get_reward_name(reward_id: String) -> String:
	for milestone_group in [PLACEABLE_REWARD_MILESTONES, AREA_EVOLUTION_MILESTONES, REWARD_MOMENT_MILESTONES]:
		for milestone in milestone_group:
			var data: Dictionary = milestone
			if String(data.get("id", "")) == reward_id:
				return String(data.get("name", _humanize_reward_id(reward_id)))
	return _humanize_reward_id(reward_id)


func _refresh_unlocks() -> void:
	var updated := false
	updated = _set_unlock("goat_friend", current_day >= 6 or total_chore_completions >= 25) or updated
	updated = _set_unlock("strawberry_crop", total_chore_completions >= 40) or updated
	updated = _set_unlock("geese_pond", current_day >= 12 or total_chore_completions >= 35) or updated
	updated = _set_unlock("duck_pond", current_day >= 12 or total_chore_completions >= 55) or updated
	updated = _refresh_player_reward_inventory() or updated
	if updated:
		emit_signal("unlocks_changed")


func _set_unlock(unlock_id: String, unlocked: bool) -> bool:
	var previous := _read_bool(unlock_progress.get(unlock_id, false))
	unlock_progress[unlock_id] = unlocked
	return previous != unlocked


func _refresh_player_reward_inventory() -> bool:
	if progression_design != PROGRESSION_DESIGN_PLAYER_PLACED:
		return false

	var updated := false
	for milestone in PLACEABLE_REWARD_MILESTONES:
		var data: Dictionary = milestone
		var reward_id := String(data.get("id", ""))
		if reward_id.is_empty() or not _is_reward_milestone_met(data):
			continue
		if reward_inventory.has(reward_id) or placed_rewards.has(reward_id):
			continue
		reward_inventory.append(reward_id)
		updated = true
	return updated


func _get_milestone_reward_ids(milestones: Array) -> Array[String]:
	var reward_ids: Array[String] = []
	for milestone in milestones:
		var data: Dictionary = milestone
		var reward_id := String(data.get("id", ""))
		if reward_id.is_empty() or reward_ids.has(reward_id):
			continue
		if _is_reward_milestone_met(data):
			reward_ids.append(reward_id)
	return reward_ids


func _is_reward_milestone_met(milestone: Dictionary) -> bool:
	var chores_goal := int(milestone.get("chores", 0))
	var day_goal := int(milestone.get("day", 0))
	var year_goal := int(milestone.get("year", 0))
	if chores_goal > 0 and total_chore_completions < chores_goal:
		return false
	if day_goal > 0 and current_day < day_goal:
		return false
	if year_goal > 0 and current_year < year_goal:
		return false
	return true


func _is_reward_slot_used(slot_id: String) -> bool:
	for used_slot in placed_rewards.values():
		if String(used_slot) == slot_id:
			return true
	return false


func _humanize_reward_id(reward_id: String) -> String:
	return reward_id.replace("_", " ").capitalize()


func save_state() -> void:
	var save_data := {
		"current_day": current_day,
		"current_year": current_year,
		"current_season": current_season,
		"garden_plots": garden_plots,
		"daily_chore_states": daily_chore_states,
		"daily_activity_states": daily_activity_states,
		"daily_progress": daily_progress,
		"daily_assist_memory": daily_assist_memory,
		"unlock_progress": unlock_progress,
		"progression_design": progression_design,
		"reward_inventory": reward_inventory,
		"placed_rewards": placed_rewards,
		"sticker_collection": sticker_collection,
		"daily_sticker_awarded": daily_sticker_awarded,
		"today_completion_history": today_completion_history,
		"total_chore_completions": total_chore_completions,
		"farmyard_runtime_state": farmyard_runtime_state,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(save_data, "\t"))


func load_state() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return false

	var data := parsed as Dictionary
	current_day = max(1, _read_int(data.get("current_day", 1), 1))
	current_year = _get_year_for_day(current_day)
	current_season = _get_season_for_day(current_day)
	total_chore_completions = max(0, _read_int(data.get("total_chore_completions", 0), 0))
	unlock_progress = _read_dictionary(data.get("unlock_progress", {}))
	progression_design = str(data.get("progression_design", DEFAULT_PROGRESSION_DESIGN))
	if not [PROGRESSION_DESIGN_PLAYER_PLACED, PROGRESSION_DESIGN_AREA_EVOLUTION, PROGRESSION_DESIGN_REWARD_MOMENTS].has(progression_design):
		progression_design = DEFAULT_PROGRESSION_DESIGN
	reward_inventory.clear()
	for reward_id in _read_array(data.get("reward_inventory", [])):
		var clean_reward_id := str(reward_id)
		if VISUAL_REWARD_IDS.has(clean_reward_id):
			reward_inventory.append(clean_reward_id)
	placed_rewards = _read_dictionary(data.get("placed_rewards", {}))
	sticker_collection = _read_dictionary(data.get("sticker_collection", {}))
	daily_sticker_awarded = _read_bool(data.get("daily_sticker_awarded", false))
	daily_chore_states = _read_dictionary(data.get("daily_chore_states", {}))
	daily_activity_states = _read_dictionary(data.get("daily_activity_states", {}))
	daily_progress = _read_dictionary(data.get("daily_progress", {}))
	daily_assist_memory = _read_dictionary(data.get("daily_assist_memory", {}))
	farmyard_runtime_state = _read_dictionary(data.get("farmyard_runtime_state", {}))

	today_completion_history.clear()
	for chore_id in _read_array(data.get("today_completion_history", [])):
		today_completion_history.append(str(chore_id))

	garden_plots.clear()
	for raw_plot in _read_array(data.get("garden_plots", [])):
		if raw_plot is Dictionary:
			garden_plots.append(_normalize_plot(raw_plot as Dictionary, garden_plots.size()))
	while garden_plots.size() < DEFAULT_PLOT_COUNT:
		garden_plots.append(_normalize_plot({}, garden_plots.size()))

	_ensure_daily_state_shape()
	for unlock_id in ALL_UNLOCK_IDS:
		if not unlock_progress.has(unlock_id):
			unlock_progress[unlock_id] = false
	_refresh_unlocks()
	return true


func set_farmyard_runtime_state(state: Dictionary) -> void:
	farmyard_runtime_state = state.duplicate(true)


func get_farmyard_runtime_state() -> Dictionary:
	return farmyard_runtime_state.duplicate(true)


func clear_farmyard_runtime_state() -> void:
	farmyard_runtime_state.clear()


func _ensure_daily_state_shape() -> void:
	var clean_chore_states: Dictionary = {}
	for chore_id in DAILY_CHORES:
		clean_chore_states[chore_id] = _read_bool(daily_chore_states.get(chore_id, false))
	daily_chore_states = clean_chore_states

	daily_activity_states = {
		DAILY_ACTIVITY_DUCK_POND: _read_bool(daily_activity_states.get(DAILY_ACTIVITY_DUCK_POND, false)),
		DAILY_ACTIVITY_MOLE_GARDEN: _read_bool(daily_activity_states.get(DAILY_ACTIVITY_MOLE_GARDEN, false)),
	}

	var clean_assist_memory: Dictionary = {}
	for chore_id in DAILY_CHORES:
		var assist_memory := _read_dictionary(daily_assist_memory.get(chore_id, {}))
		if not assist_memory.is_empty():
			clean_assist_memory[chore_id] = assist_memory
	daily_assist_memory = clean_assist_memory

	var egg_progress := _read_dictionary(daily_progress.get(CHORE_EGGS, {}))
	egg_progress["collected"] = _normalize_string_array(egg_progress.get("collected", []))

	var milking_progress := _read_dictionary(daily_progress.get(CHORE_MILKING, {}))
	milking_progress["amount"] = clampi(_read_int(milking_progress.get("amount", 0), 0), 0, MILK_GOAL)

	var garden_progress := _read_dictionary(daily_progress.get(CHORE_GARDEN, {}))
	garden_progress["actions"] = clampi(_read_int(garden_progress.get("actions", 0), 0), 0, DEFAULT_PLOT_COUNT)
	garden_progress["winter_rest_checked"] = _read_bool(garden_progress.get("winter_rest_checked", false))

	var feeding_progress := _read_dictionary(daily_progress.get(CHORE_FEEDING, {}))
	feeding_progress["fed_animals"] = _normalize_string_array(feeding_progress.get("fed_animals", []))

	var brushing_progress := _read_dictionary(daily_progress.get(CHORE_BRUSHING, {}))
	brushing_progress["brushed_animals"] = _normalize_string_array(brushing_progress.get("brushed_animals", []))

	daily_progress = {
		CHORE_EGGS: egg_progress,
		CHORE_MILKING: milking_progress,
		CHORE_GARDEN: garden_progress,
		CHORE_FEEDING: feeding_progress,
		CHORE_BRUSHING: brushing_progress,
	}

	for unlock_id in unlock_progress.keys():
		unlock_progress[unlock_id] = _read_bool(unlock_progress[unlock_id])

	var clean_placed_rewards: Dictionary = {}
	var used_slots: Array[String] = []
	for reward_id in placed_rewards.keys():
		var clean_reward_id := str(reward_id)
		if not VISUAL_REWARD_IDS.has(clean_reward_id):
			continue
		var slot_id := str(placed_rewards[reward_id])
		if slot_id.is_empty() or used_slots.has(slot_id):
			continue
		clean_placed_rewards[clean_reward_id] = slot_id
		used_slots.append(slot_id)
	placed_rewards = clean_placed_rewards

	var clean_reward_inventory: Array[String] = []
	for reward_id in reward_inventory:
		var clean_reward_id := str(reward_id)
		if not VISUAL_REWARD_IDS.has(clean_reward_id):
			continue
		if placed_rewards.has(clean_reward_id):
			continue
		if not clean_reward_inventory.has(clean_reward_id):
			clean_reward_inventory.append(clean_reward_id)
	reward_inventory = clean_reward_inventory

	var clean_stickers: Dictionary = {}
	for sticker_id in sticker_collection.keys():
		var clean_sticker_id := str(sticker_id)
		if not DAILY_STICKER_IDS.has(clean_sticker_id):
			continue
		var count: int = max(0, _read_int(sticker_collection[sticker_id], 0))
		if count > 0:
			clean_stickers[clean_sticker_id] = count
	sticker_collection = clean_stickers
	daily_sticker_awarded = _read_bool(daily_sticker_awarded)


func _normalize_plot(raw_plot: Dictionary, fallback_index: int) -> Dictionary:
	var state := str(raw_plot.get("state", PLOT_EMPTY))
	if not [PLOT_EMPTY, PLOT_SEEDED, PLOT_SPROUTING, PLOT_GROWING, PLOT_READY_TO_HARVEST, PLOT_HARVESTED].has(state):
		state = PLOT_EMPTY
	var watered_today := _read_bool(raw_plot.get("watered_today", false))
	var crop := str(raw_plot.get("crop", ""))
	if crop == "apple":
		crop = "pumpkin"
	var supported_crops := SPRING_CROPS + SUMMER_CROPS + FALL_CROPS + WINTER_CROPS + ["strawberry"]
	if not crop.is_empty() and not supported_crops.has(crop):
		crop = ""
	return {
		"plot_index": max(0, _read_int(raw_plot.get("plot_index", fallback_index), fallback_index)),
		"state": state,
		"watered_today": watered_today,
		"cared_today": _read_bool(raw_plot.get("cared_today", watered_today or state == PLOT_HARVESTED)),
		"crop": crop,
	}


func _read_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _read_array(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	if value == null:
		return []
	return [value]


func _read_bool(value: Variant, default_value := false) -> bool:
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


func _read_int(value: Variant, default_value := 0) -> int:
	if value is int:
		return value
	if value is float:
		return int(value)
	if value is String or value is StringName:
		var text := str(value).strip_edges()
		if text.is_valid_int():
			return int(text)
		if text.is_valid_float():
			return int(float(text))
	return default_value


func _normalize_string_array(raw_value: Variant) -> Array[String]:
	var result: Array[String] = []
	for item in _read_array(raw_value):
		if item == null:
			continue
		var text := str(item)
		if text.is_empty() or result.has(text):
			continue
		result.append(text)
	return result
