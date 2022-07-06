# Bullet that shoots rings of other bullets.
extends BaseBullet


const DEVIATION: float = 0.2
const ENDING_ANGLE: float = TAU
const NUMBER_OF_LAYERS: int = int(ENDING_ANGLE / DEVIATION)
const TIMER_INCREMENT: float = 0.15
const LIFE_THRESHOLD: int = 750
const SPAWN_BLINK_TIMES: int = 8
const PROYECTILES_PER_EXPLOSION: int = 10
const BLINK_DISABLED_DELAY: float = 1.0

enum Stages {
	INITIAL = 1,
	HARD_BULLETS_INITIAL = 2,
	HARD_BULLETS_ROTATION = 3,
	END = 4,
}

onready var blink_timer: Timer = $blink_timer
onready var unblink_timer: Timer = $unblink_timer

var current_shooting_bullet_type: String
var proyectile_speed: int = 300
var current_stage: int = 1
var keep_shooting: bool = true
var max_bursts: int = 0
var base_burst_delay: float
var base_bullets_per_burst: int
var movement_time: float
var random_proyectile_types_enabled: bool
var delay_between_bursts_timer: Timer = Timer.new()
var enable_blinking: bool = true


func _ready() -> void:
	._ready()
	delay_between_bursts_timer.set_one_shot(true)
	add_child(delay_between_bursts_timer)
	current_shooting_bullet_type = Globals.SimpleBulletTypes.STRAIGHT

func set_properties(params_dict: Dictionary) -> void:
	.set_properties(params_dict)
	delay_between_bursts_timer.set_wait_time(base_burst_delay)
	var enemy_node: BaseEnemy = EnemyManager.get_enemy()
	enemy_node.connect("pulsating_fireball_next_stage", self, "next_stage")
	enemy_node.connect("pulsating_fireball_set_stage", self, "set_stage")
	enemy_node.connect("change_boss_phase", self, "unload")

func spawn(params_dict: Dictionary) -> void:
	set_properties(params_dict)
	if enable_blinking:
		for _i in range(SPAWN_BLINK_TIMES):
			blink_timer.start()
			yield(blink_timer, "timeout")
			visible = false
			unblink_timer.start()
			yield(unblink_timer, "timeout")
			visible = true
	else:
		blink_timer.start(BLINK_DISABLED_DELAY)
		yield(blink_timer, "timeout")
	explode()

func unload() -> void:
	keep_shooting = false
	current_shooting_bullet_type = Globals.SimpleBulletTypes.STRAIGHT
	current_stage = 1 
	enable_blinking = true
	proyectile_speed = 300
	.unload()

# Shoot function. Named "explode" because the bullet used to always disappear
# after shooting a certain number of bullet rings
func explode() -> void:
	var burst_delay: float = base_burst_delay
	var rotation_direction: int = 1
	var current_burst: int = 0
	var params_dict: Dictionary = {
		"global_position": global_position,
		"scale": Globals.BulletSizes.STANDARD,
		"rotation_direction": 1,
		"speed": proyectile_speed,
	}
	while (max_bursts == -1 and keep_shooting) or (max_bursts != -1 and current_burst < max_bursts):
		if random_proyectile_types_enabled:
			current_shooting_bullet_type = [Globals.SimpleBulletTypes.STRAIGHT, Globals.SimpleBulletTypes.CIRCULAR][randi()%2]
		if current_stage == Stages.HARD_BULLETS_ROTATION:
			params_dict["rotation_direction"] = rotation_direction
		params_dict["speed"] = proyectile_speed
		BulletPatternManager.bullet_hell_circle(current_shooting_bullet_type, PROYECTILES_PER_EXPLOSION, [params_dict])
		current_burst += 1
		rotation_direction *= -1
		delay_between_bursts_timer.start()
		yield(delay_between_bursts_timer, "timeout")
		if max_bursts == -1:
			burst_delay = base_burst_delay + TIMER_INCREMENT * (clamp(LIFE_THRESHOLD - EnemyManager.get_enemy_current_damage_taken(), 0, LIFE_THRESHOLD) / LIFE_THRESHOLD)
			delay_between_bursts_timer.set_wait_time(burst_delay)
	remove_from_active_bullets()

func next_stage() -> void:
	set_new_stage(current_stage + 1)

func set_stage(new_stage: int) -> void:
	set_new_stage(new_stage)

func set_new_stage(new_stage: int) -> void:
	current_stage = new_stage
	if new_stage == Stages.HARD_BULLETS_INITIAL:
		current_shooting_bullet_type = Globals.SimpleBulletTypes.CIRCULAR
		proyectile_speed = 150
	elif new_stage == Stages.END:
		keep_shooting = false
