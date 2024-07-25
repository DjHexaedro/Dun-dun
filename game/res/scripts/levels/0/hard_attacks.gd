# Attacks used by the hard version of the boss
extends "res://juegodetriangulos/res/scripts/levels/0/normal_attacks.gd"

signal shoot_triple_homing_bullets(current_allowed_positions)

var move_positions_global: Array = []
var last_attack_bullets_list: Array = []

func enemy_died() -> void:
	for bullet_id in last_attack_bullets_list:
		SimpleBulletManager.remove_active_bullet(Globals.SimpleBulletTypes.DELAYED_CIRCULAR, bullet_id)
	.enemy_died()

func _ready() -> void:
	move_positions_global = [
		Vector2(positions_list.global.CENTER_X, positions_list.global.TOP_Y),
		Vector2(positions_list.global.CENTER_X, positions_list.global.BOTTOM_Y),
		Vector2(positions_list.global.LEFT_X, positions_list.global.CENTER_Y),
		Vector2(positions_list.global.RIGHT_X, positions_list.global.CENTER_Y),
	]

func hard_flamethrower(userdata: Dictionary) -> void:
	var current_bullet_number: int = 0
	var bullets_per_burst: int = userdata.BASE_BULLETS_PER_BURST
	var direction: int = 1
	var angle_to_screen_center: float = (positions_list.local.SCREEN_CENTER - position).angle()
	var starting_angle: float = angle_to_screen_center - ((PI / 4) * direction)
	var distance_between_bullets: float = (PI / (bullets_per_burst * 2)) * direction
	var current_deviation_right: float = 0
	var current_deviation_left: float = distance_between_bullets * bullets_per_burst
	var time_between_bullets_timer_modifier: float
	var secondary_attack_userdata: Dictionary = userdata.SECONDARY_ATTACK_PARAMS
	secondary_attack_userdata["time_between_bullets"] =  0.3
	var params_dict: Dictionary = {
		"global_position": global_position,
		"scale": userdata.BASE_BULLET_SIZE,
	}
	while continue_attacking:
		params_dict["velocity"] = userdata.BASE_BULLET_SPEED * Vector2(cos(starting_angle + current_deviation_right), sin(starting_angle + current_deviation_right))
		SimpleBulletManager.shoot_bullet(userdata.BULLET_TYPE, params_dict)
		params_dict["velocity"] = userdata.BASE_BULLET_SPEED * Vector2(cos(starting_angle + current_deviation_left), sin(starting_angle + current_deviation_left))
		SimpleBulletManager.shoot_bullet(userdata.BULLET_TYPE, params_dict)
		current_deviation_right += distance_between_bullets
		current_deviation_left -= distance_between_bullets
		current_bullet_number += 1
		time_between_bullets_timer_modifier = clamp(0.1 * (current_damage_taken / 750.0), 0, 0.1)
		main_attack_timer_start(userdata.BASE_TIME_BETWEEN_BULLETS - time_between_bullets_timer_modifier)
		yield(main_attack_timer, "timeout")
		if current_bullet_number >= bullets_per_burst:
			distance_between_bullets *= -1
			current_bullet_number = 0

func hard_bullet_hell_semicircle(userdata: Dictionary) -> void:
	var change_bullet_direction_timer: Timer = Timer.new()
	change_bullet_direction_timer.set_wait_time(1)
	change_bullet_direction_timer.set_one_shot(true)
	get_tree().get_root().add_child(change_bullet_direction_timer)
	change_bullet_direction_timer.connect("timeout", self, "_on_change_bullet_direction_timer")
	var starting_angle: float = (positions_list.local.SCREEN_CENTER - position).angle() - PI/2
	var allowed_move_positions: Array = move_positions.duplicate()
	var allowed_move_positions_global: Array = move_positions_global.duplicate()
	var next_position: Vector2
	var total_number_of_bullets: int = userdata.BASE_BULLETS_PER_LAYER
	var rotation_direction: int = 1
	var params_dict: Dictionary = {
		"scale": userdata.BASE_BULLET_SIZE,
		"speed": userdata.BASE_BULLET_SPEED,
	}
	var current_attack_id: int = current_attack
	while continue_attacking:
		params_dict["rotation_direction"] = rotation_direction
		params_dict["global_position"] = global_position 
		BulletPatternManager.bullet_hell_semicircle(userdata.BULLET_TYPE, total_number_of_bullets, starting_angle, [params_dict])
		change_bullet_direction_timer.start()
		rotation_direction *= -1
		allowed_move_positions = move_positions.duplicate()
		allowed_move_positions_global = move_positions_global.duplicate()
		allowed_move_positions_global.remove(allowed_move_positions.find(position))
		allowed_move_positions.erase(position)
		next_position = allowed_move_positions[randi()%3]
		emit_signal("shoot_triple_homing_bullets", allowed_move_positions_global)
		move(next_position, 1.25)
		yield(self, "finished_moving")
		starting_angle = (positions_list.local.SCREEN_CENTER - position).angle() - PI/2
		if current_attack_id != current_attack:
			break

