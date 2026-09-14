extends Node2D

## Lock-on indicator. Parented to an enemy and toggled visible/hidden by
## TargetingSystem — it never needs to track a position itself.

const RADIUS := 26.0
const RING_COLOR := Color(1.0, 0.85, 0.1, 0.9)

func _process(delta: float) -> void:
	if not visible:
		return
	rotation -= 1.5 * delta
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU * 0.75, 32, RING_COLOR, 3.0)
