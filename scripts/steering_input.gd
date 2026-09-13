extends Node

## Autoload singleton bridging TouchSteering (input) and Ship (consumer).
## Holds the current Relative Vector Guidance command: a target heading and a throttle.

var active: bool = false
var target_angle: float = 0.0
var throttle: float = 0.0
