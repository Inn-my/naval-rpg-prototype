extends Node2D
class_name Projectile

## Simple straight-line "cannon shot": flies from its spawn position toward
## a fixed world-space target position at a constant speed, then frees
## itself on arrival or after a timeout — whichever comes first. Purely
## visual for now; no collision or damage.

const SPEED := 700.0
const LIFETIME := 3.0
const ARRIVAL_DISTANCE := 10.0

var target_position: Vector2

var _elapsed: float = 0.0

func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= LIFETIME:
		queue_free()
		return
	var to_target: Vector2 = target_position - global_position
	if to_target.length() <= ARRIVAL_DISTANCE:
		queue_free()
		return
	global_position += to_target.normalized() * SPEED * delta
