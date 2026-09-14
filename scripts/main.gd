extends Node2D

const SLOOP: ShipPreset = preload("res://resources/ship_presets/sloop_small_fast.tres")
const CORVETTE: ShipPreset = preload("res://resources/ship_presets/corvette_medium.tres")
const GALLEON: ShipPreset = preload("res://resources/ship_presets/galleon_heavy_slow.tres")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/Projectile.tscn")

const FIRE_COOLDOWN := 1.0

@onready var ship: Ship = $Ship
@onready var targeting: TargetingSystem = $Ship/TargetingSystem
@onready var info_label: Label = $UI/InfoLabel
@onready var fire_button: Button = $UI/TargetBar/FireButton
@onready var player_health_fill: ColorRect = $UI/PlayerHealthBar/Fill
@onready var game_over_overlay: Control = $UI/GameOverOverlay
@onready var restart_button: Button = $UI/GameOverOverlay/RestartButton

var _fire_cooldown_remaining: float = 0.0

func _ready() -> void:
	$UI/PresetBar/SloopButton.pressed.connect(_on_preset_selected.bind(SLOOP))
	$UI/PresetBar/CorvetteButton.pressed.connect(_on_preset_selected.bind(CORVETTE))
	$UI/PresetBar/GalleonButton.pressed.connect(_on_preset_selected.bind(GALLEON))
	$UI/TargetBar/CycleTargetButton.pressed.connect(targeting.cycle_target)
	$UI/TargetBar/ClearTargetButton.pressed.connect(targeting.clear_target)
	fire_button.pressed.connect(_on_fire_pressed)
	ship.died.connect(_on_ship_died)
	restart_button.pressed.connect(_on_restart_pressed)

func _on_preset_selected(preset: ShipPreset) -> void:
	ship.apply_preset(preset)

func _on_ship_died() -> void:
	get_tree().paused = true
	game_over_overlay.visible = true

func _on_restart_pressed() -> void:
	# reload_current_scene() resets the ship to the position baked into
	# Main.tscn. That's a temporary stand-in for a real checkpoint/port
	# system planned later — revisit this once that exists.
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_fire_pressed() -> void:
	if _fire_cooldown_remaining > 0.0:
		return
	var target: Node2D = targeting.current_target
	if target == null or not is_instance_valid(target):
		return
	var projectile: Node2D = PROJECTILE_SCENE.instantiate()
	add_child(projectile)
	projectile.global_position = ship.global_position
	projectile.target = target
	projectile.target_position = target.global_position
	_fire_cooldown_remaining = FIRE_COOLDOWN

func _process(delta: float) -> void:
	if ship.preset == null:
		return
	var heading_error_deg := 0.0
	if SteeringInput.active:
		heading_error_deg = rad_to_deg(angle_difference(ship.rotation, SteeringInput.target_angle))
	var has_target: bool = targeting.current_target != null and is_instance_valid(targeting.current_target)
	var target_text: String = "none"
	if has_target:
		target_text = targeting.current_target.name
	info_label.text = "%s\nspeed: %d / %d\nheading err: %.1f deg\ntarget: %s" % [
		ship.preset.preset_name,
		int(ship.linear_velocity.length()),
		int(ship.preset.max_speed),
		heading_error_deg,
		target_text,
	]

	player_health_fill.scale.x = clamp(ship.health / Ship.MAX_HEALTH, 0.0, 1.0)

	if _fire_cooldown_remaining > 0.0:
		_fire_cooldown_remaining -= delta
	fire_button.disabled = not has_target or _fire_cooldown_remaining > 0.0
