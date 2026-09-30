class_name EggCollectible
extends Area2D

signal collected(egg: EggCollectible)
signal collection_animation_finished(egg: EggCollectible)

@export var egg_id := ""
@export var visual_node: NodePath
@export var egg_sprite: NodePath
@export var idle_texture: Texture2D

var _is_collected := false
@onready var _visual_node: Node2D = get_node_or_null(visual_node) as Node2D
@onready var _egg_sprite: Sprite2D = get_node_or_null(egg_sprite) as Sprite2D


func _ready() -> void:
	input_pickable = true
	if _egg_sprite != null and idle_texture != null:
		_egg_sprite.texture = idle_texture


func configure(already_collected: bool) -> void:
	_is_collected = already_collected
	visible = not already_collected
	input_pickable = not already_collected


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _is_collected:
		return

	if event is InputEventScreenTouch and event.pressed:
		get_viewport().set_input_as_handled()
		emit_signal("collected", self)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		emit_signal("collected", self)


func animate_collection(target_position: Vector2) -> void:
	_is_collected = true
	input_pickable = false
	FarmFeedback.pulse(_visual_node if _visual_node != null else self, 1.12)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target_position, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.35, 0.35), 0.45)
	tween.tween_property(self, "modulate:a", 0.0, 0.45)
	await tween.finished
	visible = false
	emit_signal("collection_animation_finished", self)
