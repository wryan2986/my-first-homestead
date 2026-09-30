class_name ChoreRuntime
extends RefCounted


static func configure_assist(assist: RefCounted, chore_id: String) -> void:
	if assist == null:
		return
	assist.call("configure", chore_id, FarmState.get_assist_memory(chore_id))


static func record_failed_attempt(assist: RefCounted, chore_id: String) -> int:
	if assist == null:
		return ChoreAssist.STAGE_NORMAL
	var stage := int(assist.call("record_failed_attempt"))
	save_assist_memory(assist, chore_id)
	return stage


static func record_progress(assist: RefCounted, chore_id: String, hint_prefix: String = "") -> void:
	if assist == null:
		return
	assist.call("record_progress")
	if not hint_prefix.is_empty() and VoiceOverManager != null:
		VoiceOverManager.reset_hints_with_prefix(hint_prefix)
	save_assist_memory(assist, chore_id)


static func mark_assist_action_performed(assist: RefCounted, chore_id: String) -> void:
	if assist == null:
		return
	assist.call("mark_assist_action_performed")
	save_assist_memory(assist, chore_id)


static func show_assist_hint(target: CanvasItem, strong: bool, text: String, prompt_key: String) -> void:
	if target != null:
		FarmFeedback.assist_hint(target, strong)
	if VoiceOverManager != null:
		VoiceOverManager.speak_hint(text, prompt_key)


static func save_assist_memory(assist: RefCounted, chore_id: String) -> void:
	if assist == null or chore_id.is_empty():
		return
	FarmState.save_assist_memory(chore_id, Dictionary(assist.call("get_memory")))
