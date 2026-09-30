extends SceneTree

const TREE_SCRIPT := preload("res://scripts/RainbowTreeDecoration.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var tree := TREE_SCRIPT.new()
	_check_paths(tree, "spring", ["res://art/effects/rainbow_tree_blossom_drop.png"])
	_check_paths(tree, "summer", ["res://art/effects/rainbow_tree_green_apple_drop.png"])
	_check_paths(tree, "fall", ["res://art/effects/fall_leaf.png", "res://art/effects/rainbow_tree_acorn_drop.png"])
	_check_paths(tree, "winter", ["res://art/effects/rainbow_tree_snow_puff_drop.png", "res://art/effects/large_snowflake.png"])
	_check_spawn_rect(tree)
	tree.free()
	_report_and_quit()


func _check_paths(tree: Node, season: String, expected: Array[String]) -> void:
	var actual: Array[String] = tree.call("get_drop_paths_for_season", season)
	if actual != expected:
		_fail("%s drop paths were %s, expected %s." % [season, actual, expected])
	for path in actual:
		if not ResourceLoader.exists(path):
			_fail("%s drop path is missing: %s." % [season, path])


func _check_spawn_rect(tree: Node) -> void:
	var rect: Rect2 = tree.call("get_drop_spawn_local_rect")
	if rect.position.y >= -80.0:
		_fail("Rainbow tree drop spawn rect should start in the canopy, got %s." % rect)
	if rect.size.x < 180.0 or rect.size.y < 100.0:
		_fail("Rainbow tree drop spawn rect is too small to look shaken loose: %s." % rect)


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report_and_quit() -> void:
	if _failures.is_empty():
		print("RAINBOW_TREE_DROP_MAPPING_TEST_OK")
		quit(0)
	else:
		print("RAINBOW_TREE_DROP_MAPPING_TEST_FAILED")
		for failure in _failures:
			print(" - %s" % failure)
		quit(1)
