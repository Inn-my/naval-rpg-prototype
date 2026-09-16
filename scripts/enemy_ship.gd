extends Node2D
class_name EnemyShip

## Placeholder hostile: drifts slowly in a random direction and bounces back
## once it strays too far from the origin. No AI, no weapons — this exists
## only as a targetable object for the forward-arc scan (doc section 3).

const DRIFT_SPEED_RANGE := Vector2(20.0, 60.0)
const CONTAINMENT_RADIUS := 1400.0

const HEALTH_COLOR_HIGH := Color(0.2, 0.85, 0.2, 1)
const HEALTH_COLOR_MEDIUM := Color(0.95, 0.85, 0.1, 1)
const HEALTH_COLOR_LOW := Color(0.9, 0.15, 0.15, 1)

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/Projectile.tscn")

## Health, damage, attack timing, and range all live in this shared resource
## so combat can be rebalanced by editing resources/game_balance.tres in the
## Inspector, without touching any scripts.
const BALANCE: GameBalance = preload("res://resources/game_balance.tres")

const DEATH_FLASH_COLOR := Color(1, 1, 1, 1)
const DEATH_FLASH_DURATION := 0.1
const DEATH_FADE_DURATION := 0.45

## Strength tiers enemies can be spawned with. Each tier has its own health,
## attack damage, and hull tint so stronger enemies are visibly tougher.
enum Tier { WEAK, NORMAL, STRONG }

const TIER_HULL_COLOR := {
	Tier.WEAK: Color(0.85, 0.55, 0.5, 1),
	Tier.NORMAL: Color(0.7, 0.2, 0.15, 1),
	Tier.STRONG: Color(0.45, 0.05, 0.05, 1),
}

@export var health: float = BALANCE.enemy_normal_health

var max_health: float = BALANCE.enemy_normal_health
var tier: Tier = Tier.NORMAL
var attack_damage: float = BALANCE.enemy_normal_damage

var _velocity: Vector2
var _attack_cooldown_remaining: float = 0.0
var _dying: bool = false

@onready var hull: Polygon2D = $Hull
@onready var health_bar: Node2D = $HealthBar
@onready var health_bar_fill: Polygon2D = $HealthBar/Fill
@onready var hit_area: Area2D = $HitArea
@onready var death_burst: CPUParticles2D = $DeathBurst

func _ready() -> void:
	add_to_group("enemies")
	var speed: float = randf_range(DRIFT_SPEED_RANGE.x, DRIFT_SPEED_RANGE.y)
	_velocity = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * speed
	rotation = _velocity.angle()
	# Random head start on the attack cooldown so a whole wave doesn't fire
	# its first shots in lockstep the moment the player comes into range.
	_attack_cooldown_remaining = randf_range(0.0, BALANCE.enemy_attack_cooldown_jitter)
	_update_health_bar()

## Applies a strength tier's health, attack damage, and hull tint. Called by
## the spawner right after the enemy is added to the scene; resets health to
## the new tier's max so it always spawns at full health for that tier.
func set_tier(new_tier: Tier) -> void:
	tier = new_tier
	match tier:
		Tier.WEAK:
			max_health = BALANCE.enemy_weak_health
			attack_damage = BALANCE.enemy_weak_damage
		Tier.STRONG:
			max_health = BALANCE.enemy_strong_health
			attack_damage = BALANCE.enemy_strong_damage
		_:
			max_health = BALANCE.enemy_normal_health
			attack_damage = BALANCE.enemy_normal_damage
	health = max_health
	if hull:
		hull.color = TIER_HULL_COLOR[tier]
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
	var fraction: float = clamp(health / max_health, 0.0, 1.0)
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
	var player: Ship = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	# The captain has stepped off the ship to trade — enemies can't target
	# or fire at all while this is set, not just have their shots blocked.
	if player.is_invulnerable:
		return
	if global_position.distance_to(player.global_position) > BALANCE.enemy_attack_range:
		return
	_fire_at(player)
	# Re-roll the jitter each shot so enemies drift out of sync over time
	# rather than just staying offset by their initial head start.
	_attack_cooldown_remaining = BALANCE.enemy_attack_cooldown + randf_range(0.0, BALANCE.enemy_attack_cooldown_jitter)

func _fire_at(target: Node2D) -> void:
	var projectile: Node2D = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.target = target
	projectile.target_position = target.global_position
	projectile.damage = attack_damage
