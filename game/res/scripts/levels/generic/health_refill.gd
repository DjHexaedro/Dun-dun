extends AnimatedSprite


signal player_healed

const POSITION_OFFSET: Vector2 = Vector2(0, -50)
const MAX_TIMES_BLINKED: int = 14
const BLINK_TIME: float = 12.0
const UNBLINK_TIME: float = 3.0

var spawned: bool = false
var blink: bool = false
var move: bool = false
var waited_time: float = 0.0
var times_blinked: int = 0
var speed: int = 100

func spawn() -> void:
	position = POSITION_OFFSET
	blink = true

func _process(delta: float) -> void:
	if blink:
		if waited_time < [BLINK_TIME, UNBLINK_TIME][times_blinked % 2]:
			waited_time += 100 * delta
		else:
			visible = not visible
			waited_time = 0.0
			times_blinked += 1
		if times_blinked >= MAX_TIMES_BLINKED:
			blink = false
			visible = true
			move = true
	if move:
		global_position.y += speed * delta
		if get_parent().get_global_position().y <= get_global_position().y:
			emit_signal("player_healed")
			queue_free()
