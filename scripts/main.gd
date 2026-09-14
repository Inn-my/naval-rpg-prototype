extends Node2D

const SLOOP: ShipPreset = preload("res://resources/ship_presets/sloop_small_fast.tres")
const CORVETTE: ShipPreset = preload("res://resources/ship_presets/corvette_medium.tres")
const GALLEON: ShipPreset = preload("res://resources/ship_presets/galleon_heavy_slow.tres")

@onready var ship: Ship = $Ship
@onready var targeting: TargetingSystem = $Ship/TargetingSystem
@onready var info_label: Label = $UI/InfoLabel

func _ready() -> void:
	$UI/PresetBar/SloopButton.pressed.connect(_on_preset_selected.bind(SLOOP))
	$UI/PresetBar/CorvetteButton.pressed.connect(_on_preset_selected.bind(CORVETTE))
	$UI/PresetBar/GalleonButton.pressed.connect(_on_preset_selected.bind(GALLEON))
	$UI/TargetBar/CycleTargetButton.pressed.connect(targeting.cycle_target)
	$UI/TargetBar/ClearTargetButton.pressed.connect(targeting.clear_target)

func _on_preset_selected(preset: ShipPreset) -> void:
	ship.apply_preset(preset)

func _process(_delta: float) -> void:
	if ship.preset == null:
		return
	var heading_error_deg := 0.0
	if SteeringInput.active:
		heading_error_deg = rad_to_deg(angle_difference(ship.rotation, SteeringInput.target_angle))
	var target_text: String = "none"
	if targeting.current_target and is_instance_valid(targeting.current_target):
		target_text = targeting.current_target.name
	info_label.text = "%s\nspeed: %d / %d\nheading err: %.1f deg\ntarget: %s" % [
		ship.preset.preset_name,
		int(ship.linear_velocity.length()),
		int(ship.preset.max_speed),
		heading_error_deg,
		target_text,
	]
