class_name GardenBasketFill
extends Node2D

@export var crop_positions: Array[Vector2] = [
	Vector2(-74.0, -34.0),
	Vector2(-34.0, -48.0),
	Vector2(6.0, -36.0),
	Vector2(44.0, -50.0),
	Vector2(82.0, -32.0),
]
@export var crop_scale := Vector2(0.25, 0.25)
@export var crop_z_index := 0
@export var pop_duration := 0.16
@export var pop_scale_multiplier := 1.18

var _crop_sprites: Array[Sprite2D] = []


func _ready() -> void:
	clear()


func clear() -> void:
	for crop in _crop_sprites:
		if is_instance_valid(crop):
			crop.queue_free()
	_crop_sprites.clear()


func add_crop(texture: Texture2D, modulate_color: Color = Color.WHITE, requested_scale := Vector2.ZERO) -> void:
	if texture == null:
		return

	var crop := Sprite2D.new()
	var final_scale := requested_scale if requested_scale != Vector2.ZERO else crop_scale
	var index := _crop_sprites.size()
	crop.name = "BasketCrop%d" % (index + 1)
	crop.texture = texture
	crop.position = _get_crop_position(index)
	crop.scale = final_scale * 0.35
	crop.modulate = Color(modulate_color.r, modulate_color.g, modulate_color.b, 0.0)
	crop.z_index = crop_z_index
	add_child(crop)
	_crop_sprites.append(crop)
	_pop_in_crop(crop, modulate_color, final_scale)


func _get_crop_position(index: int) -> Vector2:
	if index < crop_positions.size():
		return crop_positions[index]

	var columns := ceili(sqrt(float(index + 1)))
	var column := index % columns
	var row := int(floor(float(index) / float(columns)))
	return Vector2(
		(float(column) - float(columns - 1) * 0.5) * 36.0,
		-46.0 + float(row) * 24.0
	)


func _pop_in_crop(crop: Sprite2D, modulate_color: Color, final_scale: Vector2) -> void:
	crop.visible = true
	var tween := crop.create_tween()
	tween.set_parallel(true)
	tween.tween_property(crop, "modulate:a", modulate_color.a, pop_duration)
	tween.tween_property(crop, "scale", final_scale * pop_scale_multiplier, pop_duration)
	tween.chain().tween_property(crop, "scale", final_scale, pop_duration * 0.6)
