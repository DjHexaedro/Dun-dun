# Class to manage the normal attacks of Ongard
extends "res://juegodetriangulos/res/scripts/levels/0/base.gd"

var delayed_bullet_id_list: Array = []
var next_wave: bool = false

# These bullets are not actually marked as active when they spawn, so in case
# they spawn and the enemy dies they must be manually removed
func enemy_died() -> void:
	for bullet_id in delayed_bullet_id_list:
		SimpleBulletManager.remove_active_bullet(Globals.SimpleBulletTypes.DELAYED, bullet_id)
	.enemy_died()

func flamethrower(userdata: Dictionary) -> void:
	var current_bullet_number: int = 0
	var bullets_per_burst: int = userdata.BASE_BULLETS_PER_BURST
	var direction: Vector2
	var starting_angle: float = angle_to_screen_center - (PI / 4)
	var distance_between_bullets: float = (PI / (bullets_per_burst * 2))
	var current_deviation: float = 0
	var time_between_bullets_timer_modifier: float
	var params_dict: Dictionary = {
		"global_position": global_position,
		"scale": userdata.BASE_BULLET_SIZE,
	}
	while continue_attacking:
		direction = Vector2(cos(starting_angle + current_deviation), sin(starting_angle + current_deviation))
		params_dict["velocity"] = direction * userdata.BASE_BULLET_SPEED
		SimpleBulletManager.shoot_bullet(userdata.BULLET_TYPE, params_dict)
		current_deviation += distance_between_bullets
		current_bullet_number += 1
		time_between_bullets_timer_modifier = clamp(0.1 * (current_damage_taken / 750), 0, 0.1)
		main_attack_timer_start(userdata.BASE_TIME_BETWEEN_BULLETS - time_between_bullets_timer_modifier)
		yield(main_attack_timer, "timeout")
		if current_bullet_number >= bullets_per_burst:
			distance_between_bullets *= -1
			current_bullet_number = 0

func fire_rain(userdata: Dictionary) -> void:
	var deviation: float
	var direction: Vector2
	var bullet_speed: int
	var time_between_bullets: float = userdata.get('BASE_TIME_BETWEEN_BULLETS', 0.1)
	var time_between_bullets_timer_modifier: float
	var params_dict: Dictionary = {
		"global_position": global_position,
		"scale": userdata.BASE_BULLET_SIZE,
	}
	var parent_attack_id: int = current_attack
	while continue_attacking:
		bullet_speed = userdata.BASE_BULLET_SPEED + (randi()%100 - 50)
		deviation = randf() * (PI/2) - (PI/4)
		direction = Vector2(cos(angle_to_screen_center + deviation), sin(angle_to_screen_center + deviation))
		params_dict["velocity"] = direction * bullet_speed
		SimpleBulletManager.shoot_bullet(userdata.BULLET_TYPE, params_dict)
		time_between_bullets_timer_modifier = clamp(0.25 * (current_damage_taken/1000), 0, 0.25)
		secondary_attack_timer_start(time_between_bullets - time_between_bullets_timer_modifier)
		yield(secondary_attack_timer, "timeout")
		if parent_attack_id != current_attack:
			break

func bullet_hell_semicircle(userdata: Dictionary) -> void:
	Settings.increase_game_statistic("ongard_normal_times_reached_second_phase", 1)
	var starting_angle: float = (positions_list.local.SCREEN_CENTER - position).angle() - PI/2
	var total_number_of_bullets: int = userdata.BASE_BULLETS_PER_LAYER
	var time_between_bullets_timer_modifier: float
	var rotation_direction: int = 1
	var params_dict: Dictionary = {
		"global_position": global_position,
		"scale": userdata.BASE_BULLET_SIZE,
		"speed": userdata.BASE_BULLET_SPEED,
	}
	var current_attack_id: int = current_attack
	while continue_attacking:
		params_dict["rotation_direction"] = rotation_direction
		BulletPatternManager.bullet_hell_semicircle(userdata.BULLET_TYPE, total_number_of_bullets, starting_angle, [params_dict])
		rotation_direction *= -1
		time_between_bullets_timer_modifier = clamp(0.3 * (current_damage_taken / 750), 0, 0.3)
		main_attack_timer_start(userdata.BASE_TIME_BETWEEN_BULLETS - time_between_bullets_timer_modifier)
		yield(main_attack_timer, "timeout")
		if current_attack_id != current_attack:
			break

