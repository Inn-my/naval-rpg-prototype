extends Resource
class_name GameBalance

## Central combat tuning knobs. Edit resources/game_balance.tres in the
## Godot Inspector to rebalance the game — no script changes needed.

@export_group("Player")
@export var player_max_health: float = 250.0

@export_group("Enemy Health")
@export var enemy_weak_health: float = 60.0
@export var enemy_normal_health: float = 100.0
@export var enemy_strong_health: float = 150.0

@export_group("Enemy Damage")
@export var enemy_weak_damage: float = 10.0
@export var enemy_normal_damage: float = 20.0
@export var enemy_strong_damage: float = 30.0

@export_group("Enemy Attack Timing")
## Base seconds between shots for a single enemy.
@export var enemy_attack_cooldown: float = 4.5
## Random extra (0..jitter) added on top of the base cooldown after every
## shot, and used to give each enemy's first shot a random head start too.
## This is what keeps a pack of enemies from all firing on the player at
## the same instant instead of stacking their damage.
@export var enemy_attack_cooldown_jitter: float = 2.0
@export var enemy_attack_range: float = 600.0
