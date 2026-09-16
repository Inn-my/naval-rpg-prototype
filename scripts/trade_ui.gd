extends Control
class_name TradeUI

## Buy-only trade panel for the single-port slice: lists the five starting
## goods, lets the player spend gold from PlayerWallet to add units to
## cargo, and shows current gold/cargo. No selling and no per-port pricing
## yet — that's a later slice.

const GOODS := [
	{"id": "tobacco", "name": "Tobacco", "unit": "barrel", "price": 5},
	{"id": "sugar", "name": "Sugar", "unit": "barrel", "price": 10},
	{"id": "cloth", "name": "Cloth", "unit": "crate", "price": 3},
	{"id": "tools", "name": "Tools", "unit": "crate", "price": 3},
	{"id": "rum", "name": "Rum", "unit": "barrel", "price": 28},
]

@onready var gold_label: Label = $Panel/VBox/GoldLabel
@onready var cargo_label: Label = $Panel/VBox/CargoLabel
@onready var goods_list: VBoxContainer = $Panel/VBox/GoodsList
@onready var close_button: Button = $Panel/VBox/CloseButton

var _buy_buttons: Dictionary = {}  # good id -> Button

func _ready() -> void:
	close_button.pressed.connect(close)
	for good in GOODS:
		_add_good_row(good)
	refresh()

func _add_good_row(good: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var label := Label.new()
	label.text = "%s (%s) — %d gold" % [good.name, good.unit, good.price]
	label.custom_minimum_size = Vector2(280, 0)
	row.add_child(label)

	var buy_button := Button.new()
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(80, 0)
	buy_button.pressed.connect(_on_buy_pressed.bind(good))
	row.add_child(buy_button)

	goods_list.add_child(row)
	_buy_buttons[good.id] = buy_button

func _on_buy_pressed(good: Dictionary) -> void:
	if PlayerWallet.buy(good.id, good.price):
		refresh()

func open() -> void:
	visible = true
	refresh()

func close() -> void:
	visible = false

func refresh() -> void:
	gold_label.text = "Gold: %d" % PlayerWallet.gold
	cargo_label.text = "Cargo: %s" % _format_cargo()
	for good in GOODS:
		var buy_button: Button = _buy_buttons[good.id]
		buy_button.disabled = not PlayerWallet.can_afford(good.price)

func _format_cargo() -> String:
	var parts: Array = []
	for good in GOODS:
		var count: int = PlayerWallet.cargo.get(good.id, 0)
		if count > 0:
			parts.append("%s x%d" % [good.name, count])
	if parts.is_empty():
		return "(empty)"
	return ", ".join(parts)
