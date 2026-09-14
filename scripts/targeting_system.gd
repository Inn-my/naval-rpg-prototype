extends Node
class_name TargetingSystem

## Forward arc-cone auto-targeting (doc section 3):
##   S = wd*(1 - d/dmax) + wtheta*cos(theta_offset) + wv*Vthreat
##
## cycle_target() rescans the arc each call and steps to the next candidate
## after whichever is currently locked, best-score first. The lock itself
## persists once set (even if the target later drifts outside the arc) —
## only clear_target() or the next cycle moves it. That keeps candidate
## *selection* arc-limited without forcing an unwanted un-lock mid-turn.

signal target_changed(target: Node2D)

@export var arc_half_angle_deg: float = 30.0
@export var max_range: float = 1200.0
@export var weight_distance: float = 0.5
@export var weight_angle: float = 0.4
@export var weight_threat: float = 0.1

const PLACEHOLDER_THREAT := 1.0

var current_target: Node2D = null

@onready var ship: Node2D = get_parent()

func cycle_target() -> void:
	var candidates: Array = _scan_arc()
	if candidates.is_empty():
		return
	var current_index: int = candidates.find(current_target)
	var next_index: int = 0
	if current_index != -1:
		next_index = (current_index + 1) % candidates.size()
	_set_target(candidates[next_index])

func clear_target() -> void:
	_set_target(null)

func _set_target(target: Node2D) -> void:
	if current_target and is_instance_valid(current_target) and current_target.has_node("TargetRing"):
		current_target.get_node("TargetRing").visible = false
	current_target = target
	if current_target and current_target.has_node("TargetRing"):
		current_target.get_node("TargetRing").visible = true
	target_changed.emit(current_target)

## Returns enemies inside the forward arc and within range, best score first.
func _scan_arc() -> Array:
	var arc_half_rad: float = deg_to_rad(arc_half_angle_deg)
	var forward: Vector2 = Vector2.RIGHT.rotated(ship.rotation)
	var scored: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var offset: Vector2 = enemy.global_position - ship.global_position
		var distance: float = offset.length()
		if distance <= 0.0 or distance > max_range:
			continue
		var theta_offset: float = forward.angle_to(offset)
		if absf(theta_offset) > arc_half_rad:
			continue
		var score: float = (
			weight_distance * (1.0 - distance / max_range)
			+ weight_angle * cos(theta_offset)
			+ weight_threat * PLACEHOLDER_THREAT
		)
		scored.append({"node": enemy, "score": score})
	scored.sort_custom(func(a, b): return a["score"] > b["score"])
	var result: Array = []
	for entry in scored:
		result.append(entry["node"])
	return result
