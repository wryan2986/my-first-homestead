extends SceneTree

const WINDMILL_SCRIPT := preload("res://scripts/WindmillDecoration.gd")

var _failures: Array[String] = []
var _windmill: Sprite2D
var _fan_center: Node2D


func _initialize() -> void:
	_spawn_windmill()
	await process_frame
	await process_frame
	_find_fan_center()
	await _check_spin_direction_and_duration()
	await _check_restart()
	_report_and_quit()


func _spawn_windmill() -> void:
	_windmill = Sprite2D.new()
	_windmill.name = "Windmill"
	_windmill.set_script(WINDMILL_SCRIPT)
	_windmill.visible = true
	root.add_child(_windmill)


func _find_fan_center() -> void:
	if _windmill == null:
		return
	_windmill.set("_whoosh_stream", null)
	_fan_center = _windmill.get_node_or_null("FanCenter") as Node2D
	if _fan_center == null:
		_fail("Missing generated FanCenter.")


func _check_spin_direction_and_duration() -> void:
	if _windmill == null or _fan_center == null:
		return
	var start_rotation := _fan_center.rotation
	_windmill.call("handle_tap")
	await _wait_seconds(0.2)
	var early_rotation := _fan_center.rotation
	if early_rotation >= start_rotation - 0.05:
		_fail("Windmill did not start rotating in the negative direction. start=%s early=%s" % [start_rotation, early_rotation])
	var early_tween := _windmill.get("_fan_tween") as Tween
	if early_tween == null or not early_tween.is_valid():
		_fail("Windmill spin tween was not active shortly after tap.")

	await _wait_seconds(1.15)
	var later_rotation := _fan_center.rotation
	var later_tween := _windmill.get("_fan_tween") as Tween
	if later_tween == null or not later_tween.is_valid():
		_fail("Windmill spin tween ended too early; expected it to last longer than the old animation.")
	if absf(later_rotation - early_rotation) < 0.05:
		_fail("Windmill fan was not still moving after the old animation duration.")


func _check_restart() -> void:
	if _windmill == null or _fan_center == null:
		return
	var before_restart := _fan_center.rotation
	_windmill.call("handle_tap")
	await _wait_seconds(0.2)
	var after_restart := _fan_center.rotation
	var tween := _windmill.get("_fan_tween") as Tween
	if tween == null or not tween.is_valid():
		_fail("Windmill spin tween was not active after restart tap.")
	if after_restart >= before_restart - 0.05:
		_fail("Windmill restart did not continue in the negative direction. before=%s after=%s" % [before_restart, after_restart])


func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report_and_quit() -> void:
	if _windmill != null and is_instance_valid(_windmill):
		_windmill.queue_free()
		await process_frame
	if _failures.is_empty():
		print("WINDMILL_SPIN_ANIMATION_TEST_OK")
		quit(0)
	else:
		print("WINDMILL_SPIN_ANIMATION_TEST_FAILED")
		for failure in _failures:
			print(" - %s" % failure)
		quit(1)
