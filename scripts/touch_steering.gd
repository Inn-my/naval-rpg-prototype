extends Control

## Relative Vector Guidance input zone.
##
## Deliberately NOT a floating joystick: the reference anchor is fixed to a
## constant screen position (bottom-left) instead of spawning wherever the
## finger first lands. The vector from that fixed anchor to the current touch
## position sets the target heading (angle) and throttle (clamped distance).
## Only touches that START in the left half of the screen are captured, so
## the right half stays free for future targeting controls (doc section 3).

const ANCHOR_MARGIN := Vector2(160.0, 140.0)
const MAX_RADIUS := 110.0
const DEADZONE := 14.0

var _anchor_pos: Vector2
var _touch_index: int = -1
var _current_pos: Vector2

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_anchor()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_anchor()

func _update_anchor() -> void:
	var vp: Vector2 = get_viewport_rect().size
	_anchor_pos = Vector2(ANCHOR_MARGIN.x, vp.y - ANCHOR_MARGIN.y)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index == -1 and event.position.x < get_viewport_rect().size.x * 0.5:
				_touch_index = event.index
				_current_pos = event.position
				_apply_input()
				queue_redraw()
		elif event.index == _touch_index:
			_touch_index = -1
			SteeringInput.active = false
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_current_pos = event.position
		_apply_input()
		queue_redraw()

func _apply_input() -> void:
	var offset: Vector2 = _current_pos - _anchor_pos
	var distance: float = offset.length()
	if distance < DEADZONE:
		SteeringInput.active = false
		return
	SteeringInput.active = true
	SteeringInput.target_angle = offset.angle()
	SteeringInput.throttle = clamp((distance - DEADZONE) / (MAX_RADIUS - DEADZONE), 0.0, 1.0)

func _draw() -> void:
	# Fixed reference ring — always in the same place, unlike a floating stick.
	draw_arc(_anchor_pos, MAX_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.25), 2.0)
	draw_circle(_anchor_pos, 5.0, Color(1, 1, 1, 0.6))
	if _touch_index != -1:
		var offset: Vector2 = (_current_pos - _anchor_pos).limit_length(MAX_RADIUS)
		draw_line(_anchor_pos, _anchor_pos + offset, Color(0.3, 1.0, 0.6, 0.9), 4.0)
		draw_circle(_anchor_pos + offset, 10.0, Color(0.3, 1.0, 0.6, 0.9))
