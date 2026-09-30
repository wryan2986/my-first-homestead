extends SceneTree

const POND_SCENE := preload("res://scenes/DuckPondMusicScene.tscn")
const GREEN_PAD_PATH := "res://art/props/lily_pad_music_green.png"
const DUCK_PATH := "res://art/animals/duck_swimming_idle.png"

var _failures: Array[String] = []


func _initialize() -> void:
	var pond := POND_SCENE.instantiate()
	root.add_child(pond)
	await process_frame

	for node_path in [
		"LilyPads/LilyPadC",
		"LilyPads/LilyPadE",
		"LilyPads/LilyPadG",
		"LilyPads/LilyPadA",
	]:
		var pad := pond.get_node_or_null(node_path)
		var sprite := pad.get_node_or_null("Sprite") as Sprite2D if pad != null else null
		if sprite == null:
			_fail("Missing lily pad sprite at %s." % node_path)
			continue
		if sprite.texture == null or sprite.texture.resource_path != GREEN_PAD_PATH:
			_fail("Lily pad %s is not using the green texture." % node_path)
		if sprite.scale.x < 0.95 or sprite.scale.y < 0.95:
			_fail("Lily pad %s was not enlarged." % node_path)

		var collision := pad.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or collision.shape == null:
			_fail("Lily pad %s is missing its touch shape." % node_path)
		elif collision.shape is CircleShape2D and (collision.shape as CircleShape2D).radius < 108.0:
			_fail("Lily pad %s touch shape was not enlarged." % node_path)

	for node_path in ["Ducks/DuckA", "Ducks/DuckB", "Ducks/DuckC"]:
		var duck := pond.get_node_or_null(node_path) as Sprite2D
		if duck == null or duck.texture == null or duck.texture.resource_path != DUCK_PATH:
			_fail("Duck %s is not using the mallard swimming sprite." % node_path)

	pond.queue_free()
	await process_frame
	_report_and_quit()


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report_and_quit() -> void:
	if _failures.is_empty():
		print("DUCK_POND_ASSET_WIRING_TEST_OK")
		quit(0)
	else:
		print("DUCK_POND_ASSET_WIRING_TEST_FAILED")
		for failure in _failures:
			print(" - %s" % failure)
		quit(1)
