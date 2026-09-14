extends Node2D
class_name EnemyShip

## Placeholder hostile: drifts slowly in a random direction and bounces back
## once it strays too far from the origin. No AI, no weapons — this exists
## only as a targetable object for the forward-arc scan (doc section 3).

const DRIFT_SPEED_RANGE := Vector2(20.0, 60.0)
const CONTAINMENT_RADIUS := 1400.0
const MAX_HEALTH := 100.0

const HEALTH_COLOR_HIGH := Color(0.2, 0.85, 0.2, 1)
const HEALTH_COLOR_MEDIUM := Color(0.95, 0.85, 0.1, 1)
const HEALTH_COLOR_LOW := Color(0.9, 0.15, 0.15, 1)

@export var health: float = MAX_HEALTH

var _velocity: Vector2

@onready var health_bar_fill: Polygon2D = $HealthBar/Fill

func _ready() -> void:
	add_to_group("enemies")
	var speed: float = randf_range(DRIFT_SPEED_RANGE.x, DRIFT_SPEED_RANGE.y)
	_velocity = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * speed
	rotation = _velocity.angle()
	_update_health_bar()

func take_damage(amount: float) -> void:
	health -= amount
	_update_health_bar()
	if health <= 0.0:
		queue_free()

func _update_health_bar() -> void:
	var fraction: float = clamp(health / MAX_HEALTH, 0.0, 1.0)
	health_bar_fill.scale.x = fraction
	if fraction > 0.5:
		health_bar_fill.color = HEALTH_COLOR_HIGH
	elif fraction > 0.2:
		health_bar_fill.color = HEALTH_COLOR_MEDIUM
	else:
		health_bar_fill.color = HEALTH_COLOR_LOW

func _physics_process(delta: float) -> void:
	position += _velocity * delta
	if position.length() > CONTAINMENT_RADIUS:
		_velocity = -position.normalized() * _velocity.length()
		rotation = _velocity.angle()
