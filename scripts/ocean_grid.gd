extends Node2D

## Static reference grid so heading/drift are visible against something.
## Drawn once; never invalidated, so it costs nothing after the first frame.

const CELL := 128.0
const EXTENT := 4000.0
const LINE_COLOR := Color(1, 1, 1, 0.06)

func _ready() -> void:
	z_index = -10

func _draw() -> void:
	var i := -EXTENT
	while i <= EXTENT:
		draw_line(Vector2(i, -EXTENT), Vector2(i, EXTENT), LINE_COLOR, 1.0)
		draw_line(Vector2(-EXTENT, i), Vector2(EXTENT, i), LINE_COLOR, 1.0)
		i += CELL
