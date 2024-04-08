# Bullet that aims at the player and shoots other bullets at them.
extends BaseBullet


const POSIBLE_DEVIATION: Array = [0, 20]
const RNG_DEVIATION: float = 0.75
const SPAWN_BLINK_TIMES: int = 8
const BASE_BURST_DELAY: float = 0.3

onready var blink_timer: Timer = $blink_timer
onready var unblink_timer: Timer = $unblink_timer

var current_bullet_type: String
var min_proyectile_speed: int = 100
var max_proyectile_speed: int = 200
var current_stage: int = 1
var keep_shooting: bool = true
var multiple_bullet_types_enabled: bool = false 
var can_move: bool = false 
var can_move_y: bool = true
var can_move_x: bool = false 
var n_of_bullets: int = 5
var speed: Vector2 = Vector2(100, 100)
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var final_position: Vector2
var only_vertical_movement: bool = false
var movement_direction: int = 1
var delay_between_bursts_timer: Timer = Timer.new()
var actual_burst_delay: float = BASE_BURST_DELAY
var arena_global_position: Vector2
var top_y: int
var bottom_y: int
var right_x: int
var left_x: int

func _ready() -> void:
	rng.randomize()
	current_bullet_type = Globals.SimpleBulletTypes.STRAIGHT
	delay_between_bursts_timer.set_one_shot(true)
	add_child(delay_between_bursts_timer)
	arena_global_position = ArenaManager.get_current_location().get_global_position()
	top_y = arena_global_position.y + Globals.Positions.TOP_Y
	bottom_y = arena_global_position.y + Globals.Positions.BOTTOM_Y
	right_x = arena_global_position.x + Globals.Positions.RIGHT_X
	left_x = arena_global_position.x + Globals.Positions.LEFT_X

func _process(delta: float) -> void:
	if can_move:
		# This movement logic moves the bullet either up and down
		# or in a rectangular pattern
		if can_move_y:
			if only_vertical_movement:
				position.y += speed.y * delta * movement_direction
				if position.y <= top_y:
					position.y = top_y
					movement_direction *= -1
				elif position.y >= bottom_y:
					position.y = bottom_y
					movement_direction *= -1
			else:
				position.y += speed.y * delta * (1 if position.x == right_x else -1)
				if position.y <= top_y:
					position.y = top_y
					can_move_y = false
					can_move_x = true
				elif position.y >= bottom_y:
					position.y = bottom_y
					can_move_y = false
					can_move_x = true
		elif can_move_x:
			position.x += speed.x * delta * (1 if position.y == top_y else -1)
			if position.x <= left_x:
				position.x = left_x
				can_move_y = true 
				can_move_x = false 
			elif position.x >= right_x:
				position.x = right_x
				can_move_y = true 
				can_move_x = false 

func unload() -> void:
	.unload()
	can_move = false
	keep_shooting = false
	current_stage = 1
	multiple_bullet_types_enabled = false
	can_move_y = true 
	actual_burst_delay = BASE_BURST_DELAY
	current_bullet_type = Globals.SimpleBulletTypes.STRAIGHT
	delay_between_bursts_timer.stop()

func spawn(params_dict: Dictionary) -> void:
	set_properties(params_dict)
	for _i in range(SPAWN_BLINK_TIMES):
		blink_timer.start()
		yield(blink_timer, "timeout")
		visible = false
		unblink_timer.start()
		yield(unblink_timer, "timeout")
		visible = true
	EnemyManager.get_enemy().connect("enable_aimed_pulsating_bullet_movement", self, "enable_movement")
	EnemyManager.get_enemy().connect("enable_aimed_pulsating_bullet_multiple_bullet_types", self, "enable_multiple_bullet_types")
	EnemyManager.get_enemy().connect("unload_aimed_pulsating_bullets", self, "remove_from_active_bullets")
	delay_between_bursts_timer.connect("timeout", self, "explode")
	keep_shooting = true
	delay_between_bursts_timer.set_wait_time(actual_burst_delay)
	explode()

# Shoot function. Named "explode" because the bullet used to disappear
# after shooting
func explode() -> void:
	var bullet_direction: Vector2
	var current_bullet: int = 0
	var base_angle_to_screen_center: float = (arena_global_position - position).angle()
	var angle_to_screen_center: float
	var proyectile_speed: int
	var zero_or_one: int
	var rng_deviation: float
	var params_dict: Dictionary
	while current_bullet < n_of_bullets:
		angle_to_screen_center = base_angle_to_screen_center
		if multiple_bullet_types_enabled:
			zero_or_one = randi()%2
			current_bullet_type = [Globals.SimpleBulletTypes.STRAIGHT, Globals.SimpleBulletTypes.CIRCULAR][zero_or_one]
			angle_to_screen_center -= POSIBLE_DEVIATION[zero_or_one]
		rng_deviation = rng.randf_range(-RNG_DEVIATION, RNG_DEVIATION)
		bullet_direction = Vector2(cos(angle_to_screen_center + rng_deviation), sin(angle_to_screen_center + rng_deviation))
		proyectile_speed = rng.randi_range(min_proyectile_speed, max_proyectile_speed)
		params_dict = {
			"global_position": position,
			"scale": Globals.BulletSizes.STANDARD,
			"velocity": proyectile_speed * bullet_direction,
			"rotation_direction": 1,
		}
		SimpleBulletManager.shoot_bullet(current_bullet_type, params_dict)
		current_bullet += 1
	delay_between_bursts_timer.start()

func enable_movement(enable_horizontal_movement: bool = true) -> void:
	if keep_shooting:
		can_move = true
		only_vertical_movement = not enable_horizontal_movement

func enable_multiple_bullet_types() -> void:
	multiple_bullet_types_enabled = true
