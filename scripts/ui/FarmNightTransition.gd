class_name FarmNightTransition
extends Control

const MOON_DESIGN_POSITION := Vector2(1560.0, 150.0)
const DESIGN_SIZE := Vector2(1920.0, 1080.0)

@export var overlay: NodePath
@export var firefly_texture: Texture2D
@export var night_ambience: AudioStream
@export var night_ambience_clips: Array[AudioStream] = []
@export var owl_sound: AudioStream
@export var owl_sounds: Array[AudioStream] = []
@export var transition_duration := 4.2
@export var firefly_count := 16
@export var star_count := 34
@export var min_firefly_scale := 0.62
@export var max_firefly_scale := 0.95
@export var min_star_radius := 18.0
@export var max_star_radius := 30.0
@export var min_firefly_spacing := 110.0
@export var min_star_spacing := 92.0
@export var star_moon_exclusion_radius := 145.0
@export var placement_attempts := 18
@export var overlay_alpha := 0.56

@onready var _overlay: ColorRect = get_node_or_null(overlay) as ColorRect

var _rng := RandomNumberGenerator.new()
var _active := false
var _ambience_player: AudioStreamPlayer
var _moon_phase_day := 2
var _connected_viewport: Viewport


func _ready() -> void:
	_rng.seed = int(Time.get_ticks_usec()) + get_instance_id()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_connect_viewport()
	_apply_viewport_size()
	if _overlay != null:
		_overlay.color.a = 0.0
	_build_ambience_player()


func _exit_tree() -> void:
	if _connected_viewport != null and _connected_viewport.size_changed.is_connected(_apply_viewport_size):
		_connected_viewport.size_changed.disconnect(_apply_viewport_size)


