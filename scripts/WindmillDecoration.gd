extends Sprite2D

@export var fan_center_offset := Vector2(-12.0, -246.0)
@export var fan_center_node_path := NodePath("FanCenter")
@export var fan_sprite_node_path := NodePath("FanCenter/FanSprite")
@export var fan_frame_paths: PackedStringArray = [
	"res://art/props/decoration_windmill_fan_0.png",
	"res://art/props/decoration_windmill_fan_1.png",
	"res://art/props/decoration_windmill_fan_2.png",
	"res://art/props/decoration_windmill_fan_3.png",
]
@export var fan_frame_duration := 0.14
@export var fan_spin_duration := 3.0
@export var fan_spin_rotations := 4.0
@export var whoosh_volume_db := -18.0

var _fan_center: Node2D
var _fan_sprite: Sprite2D
var _fan_frames: Array[Texture2D] = []
var _fan_tween: Tween
var _whoosh_stream: AudioStreamWAV
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_load_fan_frames()
	_build_fan_overlay()
	_whoosh_stream = _build_whoosh_stream()


func handle_tap() -> void:
	if not is_visible_in_tree():
		return
	get_viewport().set_input_as_handled()
	FarmFeedback.pulse(self, 1.02, 0.08)
	FarmFeedback.flash(self, Color(1.08, 1.08, 1.02, 1.0), 0.08)
	_play_whoosh()
	_play_fan_spin()


func _load_fan_frames() -> void:
	_fan_frames.clear()
	for frame_path in fan_frame_paths:
		var frame_texture := load(frame_path) as Texture2D
		if frame_texture != null:
			_fan_frames.append(frame_texture)


func _build_fan_overlay() -> void:
	if _fan_frames.is_empty():
		push_warning("WindmillDecoration: no fan frame textures loaded.")
		return

	_fan_center = get_node_or_null(fan_center_node_path) as Node2D
	if _fan_center == null:
		_fan_center = Node2D.new()
		_fan_center.name = "FanCenter"
		_fan_center.position = fan_center_offset
		add_child(_fan_center)

	_fan_sprite = get_node_or_null(fan_sprite_node_path) as Sprite2D
	if _fan_sprite == null:
		_fan_sprite = Sprite2D.new()
		_fan_sprite.name = "FanSprite"
		_fan_center.add_child(_fan_sprite)

	_fan_sprite.texture = _fan_frames[0]
	_fan_sprite.centered = true
	_fan_sprite.visible = true
	_fan_sprite.z_index = z_index + 1


func _play_fan_spin() -> void:
	if _fan_center == null or not is_instance_valid(_fan_center):
		return
	if _fan_sprite == null or not is_instance_valid(_fan_sprite):
		return
	if _fan_frames.is_empty():
		return
	if _fan_tween != null and _fan_tween.is_valid():
		_fan_tween.kill()

	_fan_sprite.visible = true
	_fan_sprite.texture = _fan_frames[0]
	_fan_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

	var start_rotation := _fan_center.rotation
	var spin_amount := -TAU * maxf(0.25, fan_spin_rotations)
	var spin_duration := maxf(0.25, fan_spin_duration)
	var ease_in_duration := minf(0.35, spin_duration * 0.24)
	var ease_in_rotation := spin_amount * 0.18

	_fan_tween = create_tween()
	_fan_tween.tween_property(_fan_center, "rotation", start_rotation + ease_in_rotation, ease_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_fan_tween.tween_property(_fan_center, "rotation", start_rotation + spin_amount, spin_duration - ease_in_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_fan_tween.tween_callback(Callable(self, "_normalize_fan_rotation"))


func _set_fan_frame(frame_index: int) -> void:
	if _fan_sprite == null or not is_instance_valid(_fan_sprite):
		return
	if _fan_frames.is_empty():
		return
	var clamped_index := clampi(frame_index, 0, _fan_frames.size() - 1)
	_fan_sprite.texture = _fan_frames[clamped_index]


func _normalize_fan_rotation() -> void:
	if _fan_center == null or not is_instance_valid(_fan_center):
		return
	_fan_center.rotation = fposmod(_fan_center.rotation, TAU)


func _play_whoosh() -> void:
	if _whoosh_stream == null:
		return
	FarmFeedback.play_one_shot(self, _whoosh_stream, whoosh_volume_db)


func _build_whoosh_stream() -> AudioStreamWAV:
	var sample_rate := 24000
	var duration_seconds := 0.9
	var total_samples := int(duration_seconds * float(sample_rate))
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)

	var noise_state := 0.0
	var byte_index := 0
	for sample_index in total_samples:
		var t := float(sample_index) / float(total_samples)
		var env := sin(PI * t)
		env *= env
		var sweep := lerpf(0.42, 0.95, 1.0 - t)
		var air_noise := _rng.randf_range(-1.0, 1.0)
		noise_state = lerpf(noise_state, air_noise, 0.14)
		var whisper := noise_state * 0.8 + sin(TAU * (220.0 * sweep) * float(sample_index) / float(sample_rate)) * 0.2
		var sample_value := int(clampf(whisper * env * 11000.0, -32768.0, 32767.0))
		bytes[byte_index] = sample_value & 0xFF
		bytes[byte_index + 1] = (sample_value >> 8) & 0xFF
		byte_index += 2

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.stereo = false
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream
