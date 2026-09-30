extends Node

const CACHE_PREPARE_META := "_scene_navigator_cache_prepare"
const FARMYARD_ROUTE := "farmyard"
const SAVED_VISIBLE_META := "_scene_navigator_saved_visible"
const CHORE_RETURNING_META := "_farm_chore_returning_to_farmyard"
const MAX_ACTIVITY_CACHE_SIZE := 2

var _farmyard_scene: PackedScene
var _farmyard_instance: Node
var _activity_routes: Dictionary = {}
var _activity_cache: Dictionary = {}
var _cache_recency: Array[String] = []
var _active_activity: Node
var _active_route := ""
var _activity_container: Node2D
var _cache_container: Node2D
var _is_prewarming := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_activity_container = Node2D.new()
	_activity_container.name = "ActivityContainer"
	add_child(_activity_container)
	_cache_container = Node2D.new()
	_cache_container.name = "SceneWarmCache"
	_cache_container.visible = false
	add_child(_cache_container)


func show_farmyard(farmyard_scene: PackedScene) -> bool:
	if farmyard_scene == null:
		return false
	_farmyard_scene = farmyard_scene
	if _farmyard_instance == null or not is_instance_valid(_farmyard_instance):
		_farmyard_instance = farmyard_scene.instantiate()
		add_child(_farmyard_instance)
		if get_tree().current_scene != null and get_tree().current_scene != _farmyard_instance:
			get_tree().current_scene.queue_free()
		get_tree().current_scene = _farmyard_instance
	elif _farmyard_instance.get_parent() != self:
		if _farmyard_instance.get_parent() != null:
			_farmyard_instance.get_parent().remove_child(_farmyard_instance)
		add_child(_farmyard_instance)
	if get_tree().current_scene != _farmyard_instance:
		if get_tree().current_scene != null:
			get_tree().current_scene.queue_free()
		get_tree().current_scene = _farmyard_instance
	move_child(_activity_container, get_child_count() - 1)
	_show_farmyard()
	return true


func prepare_farmyard(farmyard_scene: PackedScene) -> bool:
	if farmyard_scene == null:
		return false
	_farmyard_scene = farmyard_scene
	if _farmyard_instance != null and is_instance_valid(_farmyard_instance):
		return true
	_farmyard_instance = farmyard_scene.instantiate()
	_farmyard_instance.set_meta(CACHE_PREPARE_META, true)
	add_child(_farmyard_instance)
	_hide_tree_visuals(_farmyard_instance)
	_set_node_active(_farmyard_instance, false)
	if _farmyard_instance.has_meta(CACHE_PREPARE_META):
		_farmyard_instance.remove_meta(CACHE_PREPARE_META)
	return true


func register_farmyard(farmyard: Node) -> void:
	if farmyard == null or not is_instance_valid(farmyard):
		return
	_farmyard_instance = farmyard


func register_activity_routes(routes: Dictionary) -> void:
	for route in routes.keys():
		var scene := routes[route] as PackedScene
		if scene != null:
			_activity_routes[String(route)] = scene
	# The milking scene is the heaviest chore scene and is commonly entered
	# early. It is the only route synchronously prepared during registration so
	# its hotspot never has to instantiate or initialize it on demand.
	_prewarm_route(FarmState.CHORE_MILKING)


func start_prewarm() -> void:
	if _is_prewarming:
		return
	_is_prewarming = true
	call_deferred("_prewarm_next_route")


func clear_activity_cache() -> void:
	for route in _activity_cache.keys():
		var cached := _activity_cache[route] as Node
		if cached != null and is_instance_valid(cached):
			cached.queue_free()
	_activity_cache.clear()
	_cache_recency.clear()


func rebuild_activity_cache() -> void:
	clear_activity_cache()
	start_prewarm()