func hard_shoot_soft_homing_bullets(userdata: Dictionary) -> void:
	var params_dict: Dictionary = {
		"base_speed": userdata.BASE_SPEED,
		"scale": userdata.SCALE,
		"direction": Vector2(1, 1),
	}
	var allowed_move_positions: Array
	var current_attack_id: int = current_attack 
	while continue_attacking:
		allowed_move_positions = yield(self, "shoot_triple_homing_bullets")
		if current_attack_id != current_attack:
			break
		for move_position in allowed_move_positions:
				params_dict["where_goes"] = "goes_down"
				if move_position.y == positions_list.global.BOTTOM_Y:
					params_dict["where_goes"] = "goes_up"
				elif move_position.x == positions_list.global.LEFT_X:
					params_dict["where_goes"] = "goes_right"
				elif move_position.x == positions_list.global.RIGHT_X:
					params_dict["where_goes"] = "goes_left"
				params_dict["velocity"] = params_dict.base_speed * params_dict.direction
				params_dict["global_position"] = move_position
				SimpleBulletManager.spawn_bullet(userdata.BULLET_TYPE, params_dict)

func hard_three_lane_fireball(userdata: Dictionary) -> void:
	MinionManager.spawn_minion(Globals.MinionTypes.WIDE, userdata.UPPER_MINION_PARAMS)
	MinionManager.spawn_minion(Globals.MinionTypes.WIDE, userdata.LOWER_MINION_PARAMS)

func hard_three_lane_fireball_secondary_attack(userdata: Dictionary) -> void:
	MinionManager.spawn_minion(Globals.MinionTypes.AUTOMATIC, userdata.LEFTER_MINION_PARAMS)
	MinionManager.spawn_minion(Globals.MinionTypes.AUTOMATIC, userdata.RIGHTER_MINION_PARAMS)

func hard_fireball_circle(userdata: Dictionary) -> void:
	var params_dict = {
		"scale": userdata.BASE_BULLET_SIZE,
		"global_position": Vector2(positions_list.global.LEFT_X, positions_list.global.TOP_Y),
	}
	ComplexBulletManager.spawn_bullet(userdata.BULLET_TYPE, params_dict)
	params_dict["global_position"] = Vector2(positions_list.global.RIGHT_X, positions_list.global.TOP_Y)
	ComplexBulletManager.spawn_bullet(userdata.BULLET_TYPE, params_dict)

func hard_fireball_circle_secondary_attack(userdata: Dictionary) -> void:
	var params_dict = {
		"scale": userdata.BASE_BULLET_SIZE,
		"global_position": Vector2(positions_list.global.LEFT_X, positions_list.global.BOTTOM_Y)
	}
	ComplexBulletManager.spawn_bullet(userdata.BULLET_TYPE, params_dict)
	params_dict["global_position"] = Vector2(positions_list.global.RIGHT_X, positions_list.global.BOTTOM_Y)
	ComplexBulletManager.spawn_bullet(userdata.BULLET_TYPE, params_dict)

func hard_constant_fire_circle(userdata: Dictionary) -> void:
	create_hard_constant_fire_circle(userdata)

