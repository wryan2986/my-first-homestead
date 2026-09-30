extends Node2D

# Autopilot for capturing real gameplay footage with continuous motion
@onready var egg_scene: Node2D = $EggCollectingScene
@onready var timer: Timer = $AutopilotTimer

var _elapsed := 0.0
var _chicken_hop_timer := 0.0

func _ready() -> void:
	# Ensure clean state BEFORE egg_scene initializes? But child already did. So reset now and reconfigure.
	if FarmState.has_method("debug_reset_today"):
		FarmState.debug_reset_today()
	else:
		FarmState.reset_all_state()
	# Also clear any completion state
	await get_tree().process_frame
	await get_tree().process_frame
	# Force reset egg_scene internal counters
	if egg_scene != null:
		egg_scene.set("_completion_active", false)
		egg_scene.set("_basket_arrived_count", 0)
		# Hide completion panel
		var panel = egg_scene.get_node_or_null(egg_scene.completion_panel)
		if panel != null:
			panel.visible = false
		var back = egg_scene.get_node_or_null(egg_scene.back_button)
		if back != null:
			back.visible = false
		# Re-configure eggs to ensure all 6 visible
		for path in egg_scene.egg_paths:
			var egg = egg_scene.get_node_or_null(path) as EggCollectible
			if egg != null:
				egg.configure(false)
				egg.visible = true
				egg.set("_is_collected", false)
				egg.input_pickable = true
				egg.modulate.a = 1.0
				egg.scale = Vector2.ONE
				egg.position = egg.position # keep
		if egg_scene.has_method("_refresh_ui"):
			egg_scene.call("_refresh_ui", true)
		# Also reset basket fill visual
		var basket_fill = egg_scene.get_node_or_null(egg_scene.basket_fill_visual)
		if basket_fill != null and basket_fill.has_method("set_collected_count"):
			basket_fill.call("set_collected_count", 0, 6, false)
		# Make chickens lively
		for cpath in egg_scene.chicken_paths:
			var chicken = egg_scene.get_node_or_null(cpath) as BouncyCritter
			if chicken != null:
				chicken.autonomous_movement_enabled = true
				chicken.idle_duration_range = Vector2(0.35, 0.85)
				chicken.waddle_distance_range = Vector2(45, 110)
				chicken.move_speed = 110.0
				chicken.cluck_interval_range = Vector2(2.0, 4.0)
				chicken.random_clucks_enabled = true
				chicken.movement_bounds = Rect2(120, 740, 1680, 220)
				# Ensure visible
				chicken.visible = true
	print("[AutoCapture] reset complete, starting autopilot")
	await get_tree().create_timer(0.6).timeout
	timer.wait_time = 2.05
	timer.timeout.connect(_on_autopilot_tick)
	timer.start()
	print("[AutoCapture] lively started")

func _process(delta: float) -> void:
	_elapsed += delta
	_chicken_hop_timer += delta
	if _chicken_hop_timer > 0.85:
		_chicken_hop_timer = 0.0
		if egg_scene != null and not egg_scene.chicken_paths.is_empty():
			var idx = randi() % egg_scene.chicken_paths.size()
			var chicken = egg_scene.get_node_or_null(egg_scene.chicken_paths[idx]) as BouncyCritter
			if chicken != null:
				chicken.hop()

func _on_autopilot_tick() -> void:
	if egg_scene == null:
		return
	print("[AutoCapture] tick at ", _elapsed, " collected count ", FarmState.get_collected_egg_count(), " completion_active ", egg_scene.get("_completion_active"))
	var collected := false
	# Try scene's method first
	if egg_scene.has_method("_collect_next_available_egg"):
		collected = egg_scene.call("_collect_next_available_egg")
		print("[AutoCapture] _collect_next returned ", collected)
	if not collected:
		for path in egg_scene.egg_paths:
			var egg = egg_scene.get_node_or_null(path) as EggCollectible
			if egg != null:
				print("[AutoCapture] checking egg ", egg.egg_id, " visible ", egg.visible, " collected ", FarmState.is_egg_collected(egg.egg_id), " _is_collected ", egg.get("_is_collected"))
			if egg != null and egg.visible and not FarmState.is_egg_collected(egg.egg_id):
				if egg_scene.has_method("_collect_egg"):
					collected = egg_scene.call("_collect_egg", egg)
					print("[AutoCapture] _collect_egg returned ", collected)
				else:
					egg.emit_signal("collected", egg)
					collected = true
				break
	if collected:
		print("[AutoCapture] collected egg at ", _elapsed, " now count ", FarmState.get_collected_egg_count())
		# Check if should stop after 6
		if FarmState.get_collected_egg_count() >= 6:
			print("[AutoCapture] all eggs collected, will finish after delay")
			# Don't stop timer immediately, let completion animation play, but prevent further collects
			# Timer will keep firing but no eggs left, then we'll stop
	else:
		print("[AutoCapture] no more eggs, stopping timer at ", _elapsed)
		timer.stop()
		await get_tree().create_timer(3.2).timeout
