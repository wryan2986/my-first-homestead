class_name EggBasketFill
extends Node2D

@export var egg_texture: Texture2D
@export var egg_positions: Array[Vector2] = [
	Vector2(-88.0, -26.0),
	Vector2(-42.0, -48.0),
	Vector2(4.0, -34.0),
	Vector2(50.0, -50.0),
	Vector2(96.0, -28.0),
]
@export var egg_scale := Vector2(0.34, 0.34)
@export var egg_modulate := Color(1.0, 0.96, 0.82, 1.0)
@export var egg_z_index := 0
@export var pop_duration := 0.16
@export var pop_scale_multiplier := 1.2

var _egg_sprites: Array[Sprite2D] = []


func _ready() -> void:
	_ensure_egg_sprites(egg_positions.size())
	set_collected_count(0, egg_positions.size(), false)


func set_collected_count(collected_count: int, total_count: int = -1, animate_new: bool = true) -> void:
	var desired_total := total_count if total_count > 0 else egg_positions.size()
	_ensure_egg_sprites(desired_total)
	var clamped_count := clampi(collected_count, 0, _egg_sprites.size())

	for index in _egg_sprites.size():
		var egg := _egg_sprites[index]
		var should_show := index < clamped_count
		if should_show and not egg.visible and animate_new:
			_pop_in_egg(egg)
		else:
			egg.visible = should_show
			egg.modulate = egg_modulate
			egg.scale = egg_scale


func _ensure_egg_sprites(total_count: int) -> void:
	while _egg_sprites.size() < total_count:
		var index := _egg_sprites.size()
		var egg := Sprite2D.new()
		egg.name = "BasketEgg%d" % (index + 1)
		egg.texture = egg_texture
		egg.position = _get_egg_position(index, total_count)
		egg.scale = egg_scale
		egg.modulate = egg_modulate
		egg.visible = false
		egg.z_index = egg_z_index
		add_child(egg)
		_egg_sprites.append(egg)

	for index in _egg_sprites.size():
		_egg_sprites[index].texture = egg_texture
		_egg_sprites[index].position = _get_egg_position(index, total_count)
		_egg_sprites[index].z_index = egg_z_index


func _get_egg_position(index: int, total_count: int) -> Vector2:
	if index < egg_positions.size():
		return egg_positions[index]

	var columns := ceili(sqrt(float(total_count)))
	var column := index % columns
	var row := int(floor(float(index) / float(columns)))
	return Vector2(
		(float(column) - float(columns - 1) * 0.5) * 46.0,
		-48.0 + float(row) * 32.0
	)


func _pop_in_egg(egg: Sprite2D) -> void:
	egg.visible = true
	egg.modulate = Color(egg_modulate.r, egg_modulate.g, egg_modulate.b, 0.0)
	egg.scale = egg_scale * 0.35

	var tween := egg.create_tween()
	tween.set_parallel(true)
	tween.tween_property(egg, "modulate:a", egg_modulate.a, pop_duration)
	tween.tween_property(egg, "scale", egg_scale * pop_scale_multiplier, pop_duration)
	tween.chain().tween_property(egg, "scale", egg_scale, pop_duration * 0.6)