func go_to_activity(route: String, scene: PackedScene = null) -> bool:
	var transition_started_msec := Time.get_ticks_msec()
	if route.is_empty():
		return false
	var target_scene := scene if scene != null else _activity_routes.get(route) as PackedScene
	if target_scene == null:
		return false
	_activity_routes[route] = target_scene

	if _active_activity != null and is_instance_valid(_active_activity):
		return false

	var activity := _take_cached_activity(route)
	var from_cache := activity != null
	var cache_resolved_msec := Time.get_ticks_msec()
	if activity == null:
		activity = target_scene.instantiate()
	var instantiated_msec := Time.get_ticks_msec()
	_active_activity = activity
	_active_route = route
	_hide_farmyard()
	var farmyard_hidden_msec := Time.get_ticks_msec()
	_activity_container.add_child(activity)
	_set_node_active(activity, true)
	_restore_tree_visibility(activity)
	var tree_restored_msec := Time.get_ticks_msec()
	if activity.has_meta(CHORE_RETURNING_META):
		activity.remove_meta(CHORE_RETURNING_META)
	if activity.has_method("activate_from_cache"):
		activity.call("activate_from_cache")
	var activated_msec := Time.get_ticks_msec()
	if OS.is_debug_build():
		print("[SceneTiming] route=%s cache=%s cache_lookup_ms=%d instantiate_ms=%d hide_farmyard_ms=%d attach_restore_ms=%d activate_ms=%d total_ms=%d" % [
			route,
			from_cache,
			cache_resolved_msec - transition_started_msec,
			instantiated_msec - cache_resolved_msec,
			farmyard_hidden_msec - instantiated_msec,
			tree_restored_msec - farmyard_hidden_msec,
			activated_msec - tree_restored_msec,
			activated_msec - transition_started_msec,
		])
		call_deferred("_report_activity_first_frame", route, transition_started_msec, from_cache)
	return true


func return_to_farmyard() -> bool:
	if _active_activity == null or not is_instance_valid(_active_activity):
		_show_farmyard()
		return false
	var finished_route := _active_route
	var activity := _active_activity
	_active_activity = null
	_active_route = ""
	if activity.has_method("deactivate_for_cache_or_free"):
		activity.call("deactivate_for_cache_or_free")
	_store_activity_in_cache(finished_route, activity)
	_show_farmyard()
	if _farmyard_instance != null and is_instance_valid(_farmyard_instance):
		if _farmyard_instance.has_method("refresh_after_activity_return"):
			_farmyard_instance.call("refresh_after_activity_return")
	return true


func has_active_activity() -> bool:
	return _active_activity != null and is_instance_valid(_active_activity)


func is_activity_warm(route: String) -> bool:
	var cached := _activity_cache.get(route) as Node
	return cached != null and is_instance_valid(cached)


func _prewarm_next_route() -> void:
	_prewarm_route(FarmState.CHORE_MILKING)
	_is_prewarming = false


func _prewarm_route(route: String) -> void:
	if route.is_empty() or _activity_cache.has(route):
		return
	var scene := _activity_routes.get(route) as PackedScene
	if scene == null:
		return
	var prepare_started_msec := Time.get_ticks_msec()
	var activity := scene.instantiate()
	activity.set_meta(CACHE_PREPARE_META, true)
	_set_node_active(activity, false)
	_cache_container.add_child(activity)
	_hide_tree_visuals(activity)
	if activity.has_method("prepare_for_cached_scene"):
		activity.call("prepare_for_cached_scene")
	_activity_cache[route] = activity
	_touch_cached_route(route)
	_enforce_cache_limit()
	if OS.is_debug_build():
		print("[SceneTiming] route=%s prewarm_ms=%d cache_size=%d" % [
			route,
			Time.get_ticks_msec() - prepare_started_msec,
			_activity_cache.size(),
		])


func _store_activity_in_cache(route: String, activity: Node) -> void:
	if route.is_empty() or activity == null or not is_instance_valid(activity):
		if activity != null and is_instance_valid(activity):
			activity.queue_free()
		return
	if _activity_cache.has(route):
		var existing := _activity_cache[route] as Node
		if existing != null and is_instance_valid(existing) and existing != activity:
			existing.queue_free()
	if activity.get_parent() != null:
		activity.get_parent().remove_child(activity)
	activity.set_meta(CACHE_PREPARE_META, true)
	_hide_tree_visuals(activity)
	_set_node_active(activity, false)
	_cache_container.add_child(activity)
	_activity_cache[route] = activity
	_touch_cached_route(route)
	_enforce_cache_limit()


