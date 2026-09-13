extends Resource
class_name ShipPreset

## Per-hull tuning data for the Relative Vector Guidance / PID steering model.
## Every field is Inspector-editable so hull feel can be tuned without touching code.

@export var preset_name: String = "Unnamed Hull"

@export_group("Mass & Linear Motion")
@export var mass: float = 100.0
@export var max_thrust: float = 300.0
@export var linear_drag: float = 4.0
@export var max_speed: float = 250.0

@export_group("Angular / PID")
@export var moment_of_inertia: float = 90.0
@export var kp: float = 100.0
@export var ki: float = 0.5
## Damping ratio (zeta). 1.0 = critically damped (no overshoot). >1 = overdamped (extra sluggish, still no overshoot).
@export var damping_ratio: float = 1.0
@export var max_torque: float = 200.0
@export var integral_limit: float = 20.0

@export_group("Visuals")
@export var hull_scale: float = 1.0
@export var hull_color: Color = Color(0.8, 0.7, 0.5)

## Kd derived from Kp, inertia and damping ratio: Kd = 2*zeta*sqrt(Kp*I).
## This is the critical-damping solution for I*theta_dd + Kd*theta_d + Kp*theta = 0,
## so any hull mass gets a matching Kd that will not overshoot the target heading.
func get_kd() -> float:
	return 2.0 * damping_ratio * sqrt(max(kp * moment_of_inertia, 0.0))
