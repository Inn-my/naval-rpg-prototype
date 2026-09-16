extends Node

## Tracks the player's doubloons and cargo hold for the whole play session.
## Autoloaded as a singleton (same pattern as SteeringInput) so any scene —
## the trade UI now, a sell screen or second port later — can read and
## spend from it without a reference threaded through Main/Ship.

const STARTING_GOLD := 100

var gold: int = STARTING_GOLD
var cargo: Dictionary = {}  # good id (String) -> unit count (int)

func can_afford(price: int) -> bool:
	return gold >= price

## Deducts price from gold and adds one unit of good_id to cargo. Returns
## false and does nothing if the player can't afford it, so callers don't
## need to duplicate the affordability check themselves.
func buy(good_id: String, price: int) -> bool:
	if not can_afford(price):
		return false
	gold -= price
	cargo[good_id] = cargo.get(good_id, 0) + 1
	return true
