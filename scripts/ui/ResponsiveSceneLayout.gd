class_name ResponsiveSceneLayout
extends Node

const DESIGN_SIZE := Vector2(1920.0, 1080.0)

@export var design_size := DESIGN_SIZE
@export var excluded_root_names: PackedStringArray = [
	"Hud",
	"Background",
	"BackgroundLayers",
	"CoopBackground",
	"HayFloor",
	"ResponsiveLayout",
]
@export var hud_canvas_path: NodePath = NodePath("../Hud")
@export var top_margin := 36.0
@export var side_margin := 44.0
@export var bottom_margin := 42.0
@export var center_completion_panels := true
@export var anchor_top_right_buttons := true
@export var anchor_bottom_center_feedback := true
@export var fit_design_roots_to_viewport := false

var _cached_positions: Dictionary = {}
var _cached_scales: Dictionary = {}
var _connected_viewport: Viewport


func _ready() -> void:
	_cache_design_nodes()
	_connect_viewport()
	_apply_layout()


func _exit_tree() -> void:
	if _connected_viewport != null and _connected_viewport.size_changed.is_connected(_apply_layout):
		_connected_viewport.size_changed.disconnect(_apply_layout)


func _connect_viewport() -> void:
	_connected_viewport = get_viewport()
	if _connected_viewport != null and not _connected_viewport.size_changed.is_connected(_apply_layout):
		_connected_viewport.size_changed.connect(_apply_layout)


func _cache_design_nodes() -> void:
	var scene_root := get_parent()
	if scene_root == null:
		return
	for child in scene_root.get_children():
		if child == self:
			continue
		if excluded_root_names.has(child.name):
			continue
		if child is Node2D:
			_cached_positions[child] = (child as Node2D).position
			_cached_scales[child] = (child as Node2D).scale
		elif child is Control:
			_cached_positions[child] = (child as Control).position
			_cached_scales[child] = (child as Control).scale


func _apply_layout() -> void:
	var viewport_size := _get_viewport_size()
	var scale_factor := _get_design_scale(viewport_size)
	var design_offset := (viewport_size - design_size * scale_factor) * 0.5
	for node in _cached_positions.keys():
		if node == null or not is_instance_valid(node):
			continue
		var original_position: Vector2 = _cached_positions[node]
		var original_scale: Vector2 = _cached_scales.get(node, Vector2.ONE)
		if node is Node2D:
			var node_2d := node as Node2D
			node_2d.position = original_position * scale_factor + design_offset
			node_2d.scale = original_scale * scale_factor
		elif node is Control:
			var control := node as Control
			control.position = original_position * scale_factor + design_offset
			control.scale = original_scale * scale_factor
	_apply_hud_layout(viewport_size)


func _get_design_scale(viewport_size: Vector2) -> float:
	if not fit_design_roots_to_viewport:
		return 1.0
	if design_size.x <= 0.0 or design_size.y <= 0.0:
		return 1.0
	return maxf(viewport_size.x / design_size.x, viewport_size.y / design_size.y)


func _get_viewport_size() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return design_size
	var size := viewport.get_visible_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return design_size
	return size


func _apply_hud_layout(viewport_size: Vector2) -> void:
	var hud_root := get_node_or_null(hud_canvas_path)
	if hud_root == null:
		hud_root = get_parent()
	if hud_root == null:
		return
	_anchor_named_controls(hud_root, hud_root, viewport_size)


func _anchor_named_controls(scene_root: Node, root: Node, viewport_size: Vector2) -> void:
	for child in root.get_children():
		var control := child as Control
		if control != null:
			_apply_control_anchor(scene_root, control, viewport_size)
		_anchor_named_controls(scene_root, child, viewport_size)


func _apply_control_anchor(scene_root: Node, control: Control, viewport_size: Vector2) -> void:
	var control_size := _get_control_size(control)
	if control_size.x <= 0.0 or control_size.y <= 0.0:
		return

	match String(control.name):
		"BackButton", "NextDayButton":
			if anchor_top_right_buttons:
				_set_control_position(control, Vector2(viewport_size.x - control_size.x - side_margin, top_margin))
		"SettingsButton":
			if anchor_top_right_buttons and control.get_parent() is Control:
				_set_control_position(control, Vector2(viewport_size.x - control_size.x - side_margin, top_margin))
		"SettingsPanel", "CompletionPanel":
			if center_completion_panels:
				_set_control_position(control, (viewport_size - control_size) * 0.5)
				if control.name == "CompletionPanel":
					_avoid_top_right_overlap(scene_root, control, viewport_size, "BackButton")
		"FeedbackLabel":
			if anchor_bottom_center_feedback:
				_set_control_position(control, Vector2((viewport_size.x - control_size.x) * 0.5, viewport_size.y - control_size.y - bottom_margin))
		"BackgroundOverlay":
			control.position = Vector2.ZERO


func _avoid_top_right_overlap(scene_root: Node, control: Control, viewport_size: Vector2, obstacle_name: String) -> void:
	var obstacle := _find_control_by_name(scene_root, obstacle_name)
	if obstacle == null or not is_instance_valid(obstacle) or not obstacle.visible:
		return

	var control_size := _get_control_size(control)
	var obstacle_size := _get_control_size(obstacle)
	var control_rect := Rect2(control.position, control_size)
	var obstacle_rect := Rect2(obstacle.position, obstacle_size)
	if not control_rect.intersects(obstacle_rect.grow(24.0)):
		return

	var desired_y := obstacle_rect.position.y + obstacle_rect.size.y + 24.0
	var max_y := maxf(0.0, viewport_size.y - control_size.y - bottom_margin)
	_set_control_position(control, Vector2(control.position.x, minf(max_y, desired_y)))


func _find_control_by_name(root: Node, control_name: String) -> Control:
	for child in root.get_children():
		var control := child as Control
		if control != null and control.name == control_name:
			return control
		var nested := _find_control_by_name(child, control_name)
		if nested != null:
			return nested
	return null


func _set_control_position(control: Control, position: Vector2) -> void:
	var size := _get_control_size(control)
	control.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	control.offset_left = position.x
	control.offset_top = position.y
	control.offset_right = position.x + size.x
	control.offset_bottom = position.y + size.y


func _get_control_size(control: Control) -> Vector2:
	var control_size := control.size
	if control_size.x <= 0.0 or control_size.y <= 0.0:
		control_size = Vector2(
			maxf(0.0, control.offset_right - control.offset_left),
			maxf(0.0, control.offset_bottom - control.offset_top)
		)
	var minimum_size := control.get_combined_minimum_size()
	control_size.x = maxf(control_size.x, minimum_size.x)
	control_size.y = maxf(control_size.y, minimum_size.y)
	return control_size
