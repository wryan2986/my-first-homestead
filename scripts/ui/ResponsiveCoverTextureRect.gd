class_name ResponsiveCoverTextureRect
extends TextureRect

const DESIGN_SIZE := Vector2(1920.0, 1080.0)

@export var design_size := DESIGN_SIZE

var _connected_viewport: Viewport


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
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
	set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	position = Vector2.ZERO
	size = _get_viewport_size()


func _get_viewport_size() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return design_size
	var viewport_size := viewport.get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return design_size
	return viewport_size
