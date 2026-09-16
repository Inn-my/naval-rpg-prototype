extends Node

## Tracks the player's doubloons and cargo hold for the whole play session.
## Autoloaded as a singleton (same pattern as SteeringInput) so any scene —
## the trade UI, any number of ports — can read and spend from it without a
## reference threaded through Main/Ship.

const STARTING_GOLD := 100

var gold: int = STARTING_GOLD
var cargo: Dictionary = {}  # good id (String) -> unit count (int)

func can_afford(price: int) -> bool:
	return gold >= price

func has_cargo(good_id: String) -> bool:
	return cargo.get(good_id, 0) > 0

## Deducts price from gold and adds one unit of good_id to cargo. Returns
## false and does nothing if the player can't afford it, so callers don't
## need to duplicate the affordability check themselves.
func buy(good_id: String, price: int) -> bool:
	if not can_afford(price):
		return false
	gold -= price
	cargo[good_id] = cargo.get(good_id, 0) + 1
	return true

## Removes one unit of good_id from cargo and adds price to gold. Returns
## false and does nothing if the player isn't carrying any of that good.
func sell(good_id: String, price: int) -> bool:
	if not has_cargo(good_id):
		return false
	cargo[good_id] -= 1
	if cargo[good_id] <= 0:
		cargo.erase(good_id)
	gold += price
	return true
