class_name SceneHotspot
extends Area2D

@export var target_scene: PackedScene
@export var visual_node: NodePath
@export var tap_sound: AudioStream

@onready var _visual_node: CanvasItem = get_node_or_null(visual_node) as CanvasItem


func _ready() -> void:
	input_pickable = true


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		handle_tap()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_tap()


func handle_tap() -> void:
	_activate()


func _activate() -> void:
	get_viewport().set_input_as_handled()
	FarmFeedback.pulse(_visual_node if _visual_node != null else self)
	FarmFeedback.flash(_visual_node if _visual_node != null else self)
	FarmFeedback.play_one_shot(self, tap_sound, -5.0)
	if target_scene != null:
		var navigator := get_tree().root.get_node_or_null("SceneNavigator")
		if navigator != null and navigator.has_method("go_to_activity"):
			if bool(navigator.call("go_to_activity", name, target_scene)):
				return
		get_tree().change_scene_to_packed(target_scene)