func shoot_soft_homing_bullet(userdata: Dictionary) -> void:
	var new_x_position: int = global_position.x
	var new_y_position: int = global_position.y
	var params_dict: Dictionary = {
		"global_position": global_position,
		"base_speed": userdata.BULLET_SPEED,
		"owner_data": ArenaManager.get_current_location(),
		"scale": userdata.BULLET_SIZE,
		"damage": 1,
		"where_goes": "goes_up" if position.y == positions_list.local.BOTTOM_Y else "goes_down",
		"direction": userdata.BULLET_DIRECTION,
	}
	var get_random_x_position: bool = userdata.get("GET_RANDOM_X_POSITION", true)
	var parent_attack_id: int = current_attack
	var n_of_players: int = PlayerManager.get_number_of_players()
	var chosen_player_id: int
	while continue_attacking:
		if get_random_x_position:
			chosen_player_id = randi()%n_of_players
			new_x_position = rng.randi_range(
				PlayerManager.get_player_position(chosen_player_id).x - userdata.SPAWN_POSITION_MARGIN_X,
				PlayerManager.get_player_position(chosen_player_id).x + userdata.SPAWN_POSITION_MARGIN_X
			)
		if hardest_mode_current_attack_stage > 15:
			new_y_position = [positions_list.global.BOTTOM_Y, positions_list.global.TOP_Y][randi()%2]
			params_dict.where_goes = "goes_up" if new_y_position == positions_list.global.BOTTOM_Y else "goes_down"
		params_dict["global_position"] = Vector2(new_x_position, new_y_position)
		params_dict["velocity"] = params_dict.base_speed * params_dict.direction
		SimpleBulletManager.spawn_bullet(userdata.BULLET_TYPE, params_dict)
		secondary_attack_timer_start(userdata.BASE_TIME_BETWEEN_BULLETS)
		yield(secondary_attack_timer, "timeout")
		if parent_attack_id != current_attack:
			break

func three_lane_fireball(userdata: Dictionary) -> void:
	Settings.increase_game_statistic("ongard_normal_times_reached_third_phase", 1)
	MinionManager.spawn_minion(Globals.MinionTypes.WIDE, userdata.UPPER_MINION_PARAMS)
	MinionManager.spawn_minion(Globals.MinionTypes.WIDE, userdata.LOWER_MINION_PARAMS)
	rng.randomize()

func three_lane_fireball_secondary_attack(userdata: Dictionary):
	var parent_attack: String = chosen_attack
	var params_dict: Dictionary = {
		"scale": userdata.BASE_BULLET_SIZE,
		"speed": userdata.BASE_BULLET_SPEED,
	}
	var next_position_x: int = [rng.randi_range((Globals.SCREEN_SIZE.x / 2) * 0.9, (Globals.SCREEN_SIZE.x / 2) * 0.6), rng.randi_range(-(Globals.SCREEN_SIZE.x / 2) * 0.9, -(Globals.SCREEN_SIZE.x / 2) * 0.6)][randi()%2]
	var next_position_y: int = [rng.randi_range((Globals.SCREEN_SIZE.y / 2) * 0.9, (Globals.SCREEN_SIZE.y / 2) * 0.6), rng.randi_range(-(Globals.SCREEN_SIZE.y / 2) * 0.9, -(Globals.SCREEN_SIZE.y / 2) * 0.6)][randi()%2]
	while continue_attacking:
		params_dict["global_position"] = global_position
		BulletPatternManager.bullet_hell_circle(userdata.BULLET_TYPE, 10, [params_dict])
		move(Vector2(next_position_x, next_position_y), 2.5)
		yield(self, "finished_moving")
		next_position_x = [rng.randi_range((Globals.SCREEN_SIZE.x / 2) * 0.9, (Globals.SCREEN_SIZE.x / 2) * 0.6), rng.randi_range(-(Globals.SCREEN_SIZE.x / 2) * 0.9, -(Globals.SCREEN_SIZE.x / 2) * 0.6)][randi()%2]
		next_position_y = [rng.randi_range((Globals.SCREEN_SIZE.y / 2) * 0.9, (Globals.SCREEN_SIZE.y / 2) * 0.6), rng.randi_range(-(Globals.SCREEN_SIZE.y / 2) * 0.9, -(Globals.SCREEN_SIZE.y / 2) * 0.6)][randi()%2]
		if parent_attack != chosen_attack:
			break