func create_hard_constant_fire_circle(userdata: Dictionary, notify_arena_center: bool = true) -> void:
	var radius = Vector2(500, 0)
	var arena_center = ArenaManager.get_arena_center()
	var step = 2 * PI / userdata.n_of_bullets 
	var offset = 10
	var new_bullet
	var params_dict = {
		"change_rotation_direction": true,
		"current_deviation": 0,
		"current_rotation_speed": userdata.BASE_BULLET_SPEED * 0.2725,
		"rotation_direction": 1,
		"scale": userdata.BASE_BULLET_SIZE,
		"can_emit_signal": true,
	}
	var bullet_id_list = []
	var rng = randi() % 15
	main_attack_timer.set_wait_time(.075)
	for c in range(userdata.n_of_bullets):
		params_dict["global_position"] = arena_center + radius.rotated(step * c + offset * (rng))
		params_dict["velocity"] = Vector2(cos((arena_center - params_dict.global_position).angle()), sin((arena_center - params_dict.global_position).angle())) * userdata.BASE_BULLET_SPEED
		new_bullet = SimpleBulletManager.get_avaliable_bullet(userdata.BULLET_TYPE, params_dict)
		bullet_id_list.append(new_bullet.get_instance_id())
		main_attack_timer.start()
		yield(main_attack_timer, "timeout")
	for bullet_id in bullet_id_list:
		SimpleBulletManager.shoot_bullet_by_id(bullet_id, userdata.BULLET_TYPE)
	last_attack_bullets_list += bullet_id_list
	bullet_id_list = []

