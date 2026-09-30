extends SceneTree

const OUTPUT_DIR := "res://_qa_previews/aspect_ratios"
const DESIGN_SIZE := Vector2(1920.0, 1080.0)
const SIZES := [
	Vector2i(1920, 1080),
	Vector2i(2340, 1080),
	Vector2i(2400, 1080),
	Vector2i(2520, 1080),
	Vector2i(1280, 800),
	Vector2i(1280, 960),
	Vector2i(1440, 960),
	Vector2i(1920, 1200),
	Vector2i(2048, 1536),
	Vector2i(2160, 1440),
]
const SCENES := {
	"start": "res://scenes/StartScene.tscn",
	"farmyard": "res://scenes/FarmyardScene.tscn",
	"eggs": "res://scenes/EggCollectingScene.tscn",
	"feeding": "res://scenes/FeedingScene.tscn",
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for scene_id in SCENES.keys():
		var packed := load(SCENES[scene_id]) as PackedScene
		if packed == null:
			push_error("Could not load %s" % SCENES[scene_id])
			continue
		for physical_size in SIZES:
			await _capture_scene(scene_id, packed, physical_size)
		packed = null
	_clear_scene_navigator_cache()
	await process_frame
	print("ASPECT_RATIO_CAPTURE_OK")
	quit()


func _capture_scene(scene_id: String, packed: PackedScene, physical_size: Vector2i) -> void:
	var size := _get_expand_logical_size(physical_size)
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	var scene := packed.instantiate()
	viewport.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var image := viewport.get_texture().get_image()
	var file_name := "%s/%s_%dx%d.png" % [OUTPUT_DIR, scene_id, physical_size.x, physical_size.y]
	var error := image.save_png(file_name)
	if error != OK:
		push_error("Could not save %s: %s" % [file_name, error])

	viewport.queue_free()
	await process_frame


func _clear_scene_navigator_cache() -> void:
	var scene_navigator := root.get_node_or_null("SceneNavigator")
	if scene_navigator != null and scene_navigator.has_method("clear_activity_cache"):
		scene_navigator.call("clear_activity_cache")


func _get_expand_logical_size(physical_size: Vector2i) -> Vector2i:
	var scale_factor := minf(
		float(physical_size.x) / DESIGN_SIZE.x,
		float(physical_size.y) / DESIGN_SIZE.y
	)
	if scale_factor <= 0.0:
		return Vector2i(DESIGN_SIZE)
	return Vector2i(ceili(float(physical_size.x) / scale_factor), ceili(float(physical_size.y) / scale_factor))
