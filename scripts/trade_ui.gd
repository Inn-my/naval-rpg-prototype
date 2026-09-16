extends Control
class_name TradeUI

## Trade panel shared by every port: lists the five starting goods, lets the
## player spend gold from PlayerWallet to buy units into cargo or sell
## cargo back for gold, and shows current gold/cargo. Every port currently
## quotes the same prices — per-port pricing (for real buy-low/sell-high
## arbitrage) is a natural next slice, not this one.

const GOODS := [
	{"id": "tobacco", "name": "Tobacco", "unit": "barrel", "buy_price": 5, "sell_price": 14},
	{"id": "sugar", "name": "Sugar", "unit": "barrel", "buy_price": 10, "sell_price": 25},
	{"id": "cloth", "name": "Cloth", "unit": "crate", "buy_price": 3, "sell_price": 6},
	{"id": "tools", "name": "Tools", "unit": "crate", "buy_price": 3, "sell_price": 5},
	{"id": "rum", "name": "Rum", "unit": "barrel", "buy_price": 28, "sell_price": 250},
]

@onready var gold_label: Label = $Panel/VBox/GoldLabel
@onready var cargo_label: Label = $Panel/VBox/CargoLabel
@onready var goods_list: VBoxContainer = $Panel/VBox/GoodsList
@onready var close_button: Button = $Panel/VBox/CloseButton

var _buy_buttons: Dictionary = {}  # good id -> Button
var _sell_buttons: Dictionary = {}  # good id -> Button

func _ready() -> void:
	close_button.pressed.connect(close)
	for good in GOODS:
		_add_good_row(good)
	refresh()

func _add_good_row(good: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var label := Label.new()
	label.text = "%s (%s)" % [good.name, good.unit]
	label.custom_minimum_size = Vector2(200, 0)
	row.add_child(label)

	var buy_button := Button.new()
	buy_button.text = "Buy (%dg)" % good.buy_price
	buy_button.custom_minimum_size = Vector2(110, 0)
	buy_button.pressed.connect(_on_buy_pressed.bind(good))
	row.add_child(buy_button)

	var sell_button := Button.new()
	sell_button.text = "Sell (%dg)" % good.sell_price
	sell_button.custom_minimum_size = Vector2(110, 0)
	sell_button.pressed.connect(_on_sell_pressed.bind(good))
	row.add_child(sell_button)

	goods_list.add_child(row)
	_buy_buttons[good.id] = buy_button
	_sell_buttons[good.id] = sell_button

func _on_buy_pressed(good: Dictionary) -> void:
	if PlayerWallet.buy(good.id, good.buy_price):
		refresh()

func _on_sell_pressed(good: Dictionary) -> void:
	if PlayerWallet.sell(good.id, good.sell_price):
		refresh()

## Marks the player ship invulnerable and makes enemies stop targeting/firing
## at it (see Ship.is_invulnerable and EnemyShip._process_attack) for as long
## as this panel is open — the captain has stepped off the ship to trade and
## shouldn't be attackable mid-transaction. Deliberately doesn't touch
## get_tree().paused: that would also freeze the Game Over flow and could
## mask bugs there, and isn't needed for the save/load system either since
## neither reads/writes on a timer. Restored the instant the panel closes.
func open() -> void:
	visible = true
	_set_player_invulnerable(true)
	refresh()

func close() -> void:
	visible = false
	_set_player_invulnerable(false)

func _set_player_invulnerable(value: bool) -> void:
	var player: Ship = get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player):
		player.is_invulnerable = value

func refresh() -> void:
	gold_label.text = "Gold: %d" % PlayerWallet.gold
	cargo_label.text = "Cargo: %s" % _format_cargo()
	for good in GOODS:
		var buy_button: Button = _buy_buttons[good.id]
		buy_button.disabled = not PlayerWallet.can_afford(good.buy_price)
		var sell_button: Button = _sell_buttons[good.id]
		sell_button.disabled = not PlayerWallet.has_cargo(good.id)

func _format_cargo() -> String:
	var parts: Array = []
	for good in GOODS:
		var count: int = PlayerWallet.cargo.get(good.id, 0)
		if count > 0:
			parts.append("%s x%d" % [good.name, count])
	if parts.is_empty():
		return "(empty)"
	return ", ".join(parts)
