class_name SceneEntranceMotion
extends RefCounted


static func tween_keyframes(
	node: Node2D,
	positions: Array,
	durations: Array,
	rotations: Array = [],
	scales: Array = []
):
	if node == null or not is_instance_valid(node):
		return null
	if positions.size() < 2 or durations.size() < positions.size() - 1:
		return null

	var tween = node.create_tween()
	for index in range(1, positions.size()):
		var segment_duration := float(durations[index - 1])
		tween.tween_property(node, "position", positions[index], segment_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if rotations.size() > index:
			tween.parallel().tween_property(node, "rotation_degrees", float(rotations[index]), segment_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if scales.size() > index:
			tween.parallel().tween_property(node, "scale", scales[index], segment_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return tween