func _take_cached_activity(route: String) -> Node:
	var activity := _activity_cache.get(route) as Node
	if activity == null or not is_instance_valid(activity):
		_activity_cache.erase(route)
		_cache_recency.erase(route)
		return null
	_activity_cache.erase(route)
	_cache_recency.erase(route)
	if activity.get_parent() != null:
		activity.get_parent().remove_child(activity)
	if activity.has_meta(CACHE_PREPARE_META):
		activity.remove_meta(CACHE_PREPARE_META)
	return activity


func _touch_cached_route(route: String) -> void:
	_cache_recency.erase(route)
	_cache_recency.append(route)


func _enforce_cache_limit() -> void:
	while _activity_cache.size() > MAX_ACTIVITY_CACHE_SIZE:
		var route_to_evict := ""
		for cached_route in _cache_recency:
			if cached_route != FarmState.CHORE_MILKING:
				route_to_evict = cached_route
				break
		if route_to_evict.is_empty():
			return
		var cached := _activity_cache.get(route_to_evict) as Node
		_activity_cache.erase(route_to_evict)
		_cache_recency.erase(route_to_evict)
		if cached != null and is_instance_valid(cached):
			if cached.get_parent() != null:
				cached.get_parent().remove_child(cached)
			cached.queue_free()


func _report_activity_first_frame(route: String, transition_started_msec: int, from_cache: bool) -> void:
	await RenderingServer.frame_post_draw
	if OS.is_debug_build():
		print("[SceneTiming] route=%s cache=%s first_frame_ms=%d" % [
			route,
			from_cache,
			Time.get_ticks_msec() - transition_started_msec,
		])


func _show_farmyard() -> void:
	if _farmyard_instance == null or not is_instance_valid(_farmyard_instance):
		return
	move_child(_farmyard_instance, max(0, get_child_count() - 2))
	move_child(_activity_container, get_child_count() - 1)
	_set_node_active(_farmyard_instance, true)
	_restore_tree_visibility(_farmyard_instance)
	MusicManager.play_farmyard_music()


func _hide_farmyard() -> void:
	if _farmyard_instance == null or not is_instance_valid(_farmyard_instance):
		return
	if _farmyard_instance.has_method("prepare_for_activity_launch"):
		_farmyard_instance.call("prepare_for_activity_launch")
	_hide_tree_visuals(_farmyard_instance)
	_set_node_active(_farmyard_instance, false)


func _set_node_active(node: Node, active: bool) -> void:
	if node == null:
		return
	node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	for child in node.get_children():
		_set_node_active(child, active)


func _hide_tree_visuals(node: Node) -> void:
	if node == null:
		return
	if node is CanvasItem:
		var canvas_item := node as CanvasItem
		if not canvas_item.has_meta(SAVED_VISIBLE_META):
			canvas_item.set_meta(SAVED_VISIBLE_META, canvas_item.visible)
		canvas_item.visible = false
	elif node is CanvasLayer:
		var canvas_layer := node as CanvasLayer
		if not canvas_layer.has_meta(SAVED_VISIBLE_META):
			canvas_layer.set_meta(SAVED_VISIBLE_META, canvas_layer.visible)
		canvas_layer.visible = false
	for child in node.get_children():
		_hide_tree_visuals(child)


func _restore_tree_visibility(node: Node) -> void:
	if node == null:
		return
	if node is CanvasItem:
		var canvas_item := node as CanvasItem
		if canvas_item.has_meta(SAVED_VISIBLE_META):
			canvas_item.visible = bool(canvas_item.get_meta(SAVED_VISIBLE_META))
			canvas_item.remove_meta(SAVED_VISIBLE_META)
	elif node is CanvasLayer:
		var canvas_layer := node as CanvasLayer
		if canvas_layer.has_meta(SAVED_VISIBLE_META):
			canvas_layer.visible = bool(canvas_layer.get_meta(SAVED_VISIBLE_META))
			canvas_layer.remove_meta(SAVED_VISIBLE_META)
	for child in node.get_children():
		_restore_tree_visibility(child)
