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

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/Projectile.tscn")
const ATTACK_RANGE := 600.0
const ATTACK_COOLDOWN := 2.5

const DEATH_FLASH_COLOR := Color(1, 1, 1, 1)
const DEATH_FLASH_DURATION := 0.1
const DEATH_FADE_DURATION := 0.45

@export var health: float = MAX_HEALTH

var _velocity: Vector2
var _attack_cooldown_remaining: float = 0.0
var _dying: bool = false

@onready var health_bar: Node2D = $HealthBar
@onready var health_bar_fill: Polygon2D = $HealthBar/Fill
@onready var hit_area: Area2D = $HitArea
@onready var death_burst: CPUParticles2D = $DeathBurst

func _ready() -> void:
	add_to_group("enemies")
	var speed: float = randf_range(DRIFT_SPEED_RANGE.x, DRIFT_SPEED_RANGE.y)
	_velocity = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * speed
	rotation = _velocity.angle()
	_update_health_bar()

func take_damage(amount: float) -> void:
	if _dying:
		return
	health -= amount
	_update_health_bar()
	if health <= 0.0:
		_die()

## Plays a quick white flash, then shrinks/fades the ship out, then frees it.
## Hitbox and health bar are disabled immediately so a "dead" enemy can't
## still be damaged or targeted while its death animation plays out.
func _die() -> void:
	_dying = true
	remove_from_group("enemies")
	hit_area.set_deferred("monitorable", false)
	hit_area.set_deferred("monitoring", false)
	health_bar.visible = false

	death_burst.get_parent().remove_child(death_burst)
	get_tree().current_scene.add_child(death_burst)
	death_burst.global_position = global_position
	death_burst.emitting = true
	death_burst.finished.connect(death_burst.queue_free)

	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", DEATH_FLASH_COLOR, DEATH_FLASH_DURATION)
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, DEATH_FADE_DURATION)
	tween.tween_property(self, "modulate:a", 0.0, DEATH_FADE_DURATION)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

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
	if _dying:
		return
	position += _velocity * delta
	if position.length() > CONTAINMENT_RADIUS:
		_velocity = -position.normalized() * _velocity.length()
		rotation = _velocity.angle()
	_process_attack(delta)

func _process_attack(delta: float) -> void:
	if _attack_cooldown_remaining > 0.0:
		_attack_cooldown_remaining -= delta
		return
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	if global_position.distance_to(player.global_position) > ATTACK_RANGE:
		return
	_fire_at(player)
	_attack_cooldown_remaining = ATTACK_COOLDOWN

func _fire_at(target: Node2D) -> void:
	var projectile: Node2D = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.target = target
	projectile.target_position = target.global_position
