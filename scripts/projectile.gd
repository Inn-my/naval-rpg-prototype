extends Node2D
class_name Projectile

## Simple straight-line "cannon shot": flies from its spawn position toward
## a fixed world-space target position at a constant speed, and deals
## damage on actually touching the target enemy's hit area. Frees itself
## on hit, on reaching the target position without a hit, or after a
## timeout — whichever comes first.

const SPEED := 700.0
const LIFETIME := 3.0
const ARRIVAL_DISTANCE := 10.0
const DEFAULT_DAMAGE := 20.0

var target_position: Vector2
var target: Node2D
var damage: float = DEFAULT_DAMAGE

var _elapsed: float = 0.0

@onready var hit_area: Area2D = $HitArea

func _ready() -> void:
	hit_area.area_entered.connect(_on_hit_area_entered)

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

func _on_hit_area_entered(area: Area2D) -> void:
	var enemy: Node = area.get_parent()
	if enemy != target:
		return
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	queue_free()
