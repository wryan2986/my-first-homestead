extends SceneTree

const GARDEN_PLOT_SCENE := "res://scenes/shared/GardenPlot.tscn"

var _failures: Array[String] = []
var _plot: Node


func _initialize() -> void:
	await process_frame
	var packed := load(GARDEN_PLOT_SCENE) as PackedScene
	if packed == null:
		_fail("Could not load %s." % GARDEN_PLOT_SCENE)
		_report_and_quit()
		return
	_plot = packed.instantiate()
	root.add_child(_plot)
	await process_frame
	_check_harvested_state()
	_check_ready_state()
	_report_and_quit()


func _check_harvested_state() -> void:
	_plot.call("apply_plot_data", {
		"state": "harvested",
		"crop": "lettuce",
		"watered_today": false,
		"cared_today": true,
	}, "winter")
	var soil := _plot.get_node_or_null("Soil") as Sprite2D
	var plant := _plot.get_node_or_null("Plant") as Sprite2D
	if soil == null or not soil.visible:
		_fail("Harvested plot must keep its circular soil tile visible.")
	if plant == null:
		_fail("Garden plot is missing its Plant sprite.")
	elif plant.visible:
		_fail("Harvested plot still draws a separate plant/soil overlay.")


func _check_ready_state() -> void:
	_plot.call("apply_plot_data", {
		"state": "ready_to_harvest",
		"crop": "lettuce",
		"watered_today": false,
		"cared_today": false,
	}, "winter")
	var plant := _plot.get_node_or_null("Plant") as Sprite2D
	if plant == null or not plant.visible:
		_fail("Ready-to-harvest crops must remain visible.")


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report_and_quit() -> void:
	if _plot != null and is_instance_valid(_plot):
		_plot.queue_free()
	if _failures.is_empty():
		print("GARDEN_PLOT_VISUAL_TEST_OK")
		quit(0)
	else:
		print("GARDEN_PLOT_VISUAL_TEST_FAILED")
		for failure in _failures:
			print(" - %s" % failure)
		quit(1)
