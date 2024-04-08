# Bullet that heals the player when it hits them.
extends AnimatedSprite

# This bullet is an AnimatedSprite with an AnimatedSprite child because
# the SimpleBulletManager script looks for AnimatedSprite when creating
# bullets, and I need the scale of the graphics to change without changing
# the actual hitbox of the proyectile.
onready var graphics: AnimatedSprite = $graphics

var scale_increment: Vector2 = Vector2(-0.25, -0.25)
var change_scale_timer: Timer = Timer.new()

func _ready():
	change_scale_timer.set_one_shot(false)
	change_scale_timer.set_wait_time(0.5)
	change_scale_timer.connect("timeout", self, "_on_health_refill_change_scale_timer_timeout")
	add_child(change_scale_timer)
	change_scale_timer.start()

func _on_health_refill_change_scale_timer_timeout() -> void:
	graphics.scale += scale_increment 
	scale_increment *= -1
