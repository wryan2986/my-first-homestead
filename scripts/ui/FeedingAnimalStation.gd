class_name FeedingAnimalStation
extends FarmAnimalCard

@export var feed_pile: NodePath
@export var feed_target: NodePath
@export var eat_target: NodePath
@export var feed_target_offset := Vector2(0.0, 60.0)
@export var walk_texture: Texture2D
@export var eating_texture: Texture2D
@export var show_feed_pile_when_fed := true
@export var pile_reveal_duration := 0.32
@export var roam_enabled := true
@export var roam_bounds := Rect2(Vector2(-96.0, -104.0), Vector2(192.0, 72.0))
@export var roam_idle_range := Vector2(1.2, 2.8)
@export var roam_move_duration_range := Vector2(1.0, 1.9)
@export var walk_frame_interval := 0.18
@export var eat_position := Vector2(0.0, -38.0)
@export var eat_bob_distance := 6.0

var _fill_tween: Tween
var _roam_tween: Tween
var _eat_tween: Tween
var _feed_pile_base_scale := Vector2.ONE
var _feed_pile_base_modulate := Color.WHITE
var _animal_base_scale := Vector2.ONE
var _is_eating := false
var _is_walking := false
var _walk_cycle_id := 0
var _walk_frame_index := 0
@onready var _feed_pile: Node2D = get_node_or_null(feed_pile) as Node2D
@onready var _feed_target: Node2D = get_node_or_null(feed_target) as Node2D
@onready var _eat_target: Node2D = get_node_or_null(eat_target) as Node2D


func _ready() -> void:
	super._ready()
	if _feed_target != null:
		_feed_target.position = feed_target_offset
	if _feed_pile != null:
		_feed_pile.position = feed_target_offset
	if _icon_sprite != null:
		_animal_base_scale = _icon_sprite.scale
	if _feed_pile != null:
		_feed_pile_base_scale = _feed_pile.scale
		_feed_pile_base_modulate = _feed_pile.modulate
		set_feed_visible(false, false)
	if roam_enabled:
		call_deferred("_begin_roam_cycle")


func get_feed_target_global_position() -> Vector2:
	if _feed_target != null:
		return _feed_target.global_position
	return global_position