func play_transition(day_in_season: int = 2) -> void:
	if _active:
		return
	_active = true
	_moon_phase_day = clampi(day_in_season, 1, 3)
	_apply_viewport_size()
	visible = true
	if _overlay != null:
		_overlay.color.a = 0.0
		var tween := create_tween()
		tween.tween_property(_overlay, "color:a", overlay_alpha, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_interval(maxf(0.0, transition_duration - 1.5))
		tween.tween_property(_overlay, "color:a", 0.0, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_callback(_finish_transition)
	_play_night_audio()
	_spawn_moon(_moon_phase_day)
	_spawn_stars()
	_spawn_fireflies()


func get_transition_duration() -> float:
	return transition_duration


func is_active() -> bool:
	return _active


func _spawn_fireflies() -> void:
	if firefly_texture == null:
		return
	var viewport_size := _get_viewport_size()
	var x_range := Vector2(120.0, maxf(121.0, viewport_size.x - 120.0))
	var y_range := Vector2(viewport_size.y * 0.28, viewport_size.y * 0.82)
	var placed_positions: Array[Vector2] = []
	for index in firefly_count:
		var firefly := Sprite2D.new()
		firefly.texture = firefly_texture
		firefly.z_index = 40
		firefly.position = _find_spaced_point(placed_positions, x_range, y_range, min_firefly_spacing)
		placed_positions.append(firefly.position)
		firefly.scale = Vector2.ONE * _rng.randf_range(min_firefly_scale, max_firefly_scale)
		firefly.modulate = Color(1.0, 0.98, 0.55, 0.0)
		add_child(firefly)
		var drift := Vector2(_rng.randf_range(-60.0, 60.0), _rng.randf_range(-34.0, 28.0))
		var start_delay := _rng.randf_range(0.15, 1.0)
		var tween := firefly.create_tween()
		tween.tween_interval(start_delay)
		tween.tween_property(firefly, "modulate:a", _rng.randf_range(0.48, 0.82), 0.55)
		tween.parallel().tween_property(firefly, "position", firefly.position + drift, maxf(0.7, transition_duration - start_delay - 0.6)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(firefly, "modulate:a", 0.0, 0.55)
		tween.tween_callback(firefly.queue_free)


func _spawn_stars() -> void:
	var viewport_size := _get_viewport_size()
	var moon_position := _get_moon_position(viewport_size)
	var x_range := Vector2(70.0, maxf(71.0, viewport_size.x - 70.0))
	var y_range := Vector2(48.0, maxf(49.0, minf(viewport_size.y * 0.34, 380.0)))
	var placed_positions: Array[Vector2] = []
	for index in star_count:
		var star := Polygon2D.new()
		var radius := _rng.randf_range(min_star_radius, max_star_radius)
		star.name = "NightStar"
		star.polygon = PackedVector2Array([
			Vector2(0.0, -radius),
			Vector2(radius * 0.28, -radius * 0.28),
			Vector2(radius, 0.0),
			Vector2(radius * 0.28, radius * 0.28),
			Vector2(0.0, radius),
			Vector2(-radius * 0.28, radius * 0.28),
			Vector2(-radius, 0.0),
			Vector2(-radius * 0.28, -radius * 0.28),
		])
		star.color = Color(1.0, 0.96, 0.68, 0.0)
		star.z_index = 38
		star.position = _find_spaced_point(placed_positions, x_range, y_range, maxf(min_star_spacing, radius * 2.2), moon_position, star_moon_exclusion_radius)
		placed_positions.append(star.position)
		add_child(star)
		var tween := star.create_tween()
		tween.tween_interval(_rng.randf_range(0.15, 1.0))
		tween.tween_property(star, "color:a", _rng.randf_range(0.45, 0.86), 0.5)
		tween.tween_interval(maxf(0.0, transition_duration - 1.6))
		tween.tween_property(star, "color:a", 0.0, 0.5)
		tween.tween_callback(star.queue_free)


func _spawn_moon(day_in_season: int) -> void:
	# Single-object moon with phase frames via shader, no second cutout circle.
	# Previous bug used two overlapping Polygon2D nodes (bright disc + dark cutout) showing double circles.
	var moon := Polygon2D.new()
	moon.name = "NightMoon"
	moon.z_index = 37
	moon.position = _get_moon_position(_get_viewport_size())
	moon.polygon = _circle_polygon(56.0, 28)
	moon.color = Color(1.0, 0.94, 0.68, 0.0)
	# Attach single shader that renders phase crescent without a second node.
	var moon_shader := Shader.new()
	moon_shader.code = """
shader_type canvas_item;
uniform float phase : hint_range(-1.0, 1.0) = 0.0;
uniform vec4 moon_color : source_color = vec4(1.0, 0.94, 0.68, 1.0);
void fragment() {
	float r = 0.5;
	vec2 p = UV - vec2(0.5);
	float d = length(p);
	float alpha = 1.0 - smoothstep(r - 0.02, r, d);
	if (d > r) {
		COLOR.a = 0.0;
		return;
	}
	// phase shifts terminator, -1 = new dark, 0 = half, 1 = full bright.
	float terminator = phase * 0.55;
	float shade = smoothstep(terminator - 0.08, terminator + 0.08, p.x);
	vec3 lit = moon_color.rgb;
	vec3 shadow = vec3(0.13, 0.14, 0.22);
	vec3 col = mix(shadow, lit, shade);
	COLOR = vec4(col, moon_color.a * alpha);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = moon_shader
	mat.set_shader_parameter("phase", _get_moon_phase_shader_value(day_in_season))
	mat.set_shader_parameter("moon_color", _get_moon_phase_color(day_in_season))
	moon.material = mat
	add_child(moon)
	var tween := moon.create_tween()
	tween.tween_property(moon, "color:a", _get_moon_phase_alpha(day_in_season), 0.65)
	tween.tween_interval(maxf(0.0, transition_duration - 1.55))
	tween.tween_property(moon, "color:a", 0.0, 0.45)
	tween.tween_callback(moon.queue_free)


func _get_moon_phase_shader_value(day_in_season: int) -> float:
	match day_in_season:
		1:
			return -0.9
		2:
			return 0.05
		_:
			return 0.95


func _get_moon_phase_color(day_in_season: int) -> Color:
	match day_in_season:
		1:
			return Color(0.82, 0.82, 0.76, 1.0)
		2:
			return Color(0.95, 0.91, 0.68, 1.0)
		_:
			return Color(1.0, 0.94, 0.68, 1.0)


func _get_moon_phase_alpha(day_in_season: int) -> float:
	match day_in_season:
		1:
			return 0.42
		2:
			return 0.68
		_:
			return 0.78


func _get_moon_cutout_offset(day_in_season: int) -> Vector2:
	# Kept for compatibility, no longer used by two-circle moon.
	match day_in_season:
		1:
			return Vector2.ZERO
		2:
			return Vector2(22.0, -4.0)
		_:
			return Vector2(120.0, 0.0)


func _get_moon_disc_alpha(day_in_season: int) -> float:
	return _get_moon_phase_alpha(day_in_season)


func _get_moon_cutout_alpha(day_in_season: int) -> float:
	return 0.0


func _circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for index in points:
		var angle := TAU * float(index) / float(points)
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)
	return polygon


func _connect_viewport() -> void:
	_connected_viewport = get_viewport()
	if _connected_viewport != null and not _connected_viewport.size_changed.is_connected(_apply_viewport_size):
		_connected_viewport.size_changed.connect(_apply_viewport_size)


func _apply_viewport_size() -> void:
	var viewport_size := _get_viewport_size()
	set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	position = Vector2.ZERO
	size = viewport_size


func _get_viewport_size() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return DESIGN_SIZE
	var viewport_size := viewport.get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return DESIGN_SIZE
	return viewport_size


func _get_moon_position(viewport_size: Vector2) -> Vector2:
	var design_offset := (viewport_size - DESIGN_SIZE) * 0.5
	return MOON_DESIGN_POSITION + design_offset


func _find_spaced_point(existing_points: Array[Vector2], x_range: Vector2, y_range: Vector2, min_spacing: float, avoid_point: Vector2 = Vector2.INF, avoid_radius: float = 0.0) -> Vector2:
	var fallback := Vector2(_rng.randf_range(x_range.x, x_range.y), _rng.randf_range(y_range.x, y_range.y))
	var attempts := maxi(1, placement_attempts)
	for attempt in attempts:
		var point := Vector2(_rng.randf_range(x_range.x, x_range.y), _rng.randf_range(y_range.x, y_range.y))
		fallback = point
		if avoid_point != Vector2.INF and avoid_radius > 0.0 and point.distance_to(avoid_point) < avoid_radius:
			continue
		var clear := true
		for existing in existing_points:
			if point.distance_to(existing) < min_spacing:
				clear = false
				break
		if clear:
			return point
	return fallback


func _build_ambience_player() -> void:
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "NightAmbiencePlayer"
	_ambience_player.bus = "SFX"
	_ambience_player.volume_db = -13.0
	add_child(_ambience_player)


func _play_night_audio() -> void:
	var ambience := _pick_audio_stream(night_ambience_clips, night_ambience)
	if _ambience_player != null and ambience != null:
		_ambience_player.stream = ambience
		_ambience_player.play()
	var owl := _pick_audio_stream(owl_sounds, owl_sound)
	if owl != null:
		var timer := get_tree().create_timer(1.25)
		timer.timeout.connect(func() -> void:
			if is_instance_valid(self) and _active:
				FarmFeedback.play_one_shot(self, owl, -9.0)
		)


func _pick_audio_stream(options: Array[AudioStream], fallback: AudioStream) -> AudioStream:
	var valid_options: Array[AudioStream] = []
	for stream in options:
		if stream != null:
			valid_options.append(stream)
	if valid_options.is_empty():
		return fallback
	return valid_options[_rng.randi_range(0, valid_options.size() - 1)]


func _finish_transition() -> void:
	if _ambience_player != null:
		_ambience_player.stop()
	visible = false
	_active = false
