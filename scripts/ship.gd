extends Node2D
class_name Ship

## Drives a hull using Relative Vector Guidance input (SteeringInput) and a
## PID angular controller (doc section 3): tau = Kp*theta_e + Ki*int(theta_e) + Kd*theta_e_dot
##
## Implemented as a plain Node2D with hand-integrated velocities rather than a
## RigidBody2D: Phase 1 has no collisions yet, and manual integration keeps
## the PID math fully transparent and independent of the physics engine's
## own damping/inertia handling.

signal died

const BALANCE: GameBalance = preload("res://resources/game_balance.tres")

@export var preset: ShipPreset
@export var health: float = BALANCE.player_max_health

var max_health: float = BALANCE.player_max_health

var linear_velocity: Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0

var _angle_error_integral: float = 0.0

@onready var hull: Polygon2D = $Hull

func _ready() -> void:
	add_to_group("player")
	apply_preset(preset)

func take_damage(amount: float) -> void:
	var was_alive: bool = health > 0.0
	health -= amount
	if was_alive and health <= 0.0:
		print("Player ship destroyed!")
		died.emit()

## Swaps the active hull preset for live feel comparison. Keeps world
## position but resets heading/velocity so each hull starts from rest.
func apply_preset(new_preset: ShipPreset) -> void:
	preset = new_preset
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	_angle_error_integral = 0.0
	rotation = 0.0
	if hull and preset:
		hull.color = preset.hull_color
		hull.scale = Vector2.ONE * preset.hull_scale

func _physics_process(delta: float) -> void:
	if preset == null:
		return
	_update_angular(delta)
	_update_linear(delta)

func _update_angular(delta: float) -> void:
	var target_angle: float = rotation
	if SteeringInput.active:
		target_angle = SteeringInput.target_angle

	var theta_e: float = angle_difference(rotation, target_angle)

	_angle_error_integral = clamp(
		_angle_error_integral + theta_e * delta,
		-preset.integral_limit,
		preset.integral_limit
	)

	# Derivative-on-measurement: theta_e_dot ~= -angular_velocity when the
	# target is roughly steady relative to a physics tick. This avoids
	# "derivative kick" from noisy/instant setpoint jumps as the finger drags.
	var kd: float = preset.get_kd()
	var torque: float = preset.kp * theta_e + preset.ki * _angle_error_integral + kd * (-angular_velocity)
	torque = clamp(torque, -preset.max_torque, preset.max_torque)

	var angular_acceleration: float = torque / preset.moment_of_inertia
	angular_velocity += angular_acceleration * delta
	rotation += angular_velocity * delta

func _update_linear(delta: float) -> void:
	var throttle: float = SteeringInput.throttle if SteeringInput.active else 0.0
	var forward: Vector2 = Vector2.RIGHT.rotated(rotation)
	var thrust_force: Vector2 = forward * preset.max_thrust * throttle
	var drag_force: Vector2 = -linear_velocity * preset.linear_drag

	var acceleration: Vector2 = (thrust_force + drag_force) / preset.mass
	linear_velocity += acceleration * delta
	if linear_velocity.length() > preset.max_speed:
		linear_velocity = linear_velocity.normalized() * preset.max_speed

	position += linear_velocity * delta