func setup_attack_constants() -> void:
	.setup_attack_constants()
	attack_params["hard_flamethrower"] = {
		BASE_BULLET_SPEED = 300,
		BASE_BULLET_SIZE = Globals.BulletSizes.ONE_AND_A_QUARTER,
		BASE_BULLETS_PER_BURST = 30,
		BASE_TIME_BETWEEN_BULLETS = 0.25,
		BULLET_TYPE = Globals.SimpleBulletTypes.STRAIGHT,
		ENABLE_SECONDARY_ATTACK = 250,
		MOVE_TO = Vector2(positions_list.local.CENTER_X, positions_list.local.TOP_Y),
		SECONDARY_ATTACK = 'fire_rain',
		SECONDARY_ATTACK_PARAMS = {
			BASE_BULLET_SPEED = 325,
			BASE_BULLET_SIZE = Globals.BulletSizes.STANDARD,
			BASE_TIME_BETWEEN_BULLETS = 0.3,
			BULLET_TYPE = Globals.SimpleBulletTypes.STRAIGHT,
		},
		SPAWN_POINTS_TO_DISABLE = {
			"top_left": ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"],
			"top_right": ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"],
		}
	}
	attack_params["hard_bullet_hell_semicircle"] = {
		BASE_BULLETS_PER_LAYER = 21,
		BASE_BULLET_SPEED = 300,
		BASE_BULLET_SIZE = Globals.BulletSizes.STANDARD,
		BASE_TIME_BETWEEN_BULLETS = 2.7,
		BULLET_TYPE = Globals.SimpleBulletTypes.CIRCULAR,
		DELAY = 2,
		ENABLE_SECONDARY_ATTACK = 200,
		MOVE_TO = Vector2(positions_list.local.CENTER_X, positions_list.local.BOTTOM_Y),
		SECONDARY_ATTACK = 'hard_shoot_soft_homing_bullets',
		SPAWN_POINTS_TO_DISABLE = {
			"bottom_left": ["spawn_point2", "spawn_point3"],
			"bottom_right": ["spawn_point2", "spawn_point3"],
			"top_left": ["spawn_point1", "spawn_point4"],
			"top_right": ["spawn_point1", "spawn_point4"],
		},
		SECONDARY_ATTACK_PARAMS = {
			BASE_SPEED = 300,
			SCALE = Globals.BulletSizes.DOUBLE,
			GET_RANDOM_X_POSITION = false,
			BULLET_TYPE = Globals.SimpleBulletTypes.SOFT_HOMING,
		}
	}
	attack_params["hard_three_lane_fireball"] = {
		BULLET_TYPE = Globals.SimpleBulletTypes.STRAIGHT,
		ENABLE_SECONDARY_ATTACK = 350,
		SECONDARY_ATTACK = 'hard_three_lane_fireball_secondary_attack',
		SPAWN_POINTS_TO_DISABLE = {
			"top_left": ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"],
			"top_right": ["spawn_point1", "spawn_point2"],
			"bottom_left": ["spawn_point3", "spawn_point4"],
			"bottom_right": ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"]
		},
		LOWER_MINION_PARAMS = {
			"bullets_per_shot": 5,
			"bullet_scale": Globals.BulletSizes.TRIPLE,
			"bullet_speed": 200,
			"chosen_bullet_direction": "UP",
			"damage_threshold": 500,
			"max_attack_speed": 1.5,
			"min_attack_speed": 1,
			"position": Vector2(positions_list.local.LEFT_X * 0.2, positions_list.local.BOTTOM_Y * 0.9),
		},
		UPPER_MINION_PARAMS = {
			"bullets_per_shot": 5,
			"bullet_scale": Globals.BulletSizes.TRIPLE,
			"bullet_speed": 200,
			"chosen_bullet_direction": "DOWN",
			"damage_threshold": 500,
			"max_attack_speed": 1.5,
			"min_attack_speed": 1,
			"position": Vector2(positions_list.local.RIGHT_X * 0.2, positions_list.local.TOP_Y * 0.9),
		},
		SECONDARY_ATTACK_PARAMS = {
			LEFTER_MINION_PARAMS = {
				"bullet_scale": Globals.BulletSizes.STANDARD,
				"bullet_speed": 200,
				"chosen_bullet_direction": "RIGHT",
				"damage_threshold": 750,
				"max_bullet_speed": 350,
				"min_bullet_speed": 250,
				"position": Vector2(positions_list.local.LEFT_X * 0.6, positions_list.local.BOTTOM_Y * 0.3),
			},
			RIGHTER_MINION_PARAMS = {
				"bullet_scale": Globals.BulletSizes.STANDARD,
				"bullet_speed": 200,
				"chosen_bullet_direction": "LEFT",
				"damage_threshold": 750,
				"max_bullet_speed": 350,
				"min_bullet_speed": 250,
				"position": Vector2(positions_list.local.RIGHT_X * 0.6, positions_list.local.TOP_Y * 0.3),
			}
		},
	}
	attack_params["hard_fireball_circle"] = {
		BASE_BULLET_SIZE = Globals.BulletSizes.QUADRUPLE,
		BULLET_TYPE = Globals.ComplexBulletTypes.RANDOM_PULSATING,
		ENABLE_SECONDARY_ATTACK = 200,
		SECONDARY_ATTACK = 'hard_fireball_circle_secondary_attack',
		SECONDARY_ATTACK_PARAMS = {
			BASE_BULLET_SIZE = Globals.BulletSizes.QUADRUPLE,
			BULLET_TYPE = Globals.ComplexBulletTypes.RANDOM_PULSATING,
		},
		SPAWN_POINTS_TO_DISABLE = {
			"top_left": ["spawn_point3", "spawn_point4"],
			"top_right": ["spawn_point1", "spawn_point2"],
			"bottom_left": ["spawn_point3", "spawn_point4"],
			"bottom_right": ["spawn_point1", "spawn_point2"]
		},
	}
	attack_params["hard_constant_fire_circle"] = {
		BASE_BULLET_SPEED = 175,
		BASE_BULLET_SIZE = Globals.BulletSizes.STANDARD,
		BULLET_TYPE = Globals.SimpleBulletTypes.DELAYED_CIRCULAR,
		DELAY = 1,
		ENABLE_SECONDARY_ATTACK = 250,
		n_of_bullets = 13,
		SPAWN_POINTS_TO_DISABLE = {
			"top_left": ["spawn_point1", "spawn_point2", "spawn_point4"],
			"top_right": ["spawn_point1", "spawn_point3", "spawn_point4"],
			"bottom_left": ["spawn_point1", "spawn_point2", "spawn_point3"],
			"bottom_right": ["spawn_point2", "spawn_point3", "spawn_point4"]
		}
	}

func _on_change_bullet_direction_timer() -> void:
	SimpleBulletManager.change_circular_bullet_rotation_direction()