func fireball_circle(userdata: Dictionary) -> void:
	Settings.increase_game_statistic("ongard_normal_times_reached_fourth_phase", 1)
	var params_dict: Dictionary = {
		"global_position": positions_list.global.SCREEN_CENTER,
		"base_speed": userdata.BASE_BULLET_SPEED,
		"owner_data": self,
		"scale": userdata.BASE_BULLET_SIZE,
		"damage": 1,
		"movement_time": userdata.BULLET_MOVEMENT_TIME,
		"max_bursts": -1,
		"base_bullets_per_burst": 8,
		"base_burst_delay": 0.85,
		"random_proyectile_types_enabled": false,
		"proyectile_speed": 200,
	}
	ComplexBulletManager.spawn_bullet(userdata.BULLET_TYPE, params_dict)

func constant_fire_circle(userdata: Dictionary) -> void:
	Settings.increase_game_statistic("ongard_normal_times_reached_fifth_phase", 1)
	var time_between_circles_timer: Timer
	time_between_circles_timer = Utils.wait(1)
	yield(time_between_circles_timer, "timeout")
	var radius: Vector2 = Vector2(500, 0)
	var arena_center: Vector2 = ArenaManager.get_arena_center()
	var step: float
	var current_iteration: int = 0
	var offset: int = 10
	var MAX_WAIT_TIME_BETWEEN_BULLETS: float = .075
	var wait_time_between_bullets: float = MAX_WAIT_TIME_BETWEEN_BULLETS
	var params_dict: Dictionary = {
		"global_position": global_position,
		"scale": userdata.BASE_BULLET_SIZE,
		"after_stopped_speed": userdata.AFTER_STOPPED_SPEED,
	}
	var bullet_angle_to_screen_center: float
	var new_bullet
	while continue_attacking:
		next_wave = false
		step = 2 * PI / userdata.n_of_bullets 
		params_dict.base_speed = userdata.BASE_BULLET_SPEED + (50 - clamp(500 - current_damage_taken, 0, 500) / 10)
		main_attack_timer.set_wait_time(wait_time_between_bullets)
		if not is_defeated:
			for c in range(userdata.n_of_bullets):
				params_dict["global_position"] = arena_center + radius.rotated(step * c + offset * (current_iteration % 15))
				bullet_angle_to_screen_center = (arena_center - params_dict["global_position"]).angle()
				params_dict["velocity"] = Vector2(cos(bullet_angle_to_screen_center), sin(bullet_angle_to_screen_center)) * userdata.BASE_BULLET_SPEED
				new_bullet = SimpleBulletManager.get_avaliable_bullet(userdata.BULLET_TYPE, params_dict)
				delayed_bullet_id_list.append(new_bullet.get_instance_id())
				main_attack_timer.start()
				yield(main_attack_timer, "timeout")
				if is_defeated:
					break
		if not is_defeated:
			for bullet_id in delayed_bullet_id_list:
				SimpleBulletManager.shoot_bullet_by_id(bullet_id, userdata.BULLET_TYPE)
				if is_defeated:
					break
		delayed_bullet_id_list = []
		yield(SimpleBulletManager, "all_delayed_bullets_fired")
		main_attack_timer_start(userdata.DELAY_BETWEEN_CIRCLES)
		yield(main_attack_timer, "timeout")
		current_iteration += 1

