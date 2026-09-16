extends Area2D
class_name Port

## Simple proximity trigger for trading: emits when the player's ship enters
## or leaves range so Main can show/hide the "Trade" prompt. No dock art or
## docking mechanics yet — just a zone the player sails into, mirroring how
## Projectile detects an enemy's HitArea (area_entered + get_parent()).

signal player_entered
signal player_exited

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("player"):
		player_entered.emit()

func _on_area_exited(area: Area2D) -> void:
	if area.get_parent().is_in_group("player"):
		player_exited.emit()
