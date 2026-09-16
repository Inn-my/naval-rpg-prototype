extends Node2D

const SLOOP: ShipPreset = preload("res://resources/ship_presets/sloop_small_fast.tres")
const CORVETTE: ShipPreset = preload("res://resources/ship_presets/corvette_medium.tres")
const GALLEON: ShipPreset = preload("res://resources/ship_presets/galleon_heavy_slow.tres")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/Projectile.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/Enemy.tscn")

const FIRE_COOLDOWN := 1.0

## Where the save file lives. user:// is Godot's per-user app-data location
## (see the class explanation below for exact OS paths) — the right place
## for save data as opposed to res://, which is the read-only game install.
const SAVE_PATH := "user://savegame.json"

## Same scattered starting positions the original Enemy1-5 nodes used.
const ENEMY_SPAWN_POSITIONS := [
	Vector2(400, -200),
	Vector2(-500, 300),
	Vector2(600, 500),
	Vector2(-700, -400),
	Vector2(200, 700),
]

## Strength tiers a spawned enemy can be assigned, picked with equal
## probability per enemy in _spawn_wave().
const ENEMY_TIERS := [EnemyShip.Tier.WEAK, EnemyShip.Tier.NORMAL, EnemyShip.Tier.STRONG]

@onready var ship: Ship = $Ship
@onready var targeting: TargetingSystem = $Ship/TargetingSystem
@onready var info_label: Label = $UI/InfoLabel
@onready var fire_button: Button = $UI/TargetBar/FireButton
@onready var player_health_fill: ColorRect = $UI/PlayerHealthBar/Fill
@onready var game_over_overlay: Control = $UI/GameOverOverlay
@onready var restart_button: Button = $UI/GameOverOverlay/RestartButton
@onready var wave_respawn_timer: Timer = $WaveRespawnTimer
@onready var trade_prompt_button: Button = $UI/TradePrompt
@onready var trade_ui: TradeUI = $UI/TradeUI
@onready var save_button: Button = $UI/SaveButton

var _fire_cooldown_remaining: float = 0.0
var _enemies_alive: int = 0
## Counts how many ports the ship is currently inside range of. A count
## instead of a bool so two overlapping port ranges (unlikely given their
## spacing, but cheap to handle correctly) can't hide the prompt early.
var _ports_in_range: int = 0

func _ready() -> void:
	_load_game_if_present()
	$UI/PresetBar/SloopButton.pressed.connect(_on_preset_selected.bind(SLOOP))
	$UI/PresetBar/CorvetteButton.pressed.connect(_on_preset_selected.bind(CORVETTE))
	$UI/PresetBar/GalleonButton.pressed.connect(_on_preset_selected.bind(GALLEON))
	$UI/TargetBar/CycleTargetButton.pressed.connect(targeting.cycle_target)
	$UI/TargetBar/ClearTargetButton.pressed.connect(targeting.clear_target)
	fire_button.pressed.connect(_on_fire_pressed)
	ship.died.connect(_on_ship_died)
	restart_button.pressed.connect(_on_restart_pressed)
	wave_respawn_timer.timeout.connect(_spawn_wave)
	for port: Port in get_tree().get_nodes_in_group("ports"):
		port.player_entered.connect(_on_port_range_entered)
		port.player_exited.connect(_on_port_range_exited)
	trade_prompt_button.pressed.connect(_on_trade_pressed)
	save_button.pressed.connect(_save_game)
	_spawn_wave()

## --- Save/load -----------------------------------------------------------
## A plain JSON file in user:// is a deliberately simple stand-in for the
## SQLite-backed persistence layer described in docs/design-blueprint.md
## (section 9) — swap this out for that once the game has enough systems
## (quests, world state, multiple characters, etc.) to need a real database.

func _save_game() -> void:
	var save_data := {
		"gold": PlayerWallet.gold,
		"cargo": PlayerWallet.cargo,
		"ship_health": ship.health,
		"ship_preset": _preset_to_id(ship.preset),
		"ship_position": [ship.position.x, ship.position.y],
		"ship_rotation": ship.rotation,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save file: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(save_data))
	file.close()

func _load_game_if_present() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not read save file: %s" % error_string(FileAccess.get_open_error()))
		return
	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file is corrupt or unreadable; starting fresh instead.")
		return
	var save_data: Dictionary = parsed

	# JSON has no separate int type, so numbers always come back as float —
	# cast explicitly to match the int/float types gold/cargo/health actually use.
	PlayerWallet.gold = int(save_data.get("gold", PlayerWallet.gold))
	var cargo: Variant = save_data.get("cargo", {})
	if typeof(cargo) == TYPE_DICTIONARY:
		var loaded_cargo: Dictionary = {}
		for good_id in cargo:
			loaded_cargo[good_id] = int(cargo[good_id])
		PlayerWallet.cargo = loaded_cargo

	var preset: ShipPreset = _preset_from_id(save_data.get("ship_preset", ""))
	if preset != null:
		# apply_preset() resets rotation (and velocity) to put the ship at
		# rest, so position/rotation must be restored after this call, not
		# before, or they'd just get overwritten back to zero.
		ship.apply_preset(preset)
	ship.health = float(save_data.get("ship_health", ship.health))

	var position_data: Variant = save_data.get("ship_position", null)
	if typeof(position_data) == TYPE_ARRAY and position_data.size() == 2:
		ship.position = Vector2(float(position_data[0]), float(position_data[1]))
	ship.rotation = float(save_data.get("ship_rotation", ship.rotation))

func _preset_to_id(preset: ShipPreset) -> String:
	if preset == SLOOP:
		return "sloop"
	if preset == GALLEON:
		return "galleon"
	return "corvette"

func _preset_from_id(id: String) -> ShipPreset:
	match id:
		"sloop":
			return SLOOP
		"galleon":
			return GALLEON
		"corvette":
			return CORVETTE
		_:
			return null

func _on_port_range_entered() -> void:
	_ports_in_range += 1
	trade_prompt_button.visible = true

## Leaving range of every port also closes the trade panel if it's open —
## buying/selling should only be possible while actually at a port.
func _on_port_range_exited() -> void:
	_ports_in_range = max(_ports_in_range - 1, 0)
	if _ports_in_range == 0:
		trade_prompt_button.visible = false
		trade_ui.close()

func _on_trade_pressed() -> void:
	trade_ui.open()

func _on_preset_selected(preset: ShipPreset) -> void:
	ship.apply_preset(preset)

## Spawns one wave of enemies at the standard scatter positions. Used both
## for the initial wave and every wave after, so there's a single place
## that defines how enemies are placed.
func _spawn_wave() -> void:
	for spawn_position in ENEMY_SPAWN_POSITIONS:
		var enemy: EnemyShip = ENEMY_SCENE.instantiate()
		add_child(enemy)
		enemy.position = spawn_position
		enemy.set_tier(ENEMY_TIERS[randi() % ENEMY_TIERS.size()])
		enemy.tree_exited.connect(_on_enemy_tree_exited)
	_enemies_alive = ENEMY_SPAWN_POSITIONS.size()

func _on_enemy_tree_exited() -> void:
	_enemies_alive -= 1
	if _enemies_alive <= 0:
		wave_respawn_timer.start()

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

	player_health_fill.scale.x = clamp(ship.health / ship.max_health, 0.0, 1.0)

	if _fire_cooldown_remaining > 0.0:
		_fire_cooldown_remaining -= delta
	fire_button.disabled = not has_target or _fire_cooldown_remaining > 0.0
