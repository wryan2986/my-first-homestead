class_name ResponsiveCoverSprite2D
extends Sprite2D

const DESIGN_SIZE := Vector2(1920.0, 1080.0)

@export var design_size := DESIGN_SIZE

var _connected_viewport: Viewport


func _ready() -> void:
	centered = false
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
	if texture == null:
		position = Vector2.ZERO
		scale = Vector2.ONE
		return
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		position = Vector2.ZERO
		scale = Vector2.ONE
		return
	var cover_scale := maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	scale = Vector2.ONE * cover_scale
	position = (viewport_size - texture_size * cover_scale) * 0.5


func _get_viewport_size() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return design_size
	var viewport_size := viewport.get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return design_size
	return viewport_size
