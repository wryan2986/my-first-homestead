extends SceneTree

const SANTA_SCENE := "res://scenes/shared/SantaSleighFlyer.tscn"

var _failures: Array[String] = []
var _music_manager: Node
var _santa: Node


func _initialize() -> void:
	_music_manager = root.get_node_or_null("MusicManager")
	if _music_manager == null:
		_fail("Missing MusicManager autoload.")
		_report_and_quit()
		return
	_music_manager.call("set_voice_over_enabled", true)
	_spawn_santa()
	await process_frame
	_make_santa_tappable()
	TranslationServer.set_locale("en")
	_santa.call("handle_tap")
	await process_frame
	var greeting_player := _santa.get_node_or_null("SantaGreetingPlayer") as AudioStreamPlayer
	var tap_player := _santa.get_node_or_null("TapPlayer") as AudioStreamPlayer
	if greeting_player == null or not greeting_player.playing:
		_fail("Santa greeting did not play when voice-over was enabled.")
	if tap_player != null and tap_player.playing:
		_fail("Santa ho-ho SFX played at the same time as the full greeting.")
	_santa.call("handle_tap")
	await process_frame
	if tap_player != null and tap_player.playing:
		_fail("Santa ho-ho SFX played during a repeated greeting tap.")
	if greeting_player != null:
		greeting_player.stop()
		greeting_player.stream = null
	await create_timer(0.55).timeout
	TranslationServer.set_locale("es")
	_santa.call("handle_tap")
	await process_frame
	if greeting_player != null and greeting_player.playing:
		_fail("Santa full greeting played for a non-English locale.")
	if tap_player == null or not tap_player.playing:
		_fail("Santa ho-ho SFX did not play for a non-English locale.")
	if _santa != null and is_instance_valid(_santa):
		for player_name in ["SantaGreetingPlayer", "TapPlayer", "BellPlayer"]:
			var player := _santa.get_node_or_null(player_name) as AudioStreamPlayer
			if player != null:
				player.stop()
				player.stream = null
		root.remove_child(_santa)
		_santa.free()
		_santa = null
		for i in range(3):
			await process_frame
	_report_and_quit()


func _spawn_santa() -> void:
	var packed := load(SANTA_SCENE) as PackedScene
	if packed == null:
		_fail("Could not load %s" % SANTA_SCENE)
		return
	_santa = packed.instantiate()
	if _santa == null:
		_fail("Could not instantiate Santa scene.")
		return
	root.add_child(_santa)


func _make_santa_tappable() -> void:
	if _santa == null:
		return
	var sleigh := _santa.get_node_or_null("Sleigh") as Sprite2D
	if sleigh != null:
		sleigh.visible = true
	var tap_area := _santa.get_node_or_null("Sleigh/TapArea") as Area2D
	if tap_area != null:
		tap_area.input_pickable = true


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report_and_quit() -> void:
	if _failures.is_empty():
		print("SANTA_AUDIO_SINGLE_CLIP_TEST_OK")
		quit(0)
	else:
		print("SANTA_AUDIO_SINGLE_CLIP_TEST_FAILED")
		for failure in _failures:
			print(" - %s" % failure)
		quit(1)