func setup_attack_constants() -> void:
	.setup_attack_constants()
	attack_params["flamethrower"] = {
		BASE_BULLET_SPEED = 275,
		BASE_BULLET_SIZE = Globals.BulletSizes.ONE_AND_A_QUARTER,
		BASE_NUMBER_OF_BURSTS = 2,
		BASE_BULLETS_PER_BURST = 30,
		BASE_TIME_BETWEEN_BULLETS = 0.35,
		BULLET_TYPE = Globals.SimpleBulletTypes.STRAIGHT,
		DELAY = 2,
		ENABLE_SECONDARY_ATTACK = 250,
		MOVE_TO = Vector2(positions_list.local.CENTER_X, positions_list.local.BOTTOM_Y),
		TIME_BETWEEN_BULLETS = 0.6,
		SECONDARY_ATTACK = 'fire_rain',
		SECONDARY_ATTACK_PARAMS = {
			BASE_BULLET_SPEED = 300,
			BASE_BULLET_SIZE = Globals.BulletSizes.STANDARD,
			BASE_TIME_BETWEEN_BULLETS = 0.6,
			BULLET_TYPE = Globals.SimpleBulletTypes.STRAIGHT,
		},
		SPAWN_POINTS_TO_DISABLE = {
			"top_left": ["spawn_point1", "spawn_point2", "spawn_point4"],
			"top_right": ["spawn_point1", "spawn_point3", "spawn_point4"],
		}
	}
	attack_params["bullet_hell_semicircle"] = {
		BASE_BULLETS_PER_LAYER = 21,
		BASE_BULLET_SPEED = 250,
		BASE_BULLET_SIZE = Globals.BulletSizes.STANDARD,
		BASE_NUMBER_OF_LAYERS = 21,
		BASE_TIME_BETWEEN_BULLETS = 2.25,
		BULLET_TYPE = Globals.SimpleBulletTypes.CIRCULAR,
		DELAY = 2,
		ENABLE_SECONDARY_ATTACK = 200,
		MOVE_TO = Vector2(positions_list.local.CENTER_X, positions_list.local.TOP_Y),
		SECONDARY_ATTACK = 'shoot_soft_homing_bullet',
		SPAWN_POINTS_TO_DISABLE = {
			"bottom_left": ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"],
			"bottom_right": ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"],
		},
		SECONDARY_ATTACK_PARAMS = {
			BASE_TIME_BETWEEN_BULLETS = 5,
			BULLET_DIRECTION = Vector2(1, 1),
			BULLET_SIZE = Globals.BulletSizes.DOUBLE,
			BULLET_SPEED = 300,
			BULLET_TYPE = Globals.SimpleBulletTypes.SOFT_HOMING,
			GET_RANDOM_X_POSITION = false,
			SPAWN_POSITION_MARGIN_X = 250,
		}
	}
	attack_params["three_lane_fireball"] = {
		ENABLE_SECONDARY_ATTACK = 200,
		MOVE_TO = Vector2(positions_list.local.CENTER_X, positions_list.local.TOP_Y),
		SECONDARY_ATTACK = 'three_lane_fireball_secondary_attack',
		SECONDARY_ATTACK_PARAMS = {
			BASE_BULLET_SPEED = 300,
			BASE_BULLET_SIZE = Globals.BulletSizes.ONE_AND_A_HALF,
			BULLET_TYPE = Globals.SimpleBulletTypes.STRAIGHT,
		},
		SPAWN_POINTS_TO_DISABLE = {
			"top_left": ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"],
			"top_right": ["spawn_point1", "spawn_point2"],
			"bottom_left": ["spawn_point3", "spawn_point4"],
			"bottom_right": ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"]
		},
		LOWER_MINION_PARAMS = {
			"bullets_per_shot": 4,
			"bullet_size": Globals.BulletSizes.QUADRUPLE,
			"bullet_speed": 200,
			"chosen_bullet_direction": "UP",
			"damage_threshold": 500,
			"max_attack_speed": 2,
			"min_attack_speed": 2,
			"position": Vector2(positions_list.local.LEFT_X * 0.3175, positions_list.local.BOTTOM_Y * 0.9),
		},
		UPPER_MINION_PARAMS = {
			"bullets_per_shot": 4,
			"bullet_size": Globals.BulletSizes.QUADRUPLE,
			"bullet_speed": 200,
			"chosen_bullet_direction": "DOWN",
			"damage_threshold": 500,
			"max_attack_speed": 2,
			"min_attack_speed": 2,
			"position": Vector2(positions_list.local.RIGHT_X * 0.3175, positions_list.local.TOP_Y * 0.9),
		}
	}
	attack_params["fireball_circle"] = {
		BASE_BULLET_SPEED = 0,
		BASE_BULLET_SIZE = Globals.BulletSizes.ONE_AND_A_HALF,
		BULLET_MOVEMENT_TIME = 2,
		BULLET_TYPE = Globals.ComplexBulletTypes.PULSATING,
		DELAY = 4,
		ENABLE_SECONDARY_ATTACK = 200,
		NEXT_STAGE = 250,
		SPAWN_POINTS_TO_DISABLE = {
			"top_left": ["spawn_point3", "spawn_point4"],
			"top_right": ["spawn_point1", "spawn_point2"],
			"bottom_left": ["spawn_point3", "spawn_point4"],
			"bottom_right": ["spawn_point1", "spawn_point2"],
		}
	}
	attack_params["constant_fire_circle"] = {
		AFTER_STOPPED_SPEED = 550,
		BASE_BULLET_SPEED = 250,
		BASE_BULLET_SIZE = Globals.BulletSizes.STANDARD,
		BULLET_TYPE = Globals.SimpleBulletTypes.DELAYED,
		DELAY_BETWEEN_CIRCLES = 1,
		ENABLE_SECONDARY_ATTACK = 250,
		n_of_bullets = 30,
		SPAWN_POINTS_TO_DISABLE = {
			"top_left": ["spawn_point3", "spawn_point4"],
			"top_right": ["spawn_point1", "spawn_point2"],
			"bottom_left": ["spawn_point3", "spawn_point4"],
			"bottom_right": ["spawn_point1", "spawn_point2"],
		}
	}
