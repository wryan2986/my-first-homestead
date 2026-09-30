extends SceneTree

const TEST_ROUTE := "_pool_test_activity"

var _failures: Array[String] = []


func _initialize() -> void:
	await process_frame
	var navigator := root.get_node_or_null("SceneNavigator")
	if navigator == null:
		_fail("Missing SceneNavigator autoload.")
		_report_and_quit()
		return

	var packed := _make_test_scene()
	navigator.call("register_activity_routes", {TEST_ROUTE: packed})
	await _settle()

	if not bool(navigator.call("go_to_activity", TEST_ROUTE, packed)):
		_fail("SceneNavigator did not open the pooled test activity.")
		_report_and_quit()
		return
	await _settle()
	var first_id := _active_activity_id(navigator)
	if first_id == 0:
		_fail("Could not find active pooled activity after first open.")

	if not bool(navigator.call("return_to_farmyard")):
		_fail("SceneNavigator did not return the test activity to the pool.")
	await _settle()
	if _active_activity_id(navigator) != 0:
		_fail("Pooled activity remained active after return.")

	if not bool(navigator.call("go_to_activity", TEST_ROUTE, packed)):
		_fail("SceneNavigator did not reopen the pooled test activity.")
	await _settle()
	var second_id := _active_activity_id(navigator)
	if first_id != 0 and second_id != first_id:
		_fail("SceneNavigator instantiated a new activity instead of reusing the pooled one.")
	navigator.call("return_to_farmyard")
	_report_and_quit()


func _make_test_scene() -> PackedScene:
	var node := Node2D.new()
	node.name = "PoolTestActivity"
	var packed := PackedScene.new()
	packed.pack(node)
	node.free()
	return packed


func _active_activity_id(navigator: Node) -> int:
	var container := navigator.get_node_or_null("ActivityContainer")
	if container == null or container.get_child_count() == 0:
		return 0
	return container.get_child(0).get_instance_id()


func _settle() -> void:
	for i in range(4):
		await process_frame


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report_and_quit() -> void:
	if _failures.is_empty():
		print("SCENE_NAVIGATOR_PERSISTENT_POOL_TEST_OK")
		quit(0)
	else:
		print("SCENE_NAVIGATOR_PERSISTENT_POOL_TEST_FAILED")
		for failure in _failures:
			print(" - %s" % failure)
		quit(1)
