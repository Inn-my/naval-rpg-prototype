extends Node2D

const SLOOP: ShipPreset = preload("res://resources/ship_presets/sloop_small_fast.tres")
const CORVETTE: ShipPreset = preload("res://resources/ship_presets/corvette_medium.tres")
const GALLEON: ShipPreset = preload("res://resources/ship_presets/galleon_heavy_slow.tres")

@onready var ship: Ship = $Ship
@onready var info_label: Label = $UI/InfoLabel

func _ready() -> void:
	$UI/PresetBar/SloopButton.pressed.connect(_on_preset_selected.bind(SLOOP))
	$UI/PresetBar/CorvetteButton.pressed.connect(_on_preset_selected.bind(CORVETTE))
	$UI/PresetBar/GalleonButton.pressed.connect(_on_preset_selected.bind(GALLEON))

func _on_preset_selected(preset: ShipPreset) -> void:
	ship.apply_preset(preset)

func _process(_delta: float) -> void:
	if ship.preset == null:
		return
	var heading_error_deg := 0.0
	if SteeringInput.active:
		heading_error_deg = rad_to_deg(angle_difference(ship.rotation, SteeringInput.target_angle))
	info_label.text = "%s\nspeed: %d / %d\nheading err: %.1f deg" % [
		ship.preset.preset_name,
		int(ship.linear_velocity.length()),
		int(ship.preset.max_speed),
		heading_error_deg,
	]
