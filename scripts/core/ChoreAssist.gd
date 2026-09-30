class_name ChoreAssist
extends RefCounted

const STAGE_NORMAL := 0
const STAGE_GENTLE_HINT := 1
const STAGE_STRONG_HINT := 2
const STAGE_ASSIST_ACTION := 3

var chore_id := ""
var failed_attempts := 0
var gentle_hint_failed_taps := 6
var gentle_hint_seconds := 11.0
var strong_hint_failed_taps := 10
var strong_hint_seconds := 25.0
var assist_action_failed_taps := 12
var assist_action_seconds := 43.0
var assist_action_cooldown_seconds := 2.0
var hint_repeat_seconds := 15.0

var _started_msec := 0
var _last_progress_msec := 0
var _last_assist_msec := -1000000
var _last_hint_msec := -1000000
var _last_hint_stage := STAGE_NORMAL


func configure(new_chore_id: String = "", memory: Dictionary = {}) -> void:
	chore_id = new_chore_id
	_started_msec = Time.get_ticks_msec()
	_last_progress_msec = _started_msec
	_last_assist_msec = -1000000
	_last_hint_msec = -1000000
	_last_hint_stage = STAGE_NORMAL

	var remembered_failures := int(memory.get("failed_attempts", 0))
	failed_attempts = clampi(int(floor(float(remembered_failures) * 0.5)), 0, gentle_hint_failed_taps - 1)


func record_failed_attempt(weight: int = 1) -> int:
	failed_attempts += max(1, weight)
	return get_stage()


func record_progress() -> void:
	failed_attempts = max(0, int(floor(float(failed_attempts) * 0.35)))
	_last_progress_msec = Time.get_ticks_msec()
	_last_hint_stage = STAGE_NORMAL


func get_stage() -> int:
	var since_progress_seconds := _seconds_since(_last_progress_msec)
	var since_started_seconds := _seconds_since(_started_msec)
	if failed_attempts >= assist_action_failed_taps and since_started_seconds >= assist_action_seconds:
		return STAGE_ASSIST_ACTION
	if failed_attempts >= strong_hint_failed_taps or since_progress_seconds >= strong_hint_seconds:
		return STAGE_STRONG_HINT
	if failed_attempts >= gentle_hint_failed_taps or since_progress_seconds >= gentle_hint_seconds:
		return STAGE_GENTLE_HINT
	return STAGE_NORMAL


func should_show_hint() -> bool:
	var stage := get_stage()
	if stage < STAGE_GENTLE_HINT:
		return false

	var now := Time.get_ticks_msec()
	if stage > _last_hint_stage or _seconds_between(_last_hint_msec, now) >= hint_repeat_seconds:
		_last_hint_stage = stage
		_last_hint_msec = now
		return true
	return false


func can_perform_assist_action() -> bool:
	return get_stage() >= STAGE_ASSIST_ACTION and _seconds_since(_last_assist_msec) >= assist_action_cooldown_seconds


func mark_assist_action_performed() -> void:
	_last_assist_msec = Time.get_ticks_msec()


func get_memory() -> Dictionary:
	return {
		"failed_attempts": failed_attempts,
	}


func is_active() -> bool:
	return get_stage() >= STAGE_GENTLE_HINT


func _seconds_since(msec: int) -> float:
	return _seconds_between(msec, Time.get_ticks_msec())


func _seconds_between(start_msec: int, end_msec: int) -> float:
	return float(end_msec - start_msec) / 1000.0
