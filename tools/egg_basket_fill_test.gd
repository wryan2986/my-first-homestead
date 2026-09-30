extends SceneTree

const FILL_SCENE := preload("res://scenes/shared/EggBasketFill.tscn")
const EGG_SCENE_PATH := "res://scenes/EggCollectingScene.tscn"
const EMPTY_BASKET_PATH := "res://art/props/egg_basket_empty.png"

var _failures: Array[String] = []


func _initialize() -> void:
	_check_scene_uses_empty_basket()
	var fill := FILL_SCENE.instantiate()
	root.add_child(fill)
	await process_frame

	var eggs := fill.get_children()
	if eggs.is_empty():
		_fail("EggBasketFill did not create its egg sprites.")
	for egg in eggs:
		if egg is Sprite2D and (egg as Sprite2D).visible:
			_fail("An egg was visible before collection began.")

	fill.call("set_collected_count", 1, eggs.size(), false)
	var visible_count := 0
	for egg in fill.get_children():
		if egg is Sprite2D and (egg as Sprite2D).visible:
			visible_count += 1
	if visible_count != 1:
		_fail("Expected one visible egg after collecting one egg, got %d." % visible_count)

	fill.call("set_collected_count", 3, eggs.size(), false)
	visible_count = 0
	for egg in fill.get_children():
		if egg is Sprite2D and (egg as Sprite2D).visible:
			visible_count += 1
	if visible_count != 3:
		_fail("Expected basket fill to grow to three eggs, got %d." % visible_count)

	fill.queue_free()
	await process_frame
	_report_and_quit()


func _check_scene_uses_empty_basket() -> void:
	var scene_text := FileAccess.get_file_as_string(EGG_SCENE_PATH)
	if scene_text.is_empty():
		_fail("Could not read the egg collecting scene.")
	elif not scene_text.contains('path="%s"' % EMPTY_BASKET_PATH):
		_fail("Egg collecting scene must start with the empty basket asset.")


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report_and_quit() -> void:
	if _failures.is_empty():
		print("EGG_BASKET_FILL_TEST_OK")
		quit(0)
	else:
		print("EGG_BASKET_FILL_TEST_FAILED")
		for failure in _failures:
			print(" - %s" % failure)
		quit(1)
