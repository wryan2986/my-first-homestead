extends SceneTree

const MILKING_ROUTE := "milking"

var _failures: Array[String] = []


func _initialize() -> void:
	await process_frame
	var navigator := root.get_node_or_null("SceneNavigator")
	if navigator == null:
		_fail("Missing SceneNavigator autoload.")
		_report_and_quit()
		return
	var milking_scene := load("res://scenes/MilkingScene.tscn") as PackedScene
	if milking_scene == null:
		_fail("Could not load MilkingScene.")
		_report_and_quit()
		return

	navigator.call("clear_activity_cache")
	navigator.call("register_activity_routes", {MILKING_ROUTE: milking_scene})
	if not bool(navigator.call("is_activity_warm", MILKING_ROUTE)):
		_fail("MilkingScene was not warmed during route registration.")
	var warmed_milking := _cached_milking(navigator)
	if warmed_milking == null:
		_fail("Could not find the warmed MilkingScene instance.")
	elif not warmed_milking.has_method("is_cache_prepared") or not bool(warmed_milking.call("is_cache_prepared")):
		_fail("MilkingScene did not complete its cache preparation.")
	elif not _has_current_season_background(warmed_milking):
		_fail("MilkingScene did not load its current seasonal background while warming.")
	elif not _uses_only_path_loaded_background(warmed_milking):
		_fail("MilkingScene still retains directly assigned seasonal background textures.")

	if not bool(navigator.call("go_to_activity", MILKING_ROUTE, milking_scene)):
		_fail("MilkingScene did not open from the warm cache.")
		_report_and_quit()
		return
	await process_frame
	var first_id := _active_activity_id(navigator)
	if first_id == 0:
		_fail("Could not find the active MilkingScene instance.")

	navigator.call("return_to_farmyard")
	await process_frame
	if not bool(navigator.call("go_to_activity", MILKING_ROUTE, milking_scene)):
		_fail("MilkingScene did not reopen from the cache.")
	await process_frame
	var second_id := _active_activity_id(navigator)
	if first_id != 0 and second_id != first_id:
		_fail("MilkingScene was instantiated again instead of reusing the cached instance.")

	navigator.call("return_to_farmyard")
	await process_frame
	_verify_bounded_cache_keeps_milking(navigator)
	_report_and_quit()


func _active_activity_id(navigator: Node) -> int:
	var container := navigator.get_node_or_null("ActivityContainer")
	if container == null or container.get_child_count() == 0:
		return 0
	return container.get_child(0).get_instance_id()


func _cached_milking(navigator: Node) -> Node:
	var cache_container := navigator.get_node_or_null("SceneWarmCache")
	if cache_container == null:
		return null
	for child in cache_container.get_children():
		if child.name == "MilkingScene":
			return child
	return null


func _has_current_season_background(milking: Node) -> bool:
	var background := milking.get_node_or_null("Background") as Sprite2D
	return background != null and background.texture != null


func _uses_only_path_loaded_background(milking: Node) -> bool:
	var background := milking.get_node_or_null("Background") as Sprite2D
	if background == null:
		return false
	for property_name in ["spring_texture", "summer_texture", "fall_texture", "winter_texture"]:
		if background.get(property_name) != null:
			return false
	var farm_state := root.get_node_or_null("FarmState")
	if farm_state == null:
		return false
	var expected_path := "res://art/backgrounds/milking_barn_background_%s.png" % str(farm_state.current_season)
	return background.texture != null and background.texture.resource_path == expected_path


func _verify_bounded_cache_keeps_milking(navigator: Node) -> void:
	var first_route := "_milking_cache_limit_first"
	var second_route := "_milking_cache_limit_second"
	var first_scene := _make_test_scene("FirstCacheLimitScene")
	var second_scene := _make_test_scene("SecondCacheLimitScene")
	navigator.call("register_activity_routes", {
		first_route: first_scene,
		second_route: second_scene,
	})
	for route in [first_route, second_route]:
		if not bool(navigator.call("go_to_activity", route)):
			_fail("Could not open cache-limit test route: %s" % route)
			continue
		navigator.call("return_to_farmyard")
	var cache_container := navigator.get_node_or_null("SceneWarmCache")
	if cache_container == null:
		_fail("Missing SceneWarmCache after cache-limit test.")
		return
	if cache_container.get_child_count() > 2:
		_fail("Activity cache exceeded its two-scene limit.")
	if not bool(navigator.call("is_activity_warm", MILKING_ROUTE)):
		_fail("Bounded cache evicted the priority MilkingScene.")


func _make_test_scene(node_name: String) -> PackedScene:
	var node := Node2D.new()
	node.name = node_name
	var packed := PackedScene.new()
	packed.pack(node)
	node.free()
	return packed


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report_and_quit() -> void:
	if _failures.is_empty():
		print("MILKING_SCENE_CACHE_TEST_OK")
		quit(0)
	else:
		print("MILKING_SCENE_CACHE_TEST_FAILED")
		for failure in _failures:
			print(" - %s" % failure)
		quit(1)
