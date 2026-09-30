class_name ResponsiveCoverNode2D
extends Node2D

const DESIGN_SIZE := Vector2(1920.0, 1080.0)

@export var design_size := DESIGN_SIZE
@export var source_size := Vector2.ZERO

var _connected_viewport: Viewport


func _ready() -> void:
	_connect_viewport()
	apply_cover()


func _exit_tree() -> void:
	if _connected_viewport != null and _connected_viewport.size_changed.is_connected(apply_cover):
		_connected_viewport.size_changed.disconnect(apply_cover)


func _connect_viewport() -> void:
	_connected_viewport = get_viewport()
	if _connected_viewport != null and not _connected_viewport.size_changed.is_connected(apply_cover):
		_connected_viewport.size_changed.connect(apply_cover)


func apply_cover() -> void:
	var viewport_size := _get_viewport_size()
	var background_size := _get_background_size()
	var cover_scale := maxf(viewport_size.x / background_size.x, viewport_size.y / background_size.y)
	scale = Vector2.ONE * cover_scale
	position = (viewport_size - background_size * cover_scale) * 0.5


func _get_background_size() -> Vector2:
	if source_size.x > 0.0 and source_size.y > 0.0:
		return source_size

	# Farmyard background layers may be downsampled for mobile bundle size.
	# Derive the source size from the actual layer instead of assuming that
	# every exported background is still 1920x1080.
	for child in get_children():
		var sprite := child as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		var texture_size := sprite.texture.get_size()
		if texture_size.x > 0.0 and texture_size.y > 0.0:
			return texture_size

	return design_size


func _get_viewport_size() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return design_size
	var viewport_size := viewport.get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return design_size
	return viewport_size
