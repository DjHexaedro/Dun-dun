# Bullet that aims at the center of the screen and shoots bullets at it.
extends BaseBullet


const TWEEN_DURATION: int = 2
const N_OF_BULLETS: int = 4
const BURST_DELAY: int = 1
const DEVIATION_MARGIN: int = 1
const SPAWN_BLINK_TIMES: int = 8

onready var blink_timer: Timer = $blink_timer
onready var unblink_timer: Timer = $unblink_timer

var min_proyectile_speed: int = 100
var max_proyectile_speed: int = 200
var keep_shooting: bool = true
var final_position: Vector2
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var delay_between_bursts_timer: Timer = Timer.new()


func _ready() -> void:
	._ready()
	delay_between_bursts_timer.set_one_shot(true)
	delay_between_bursts_timer.set_wait_time(DEVIATION_MARGIN)
	add_child(delay_between_bursts_timer)
	rng.randomize()

func set_properties(params_dict: Dictionary) -> void:
	.set_properties(params_dict)
	EnemyManager.get_enemy().connect("change_boss_phase", self, "unload")

func spawn(params_dict: Dictionary) -> void:
	set_properties(params_dict)
	for _i in range(SPAWN_BLINK_TIMES):
		blink_timer.start()
		yield(blink_timer, "timeout")
		visible = false
		unblink_timer.start()
		yield(unblink_timer, "timeout")
		visible = true
	explode()

func unload() -> void:
	.unload()
	delay_between_bursts_timer.stop()

# Shoot function. Named "explode" because the bullet used to disappear
# after shooting a certain number of bursts
func explode() -> void:
	var bullet_direction: Vector2
	var current_bullet: int = 0
	var angle_to_center: float = (Globals.Positions.SCREEN_CENTER - position).angle()
	var proyectile_speed: int
	var params_dict: Dictionary
	while keep_shooting:
		while current_bullet < N_OF_BULLETS:
			bullet_direction = Vector2(cos(angle_to_center + rng.randf_range(-DEVIATION_MARGIN, DEVIATION_MARGIN)), sin(angle_to_center + rng.randf_range(-DEVIATION_MARGIN, DEVIATION_MARGIN)))
			proyectile_speed = rng.randi_range(min_proyectile_speed, max_proyectile_speed)
			params_dict = {
				"global_position": position,
				"scale": Globals.BulletSizes.STANDARD,
				"velocity": bullet_direction * proyectile_speed,
			}
			SimpleBulletManager.shoot_bullet(Globals.SimpleBulletTypes.STRAIGHT, params_dict)
			current_bullet += 1
		delay_between_bursts_timer.start()
		yield(delay_between_bursts_timer, "timeout")
		current_bullet = 0
	remove_from_active_bullets()
