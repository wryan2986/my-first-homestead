class_name FarmAnimalCard
extends Area2D

signal tapped(card: FarmAnimalCard)

@export var animal_id := ""
@export var animal_name := "Animal"
@export var icon_sprite: NodePath
@export var title_label: NodePath
@export var status_label: NodePath
@export var selection_ring: NodePath
@export var completion_badge: NodePath
@export var dirt_texture: Texture2D
@export var idle_texture: Texture2D
@export var happy_texture: Texture2D
@export var card_movement_texture: Texture2D
@export var animal_art_faces_left := false
@export var card_roam_enabled := false
@export var card_roam_bounds := Rect2(Vector2(-36.0, -58.0), Vector2(72.0, 36.0))
@export var card_roam_idle_range := Vector2(1.6, 3.2)
@export var card_roam_move_duration_range := Vector2(1.0, 1.8)
@export var card_walk_frame_interval := 0.2

var _completed := false
var _card_roam_tween: Tween
var _card_animal_base_scale := Vector2.ONE
var _card_is_walking := false
var _card_walk_cycle_id := 0
var _card_walk_frame_index := 0
var _dirt_sprites: Array[Sprite2D] = []
@onready var _icon_sprite: Sprite2D = get_node_or_null(icon_sprite) as Sprite2D
@onready var _title_label: Label = get_node_or_null(title_label) as Label
@onready var _status_label: Label = get_node_or_null(status_label) as Label
@onready var _selection_ring: CanvasItem = get_node_or_null(selection_ring) as CanvasItem
@onready var _completion_badge: CanvasItem = get_node_or_null(completion_badge) as CanvasItem


func _ready() -> void:
	input_pickable = true
	if _title_label != null:
		FarmFeedback.hide_label(_title_label)
	if _status_label != null:
		FarmFeedback.hide_label(_status_label)
	if _icon_sprite != null:
		_card_animal_base_scale = _icon_sprite.scale
		if idle_texture != null:
			_icon_sprite.texture = idle_texture
		_build_dirt_overlays()
	if _selection_ring != null:
		_selection_ring.visible = false
	if _completion_badge != null:
		_completion_badge.visible = false
	if card_roam_enabled:
		call_deferred("_begin_card_roam_cycle")


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		get_viewport().set_input_as_handled()
		emit_signal("tapped", self)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		emit_signal("tapped", self)


func set_selected(selected: bool) -> void:
	if _selection_ring != null:
		_selection_ring.visible = selected
	if selected:
		FarmFeedback.pulse(self, 1.06)


func set_completed(completed: bool, message: String = "All done!") -> void:
	_completed = completed
	if _completion_badge != null:
		_completion_badge.visible = completed
	if _status_label != null:
		FarmFeedback.hide_label(_status_label)
	if _icon_sprite != null:
		_icon_sprite.texture = _get_card_rest_texture()
		_set_dirt_visible(not completed)
	if completed:
		FarmFeedback.bounce(self, 18.0, 0.09)
		FarmFeedback.flash(self, Color(1.0, 1.2, 0.95, 1.0), 0.09)


func cheer(message: String) -> void:
	set_completed(true, message)


func is_completed() -> bool:
	return _completed


func set_card_enabled(enabled: bool) -> void:
	input_pickable = enabled
	monitoring = enabled
	modulate = Color(1.0, 1.0, 1.0, 1.0) if enabled else Color(1.0, 1.0, 1.0, 0.45)
	if enabled and card_roam_enabled:
		call_deferred("_begin_card_roam_cycle")
	elif not enabled:
		_stop_card_roam()


func get_animal_global_position() -> Vector2:
	if _icon_sprite != null:
		return _icon_sprite.global_position
	return global_position


