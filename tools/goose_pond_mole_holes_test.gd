extends SceneTree

const FARMYARD_SCENE := "res://scenes/FarmyardScene.tscn"
const MOLE_GARDEN_SCENE := "res://scenes/MoleGardenScene.tscn"
# Keep this assertion aligned with the authored reward position in
# FarmyardScene.tscn; it guards accidental drift into neighboring hotspots.
const EXPECTED_GEESE_Y := 306.0

var _failures: Array[String] = []
var _farmyard: Node
var _mole_garden: Node


func _initialize() -> void:
	_check_geese_pond_position()
	await _check_mole_hole_visual_layer()
	_report_and_quit()


func _check_geese_pond_position() -> void:
	var packed := load(FARMYARD_SCENE) as PackedScene
	if packed == null:
		_fail("Could not load %s" % FARMYARD_SCENE)
		return
	_farmyard = packed.instantiate()
	if _farmyard == null:
		_fail("Could not instantiate FarmyardScene.")
		return
	root.add_child(_farmyard)
	var geese := _farmyard.get_node_or_null("AmbientLife/SpringPondGeese") as Node2D
	if geese == null:
		_fail("Missing AmbientLife/SpringPondGeese.")
	elif absf(geese.position.y - EXPECTED_GEESE_Y) > 0.1:
		_fail("SpringPondGeese y position is %s, expected %s." % [geese.position.y, EXPECTED_GEESE_Y])
	_farmyard.queue_free()
	_farmyard = null


func _check_mole_hole_visual_layer() -> void:
	var packed := load(MOLE_GARDEN_SCENE) as PackedScene
	if packed == null:
		_fail("Could not load %s" % MOLE_GARDEN_SCENE)
		return
	_mole_garden = packed.instantiate()
	if _mole_garden == null:
		_fail("Could not instantiate MoleGardenScene.")
		return
	root.add_child(_mole_garden)
	await process_frame
	await process_frame
	var layer := _mole_garden.get_node_or_null("HoleVisualLayer") as Node2D
	if layer == null:
		_fail("MoleGardenScene did not create HoleVisualLayer.")
		return
	var hole_names := ["HoleA", "HoleB", "HoleC", "HoleD", "HoleE"]
	for index in range(hole_names.size()):
		var hole := _mole_garden.get_node_or_null("Holes/%s" % hole_names[index]) as Area2D
		var visual := layer.get_node_or_null("HoleVisual%d" % index) as Sprite2D
		if hole == null:
			_fail("Missing mole hole Area2D at index %d." % index)
			continue
		if visual == null:
			_fail("Missing separate mole hole visual at index %d." % index)
			continue
		if visual.texture == null:
			_fail("Mole hole visual %d has no texture." % index)
		if not visual.visible:
			_fail("Mole hole visual %d is hidden." % index)
		if visual.global_position.distance_to(hole.global_position) > 0.1:
			_fail("Mole hole visual %d is not aligned to its Area2D. visual=%s hole=%s" % [index, str(visual.global_position), str(hole.global_position)])


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report_and_quit() -> void:
	if _farmyard != null and is_instance_valid(_farmyard):
		_farmyard.queue_free()
	if _mole_garden != null and is_instance_valid(_mole_garden):
		_mole_garden.queue_free()
	await process_frame
	if _failures.is_empty():
		print("GOOSE_POND_MOLE_HOLES_TEST_OK")
		quit(0)
	else:
		print("GOOSE_POND_MOLE_HOLES_TEST_FAILED")
		for failure in _failures:
			print(" - %s" % failure)
		quit(1)
