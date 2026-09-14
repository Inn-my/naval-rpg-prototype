extends Node2D
class_name EnemyShip

## Placeholder hostile: drifts slowly in a random direction and bounces back
## once it strays too far from the origin. No AI, no weapons — this exists
## only as a targetable object for the forward-arc scan (doc section 3).

const DRIFT_SPEED_RANGE := Vector2(20.0, 60.0)
const CONTAINMENT_RADIUS := 1400.0

@export var health: float = 100.0

var _velocity: Vector2

func _ready() -> void:
	add_to_group("enemies")
	var speed: float = randf_range(DRIFT_SPEED_RANGE.x, DRIFT_SPEED_RANGE.y)
	_velocity = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * speed
	rotation = _velocity.angle()

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		queue_free()

func _physics_process(delta: float) -> void:
	position += _velocity * delta
	if position.length() > CONTAINMENT_RADIUS:
		_velocity = -position.normalized() * _velocity.length()
		rotation = _velocity.angle()