func _begin_card_roam_cycle() -> void:
	if not card_roam_enabled or _icon_sprite == null or not is_inside_tree() or not visible or not input_pickable:
		return
	_kill_card_tween(_card_roam_tween)
	var target := Vector2(
		randf_range(card_roam_bounds.position.x, card_roam_bounds.position.x + card_roam_bounds.size.x),
		randf_range(card_roam_bounds.position.y, card_roam_bounds.position.y + card_roam_bounds.size.y)
	)
	var wait_time := randf_range(card_roam_idle_range.x, card_roam_idle_range.y)
	var move_time := randf_range(card_roam_move_duration_range.x, card_roam_move_duration_range.y)
	_card_roam_tween = create_tween()
	_card_roam_tween.tween_interval(wait_time)
	_card_roam_tween.tween_callback(Callable(self, "_set_card_walking").bind(true, target))
	_card_roam_tween.tween_property(_icon_sprite, "position", target, move_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_roam_tween.tween_callback(Callable(self, "_set_card_walking").bind(false))
	_card_roam_tween.tween_callback(Callable(self, "_begin_card_roam_cycle"))


func _set_card_walking(walking: bool, target_position: Vector2 = Vector2.INF) -> void:
	if _icon_sprite == null:
		return
	_card_is_walking = walking
	_card_walk_cycle_id += 1
	if walking:
		if target_position != Vector2.INF:
			_card_face_direction(target_position.x - _icon_sprite.position.x)
		_card_walk_frame_index = 0
		_cycle_card_walk_frame(_card_walk_cycle_id)
	else:
		_icon_sprite.texture = _get_card_rest_texture()
		_icon_sprite.scale = Vector2(absf(_card_animal_base_scale.x), _card_animal_base_scale.y)


func _cycle_card_walk_frame(cycle_id: int) -> void:
	if not _card_is_walking or cycle_id != _card_walk_cycle_id or _icon_sprite == null or not is_inside_tree():
		return
	if card_movement_texture != null and _card_walk_frame_index % 2 == 0:
		_icon_sprite.texture = card_movement_texture
	else:
		_icon_sprite.texture = _get_card_rest_texture()
	_card_walk_frame_index += 1
	get_tree().create_timer(card_walk_frame_interval).timeout.connect(func() -> void:
		if is_instance_valid(self):
			_cycle_card_walk_frame(cycle_id)
	)


func _card_face_direction(delta_x: float) -> void:
	if _icon_sprite == null or absf(delta_x) < 1.0:
		return
	_icon_sprite.scale = Vector2(_get_facing_scale_x(delta_x, _card_animal_base_scale.x), _card_animal_base_scale.y)


func _get_facing_scale_x(delta_x: float, base_scale_x: float) -> float:
	var moving_left := delta_x < 0.0
	var should_flip := moving_left != animal_art_faces_left
	var direction := -1.0 if should_flip else 1.0
	return absf(base_scale_x) * direction


func _get_card_rest_texture() -> Texture2D:
	if _completed and happy_texture != null:
		return happy_texture
	if idle_texture != null:
		return idle_texture
	return _icon_sprite.texture if _icon_sprite != null else null


func _build_dirt_overlays() -> void:
	if _icon_sprite == null or dirt_texture == null or not _dirt_sprites.is_empty():
		return
	var positions: Array[Vector2] = [
		Vector2(-48.0, -12.0),
		Vector2(34.0, -26.0),
		Vector2(10.0, 36.0),
	]
	var scales: Array[Vector2] = [
		Vector2(0.11, 0.08),
		Vector2(0.09, 0.07),
		Vector2(0.075, 0.055),
	]
	for index in positions.size():
		var dirt := Sprite2D.new()
		dirt.name = "DirtSmudge%d" % (index + 1)
		dirt.texture = dirt_texture
		dirt.position = positions[index]
		dirt.scale = scales[index]
		dirt.z_index = _icon_sprite.z_index + 1
		dirt.modulate = Color(0.42, 0.28, 0.17, 0.76)
		_icon_sprite.add_child(dirt)
		_dirt_sprites.append(dirt)


func _set_dirt_visible(visible: bool) -> void:
	for dirt in _dirt_sprites:
		if dirt != null and is_instance_valid(dirt):
			dirt.visible = visible


func _stop_card_roam() -> void:
	_card_is_walking = false
	_card_walk_cycle_id += 1
	_kill_card_tween(_card_roam_tween)
	_card_roam_tween = null
	if _icon_sprite != null:
		_icon_sprite.texture = _get_card_rest_texture()
		_icon_sprite.scale = Vector2(absf(_card_animal_base_scale.x), _card_animal_base_scale.y)


func _kill_card_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
