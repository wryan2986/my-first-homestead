extends SceneTree

const STATION_SCENE := preload("res://scenes/shared/FeedingAnimalStation.tscn")
const FEEDING_SCENE_PATH := "res://scenes/FeedingScene.tscn"
const TROUGH_CONTENTS_PATH := "res://art/props/feeding_trough_contents.png"

var _failures: Array[String] = []


func _initialize() -> void:
	_check_scene_trough_targets()
	var station := STATION_SCENE.instantiate()
	root.add_child(station)
	await process_frame

	if station.get_node_or_null("StationBack") != null:
		_fail("Feeding station still contains a runtime StationBack.")
	if station.get_node_or_null("StationFront") != null:
		_fail("Feeding station still contains a runtime StationFront.")
	if station.get_node_or_null("TroughFill") != null:
		_fail("Feeding station still contains a runtime TroughFill.")

	var pile := station.get_node_or_null("FeedPile") as CanvasItem
	var target := station.get_node_or_null("FeedTarget") as Node2D
	if pile == null:
		_fail("Feeding station is missing FeedPile.")
	elif pile.visible:
		_fail("FeedPile should be hidden before feed is delivered.")
	elif pile is Sprite2D and (pile as Sprite2D).texture.resource_path != TROUGH_CONTENTS_PATH:
		_fail("FeedPile must use contents-only art so the built-in background trough stays visible.")
	if target == null:
		_fail("Feeding station is missing FeedTarget.")
	elif pile != null and (pile as Node2D).position != target.position:
		_fail("FeedPile and FeedTarget must share the built-in trough position.")

	station.call("set_feed_visible", true, false)
	if pile != null and not pile.visible:
		_fail("FeedPile did not appear after feed delivery.")
	station.call("set_feed_visible", false, false)
	if pile != null and pile.visible:
		_fail("FeedPile did not hide when the station was reset.")

	station.queue_free()
	await process_frame
	_report_and_quit()


func _check_scene_trough_targets() -> void:
	var scene_text := FileAccess.get_file_as_string(FEEDING_SCENE_PATH)
	if scene_text.is_empty():
		_fail("Could not read the feeding scene.")
		return
	var expected_offsets := {
		"SheepCard": "feed_target_offset = Vector2(51, 60)",
		"PigCard": "feed_target_offset = Vector2(39, 68)",
		"ChickenCard": "feed_target_offset = Vector2(5, 59)",
		"GoatCard": "feed_target_offset = Vector2(6, 58)",
	}
	for card_name in expected_offsets:
		if not scene_text.contains(expected_offsets[card_name]):
			_fail("%s is missing its built-in trough target offset." % card_name)


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report_and_quit() -> void:
	if _failures.is_empty():
		print("FEEDING_STATION_VISUAL_TEST_OK")
		quit(0)
	else:
		print("FEEDING_STATION_VISUAL_TEST_FAILED")
		for failure in _failures:
			print(" - %s" % failure)
		quit(1)