func set_feed_visible(filled: bool, animated: bool = true) -> void:
	if _feed_pile == null:
		return

	if _fill_tween != null:
		_fill_tween.kill()
		_fill_tween = null

	if not filled:
		_stop_eating()
		_feed_pile.visible = false
		_feed_pile.scale = Vector2(_feed_pile_base_scale.x * 0.12, _feed_pile_base_scale.y * 0.45)
		_feed_pile.modulate = Color(
			_feed_pile_base_modulate.r,
			_feed_pile_base_modulate.g,
			_feed_pile_base_modulate.b,
			0.0
		)
		return

	if not show_feed_pile_when_fed:
		_feed_pile.visible = false
		_finish_fill_reveal()
		return

	_feed_pile.visible = true
	if not animated:
		_feed_pile.scale = _feed_pile_base_scale
		_feed_pile.modulate = _feed_pile_base_modulate
		return

	_feed_pile.scale = Vector2(_feed_pile_base_scale.x * 0.18, _feed_pile_base_scale.y * 0.48)
	_feed_pile.modulate = Color(
		_feed_pile_base_modulate.r,
		_feed_pile_base_modulate.g,
		_feed_pile_base_modulate.b,
		0.0
	)
	_fill_tween = create_tween()
	_fill_tween.set_parallel(true)
	_fill_tween.tween_property(_feed_pile, "scale", _feed_pile_base_scale, pile_reveal_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fill_tween.tween_property(_feed_pile, "modulate", _feed_pile_base_modulate, pile_reveal_duration * 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_fill_tween.chain().tween_callback(Callable(self, "_finish_fill_reveal"))


func _finish_fill_reveal() -> void:
	_fill_tween = null
	FarmFeedback.flash(self, Color(1.12, 1.08, 0.92, 1.0), 0.08)


func move_to_trough_and_eat(animated: bool = true) -> void:
	if _icon_sprite == null:
		return
	var target_position := _get_eat_position()
	_is_eating = true
	_kill_tween(_roam_tween)
	_roam_tween = null
	_kill_tween(_eat_tween)
	_eat_tween = null

	if animated:
		_set_walking(true, target_position)
		var tween := create_tween()
		tween.tween_property(_icon_sprite, "position", target_position, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(Callable(self, "_set_walking").bind(false))
		tween.tween_property(_icon_sprite, "scale", _animal_base_scale * 1.05, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.chain().tween_callback(Callable(self, "_start_eating_bob"))
	else:
		_set_walking(false)
		_icon_sprite.position = target_position
		_icon_sprite.scale = _animal_base_scale * 1.05
		_start_eating_bob()


func _begin_roam_cycle() -> void:
	if _is_eating or not roam_enabled or _icon_sprite == null or not is_inside_tree():
		return
	_kill_tween(_roam_tween)
	var target := Vector2(
		randf_range(roam_bounds.position.x, roam_bounds.position.x + roam_bounds.size.x),
		randf_range(roam_bounds.position.y, roam_bounds.position.y + roam_bounds.size.y)
	)
	var wait_time := randf_range(roam_idle_range.x, roam_idle_range.y)
	var move_time := randf_range(roam_move_duration_range.x, roam_move_duration_range.y)
	_roam_tween = create_tween()
	_roam_tween.tween_interval(wait_time)
	_roam_tween.tween_callback(Callable(self, "_set_walking").bind(true, target))
	_roam_tween.tween_property(_icon_sprite, "position", target, move_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_roam_tween.tween_callback(Callable(self, "_set_walking").bind(false))
	_roam_tween.tween_callback(Callable(self, "_begin_roam_cycle"))


func _start_eating_bob() -> void:
	if _icon_sprite == null or not _is_eating:
		return
	var target_position := _get_eat_position()
	_icon_sprite.texture = _get_eating_texture()
	_icon_sprite.scale = _animal_base_scale * 1.05
	_kill_tween(_eat_tween)
	_eat_tween = create_tween()
	_eat_tween.set_loops()
	_eat_tween.tween_property(_icon_sprite, "position", target_position + Vector2(0.0, eat_bob_distance), 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_eat_tween.tween_property(_icon_sprite, "position", target_position, 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _get_eat_position() -> Vector2:
	if _eat_target != null:
		return _eat_target.position
	return eat_position


func _stop_eating() -> void:
	if not _is_eating:
		return
	_is_eating = false
	_kill_tween(_eat_tween)
	_eat_tween = null
	if _icon_sprite != null:
		_icon_sprite.texture = idle_texture if idle_texture != null else _icon_sprite.texture
		_icon_sprite.scale = _animal_base_scale
	if roam_enabled:
		call_deferred("_begin_roam_cycle")


func _set_walking(walking: bool, target_position: Vector2 = Vector2.INF) -> void:
	if _icon_sprite == null:
		return
	_is_walking = walking
	_walk_cycle_id += 1
	if walking:
		if target_position != Vector2.INF:
			_face_direction(target_position.x - _icon_sprite.position.x)
		_walk_frame_index = 0
		_cycle_walk_frame(_walk_cycle_id)
	else:
		_icon_sprite.texture = idle_texture if idle_texture != null else _icon_sprite.texture
		_icon_sprite.scale = Vector2(absf(_animal_base_scale.x), _animal_base_scale.y)


func _cycle_walk_frame(cycle_id: int) -> void:
	if not _is_walking or cycle_id != _walk_cycle_id or _icon_sprite == null or not is_inside_tree():
		return
	if walk_texture != null and _walk_frame_index % 2 == 0:
		_icon_sprite.texture = walk_texture
	elif idle_texture != null:
		_icon_sprite.texture = idle_texture
	_walk_frame_index += 1
	get_tree().create_timer(walk_frame_interval).timeout.connect(func() -> void:
		if is_instance_valid(self):
			_cycle_walk_frame(cycle_id)
	)


func _face_direction(delta_x: float) -> void:
	if absf(delta_x) < 1.0:
		return
	_icon_sprite.scale = Vector2(_get_facing_scale_x(delta_x, _animal_base_scale.x), _animal_base_scale.y)


func _get_eating_texture() -> Texture2D:
	if eating_texture != null:
		return eating_texture
	if happy_texture != null:
		return happy_texture
	return _icon_sprite.texture


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
