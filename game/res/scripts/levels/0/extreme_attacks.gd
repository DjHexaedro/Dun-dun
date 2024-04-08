# Attacks used by the hardest version of the boss
extends "res://juegodetriangulos/res/scripts/levels/0/hard_attacks.gd"

signal enable_aimed_pulsating_bullet_movement
signal enable_aimed_pulsating_bullet_multiple_bullet_types
signal unload_aimed_pulsating_bullets
signal fire_wall_finished
signal fireball_finished

const TIME_UNTIL_NEXT_STAGE: int = 1
const MARKER_TIMING_LIST: Array = [35.0, 95.0, 140.0]
const FIREWALL_TOTAL_SIZE: int = 800

var first_row: bool = true
var arena_global_position: Vector2 = Vector2.ZERO
var firewall_starting_position: int = 0


func _ready() -> void:
	firewall_starting_position = ArenaManager.get_arena_center().x - 400
	hardest_mode_time_until_next_stage_timer.set_wait_time(TIME_UNTIL_NEXT_STAGE)
	arena_global_position = ArenaManager.get_location("ongard_arena").get_global_position()

	# For this version of the boss, each stage is timed (i.e., it advances to
	# the next one automatically without the player needing to damage it).
	# This dictionary has, for each attack, a list of functions to call (the value)
	# and at which second to call that function (the key)
	hardest_mode_functions_to_call = {
		"hardest_fire_wall": {
			10: "hardest_fire_wall_second_stage",
			35: "hardest_fire_wall_end",
		},
		"hardest_pulsating_fireball": {
			10: "hardest_pulsating_fireball_second_stage",
			25: "hardest_pulsating_fireball_third_stage",
			40: "hardest_pulsating_fireball_fourth_stage",
			60: "hardest_pulsating_fireball_end",
		},
		"hardest_fireball_circle": {
			15: "hardest_fireball_circle_second_stage",
			30: "hardest_fireball_circle_third_stage",
			45: "hardest_fireball_circle_end",
		},
		"hardest_last_attack": {
			8: "hardest_last_attack_second_stage",
			12: "hardest_last_attack_third_stage",
			16: "hardest_last_attack_fourth_stage",
			20: "hardest_last_attack_fifth_stage",
			22: "hardest_last_attack_sixth_stage",
			24: "hardest_last_attack_seventh_stage",
			30: "hardest_last_attack_eighth_stage",
			37: "hardest_last_attack_ninth_stage",
			44: "hardest_last_attack_last_stage",
		},
	}

func reset(reset_animations: bool = true) -> void:
	if Utils.is_difficulty_hardest():
		hardest_mode_time_until_next_stage_timer.stop()
		hardest_mode_current_fight_time = 0.0
		first_row = true
		current_attack_stage = 0
	.reset(reset_animations)

func begin_attacking_sequence() -> void:
	.begin_attacking_sequence()
	if Utils.is_difficulty_hardest():
		hardest_mode_time_until_next_stage_timer.start()

func enemy_died() -> void:
	.enemy_died()
	if Utils.is_difficulty_hardest():
		hardest_mode_time_until_next_stage_timer.stop()

func hardest_fire_wall(userdata: Dictionary) -> void:
	while continue_attacking:
		create_fire_wall(userdata)
		yield(self, "fire_wall_finished")

func create_fire_wall(userdata: Dictionary) -> void:
	var n_of_rows: int = userdata.N_OF_ROWS
	var params_dict: Dictionary = {
		"global_position": position,
		"base_speed": userdata.BASE_BULLET_SPEED,
		"scale": userdata.BASE_BULLET_SIZE,
		"direction": userdata.BULLET_DIRECTION,
		"bullet_y_position": userdata.BULLET_Y_POSITION,
	}
	for _row_number in range(n_of_rows):
		BulletPatternManager.bullet_wall(userdata.BULLET_TYPE, firewall_starting_position, first_row, FIREWALL_TOTAL_SIZE, userdata.BASE_BULLETS_PER_ROW, [params_dict])
		if first_row:
			main_attack_timer_start(0.6 + userdata.BASE_TIME_BETWEEN_ROWS)
			first_row = false
		else:
			main_attack_timer_start(userdata.BASE_TIME_BETWEEN_ROWS)
		yield(main_attack_timer, "timeout")
		if not continue_attacking:
			break
	emit_signal("fire_wall_finished")

func hardest_fire_wall_second_stage(userdata: Dictionary) -> void:
	var secondary_attack_userdata: Dictionary = userdata.SHOOT_SOFT_HOMING_BULLETS_PARAMS
	secondary_attack_thread.start(self, userdata.SECONDARY_ATTACK, secondary_attack_userdata)

func hardest_fire_wall_end(userdata: Dictionary) -> void:
	continue_attacking = false
	current_attack_stage = 0
	change_boss_phase(current_boss_phase + 1)

func hardest_pulsating_fireball(userdata: Dictionary) -> void:
	Settings.increase_game_statistic("ongard_hardest_times_reached_second_phase", 1)
	var params_dict: Dictionary = {
		"scale": userdata.BULLET_SIZE,
		"n_of_bullets": userdata.N_OF_BULLETS,
		"movement_direction": userdata.MOVEMENT_DIRECTION,
		"speed": userdata.BULLET_SPEED,
		"min_proyectile_speed": userdata.MIN_PROYECTILE_SPEED,
		"max_proyectile_speed": userdata.MAX_PROYECTILE_SPEED,
		"global_position": Vector2(
			positions_list.global.LEFT_X, positions_list.global.CENTER_Y
		),
	}
	ComplexBulletManager.spawn_bullet(userdata.BULLET_TYPE, params_dict)

func hardest_pulsating_fireball_second_stage(userdata: Dictionary) -> void:
	var params_dict: Dictionary = {
		"scale": userdata.BULLET_SIZE,
		"n_of_bullets": userdata.N_OF_BULLETS,
		"movement_direction": -userdata.MOVEMENT_DIRECTION,
		"speed": userdata.BULLET_SPEED,
		"min_proyectile_speed": userdata.MIN_PROYECTILE_SPEED,
		"max_proyectile_speed": userdata.MAX_PROYECTILE_SPEED,
		"global_position": Vector2(
			positions_list.global.RIGHT_X, positions_list.global.CENTER_Y
		),
	}
	ComplexBulletManager.spawn_bullet(userdata.BULLET_TYPE, params_dict)

func hardest_pulsating_fireball_third_stage(_userdata: Dictionary) -> void:
	emit_signal("enable_aimed_pulsating_bullet_multiple_bullet_types")

func hardest_pulsating_fireball_fourth_stage(_userdata: Dictionary) -> void:
	emit_signal("enable_aimed_pulsating_bullet_movement", false)

func hardest_pulsating_fireball_end(_userdata: Dictionary) -> void:
	continue_attacking = false
	current_attack_stage = 0
	emit_signal("unload_aimed_pulsating_bullets")
	SimpleBulletManager.despawn_active_bullets()
	yield(SimpleBulletManager, "all_bullets_despawned")
	change_boss_phase(current_boss_phase + 1)

func hardest_fireball_circle(userdata: Dictionary) -> void:
	Settings.increase_game_statistic("ongard_hardest_times_reached_third_phase", 1)
	while continue_attacking:
		create_fireball_circle(userdata)
		yield(self, "fireball_finished")

func hardest_fireball_circle_second_stage(userdata: Dictionary) -> void:
	userdata["wait_time"] = 0.15
	userdata["random_bullet_types"] = true 

func hardest_fireball_circle_third_stage(userdata: Dictionary) -> void:
	userdata["wait_time"] = 0.1

func hardest_fireball_circle_end(_userdata: Dictionary) -> void:
	current_attack_stage = 0
	continue_attacking = false
	yield(self, "fireball_finished")
	SimpleBulletManager.despawn_active_bullets()
	yield(SimpleBulletManager, "all_bullets_despawned")
	change_boss_phase(current_boss_phase + 1)

func create_fireball_circle(userdata: Dictionary) -> void:
	var n_of_fireballs: int = userdata.N_OF_FIREBALLS
	var new_position: Vector2
	var wait_time: float = userdata.BASE_TIME_BETWEEN_BULLETS
	var bursts_per_shot: int = userdata.BASE_BURSTS_PER_SHOT
	var bullets_per_burst: int = userdata.BASE_BULLETS_PER_BURST
	var random_bullet_types: bool = userdata.get("random_bullet_types", false)
	var player_position: Vector2
	var params_dict: Dictionary
	var new_position_valid: bool
	var loop_passed: bool
	for _fireball_number in range(n_of_fireballs):
		new_position_valid = false
		while not new_position_valid:
			new_position = Vector2(
				rng.randi_range(positions_list.global.LEFT_X, positions_list.global.RIGHT_X),
				rng.randi_range(positions_list.global.TOP_Y, positions_list.global.BOTTOM_Y)
			)
			loop_passed = true
			for player_id in range(PlayerManager.get_number_of_players()):
				player_position = PlayerManager.get_player_position(player_id)
				if new_position.distance_squared_to(player_position) <= userdata.MIN_DISTANCE_TO_PLAYER:
					loop_passed = false
					break
			new_position_valid = loop_passed
		params_dict = {
			"scale": userdata.BASE_BULLET_SIZE,
			"max_bursts": bursts_per_shot,
			"base_bullets_per_burst": bullets_per_burst,
			"base_burst_delay": userdata.BASE_BURST_DELAY,
			"random_proyectile_types_enabled": random_bullet_types,
			"global_position": new_position,
			"enable_blinking": false,
		}
		ComplexBulletManager.spawn_bullet(userdata.BULLET_TYPE, params_dict)
		main_attack_timer_start(wait_time)
		yield(main_attack_timer, "timeout")
		if not continue_attacking:
			break
	emit_signal("fireball_finished")

func hardest_last_attack(userdata: Dictionary) -> void:
	Settings.increase_game_statistic("ongard_hardest_times_reached_fourth_phase", 1)
	var fire_wall_userdata = attack_params.hardest_fire_wall
	fire_wall_userdata.is_last_attack = true
	fire_wall_userdata.BASE_TIME_BETWEEN_ROWS = 0.3
	fire_wall_userdata.BASE_BULLET_SPEED = 400
	fire_wall_userdata.N_OF_ROWS = 10
	first_row = true
	create_fire_wall(fire_wall_userdata)

func hardest_last_attack_second_stage(userdata: Dictionary) -> void:
	var fire_wall_userdata = attack_params.hardest_fire_wall
	fire_wall_userdata.BULLET_DIRECTION = Globals.Directions.UP
	fire_wall_userdata.BULLET_Y_POSITION = positions_list.global.BOTTOM_Y
	first_row = true
	create_fire_wall(fire_wall_userdata)

func hardest_last_attack_third_stage(userdata: Dictionary) -> void:
	var fireball_circle_userdata = attack_params.hardest_fireball_circle
	fireball_circle_userdata.N_OF_FIREBALLS = 15 
	fireball_circle_userdata.BASE_BULLETS_PER_BURST = 30
	fireball_circle_userdata.BASE_TIME_TO_DESTINATION = 0.25
	fireball_circle_userdata.BASE_TIME_BETWEEN_BULLETS = 0.1
	fireball_circle_userdata.is_last_attack = true
	create_fireball_circle(fireball_circle_userdata)

func hardest_last_attack_fourth_stage(userdata: Dictionary) -> void:
	var fireball_circle_userdata = attack_params.hardest_fireball_circle
	fireball_circle_userdata.N_OF_FIREBALLS = 5
	fireball_circle_userdata.BASE_BURSTS_PER_SHOT = 6
	fireball_circle_userdata.BASE_BULLETS_PER_BURST = 40
	create_fireball_circle(fireball_circle_userdata)

func hardest_last_attack_fifth_stage(userdata: Dictionary) -> void:
	var aimed_fireball_userdata = attack_params.hardest_pulsating_fireball
	var aimed_pulsating_bullet_params_dict = {
		"scale": aimed_fireball_userdata.BULLET_SIZE,
		"n_of_bullets": 5,
		"speed": Vector2(400, 400),
		"min_proyectile_speed": 300,
		"max_proyectile_speed": 400,
		"actual_burst_delay": 1.5,
		"global_position": Vector2(
			positions_list.global.LEFT_X, positions_list.global.CENTER_Y
		),
		"multiple_bullet_types_enabled": false,
	}
	ComplexBulletManager.spawn_bullet(
		aimed_fireball_userdata.BULLET_TYPE, aimed_pulsating_bullet_params_dict
	)

func hardest_last_attack_sixth_stage(userdata: Dictionary) -> void:
	emit_signal("enable_aimed_pulsating_bullet_movement", true)

func hardest_last_attack_seventh_stage(userdata: Dictionary) -> void:
	var fireball_circle_userdata = attack_params.hardest_fireball_circle
	fireball_circle_userdata.N_OF_FIREBALLS = 40 
	fireball_circle_userdata.BASE_BULLETS_PER_BURST = 16
	fireball_circle_userdata.BASE_BURSTS_PER_SHOT = 1
	fireball_circle_userdata.BASE_TIME_TO_DESTINATION = 0.5
	fireball_circle_userdata.BASE_TIME_BETWEEN_BULLETS = 0.1
	fireball_circle_userdata.is_last_attack = true
	create_fireball_circle(fireball_circle_userdata)

func hardest_last_attack_eighth_stage(userdata: Dictionary) -> void:
	var fire_wall_userdata = attack_params.hardest_fire_wall
	fire_wall_userdata.BASE_TIME_BETWEEN_ROWS = 1
	fire_wall_userdata.BASE_BULLET_SPEED = 400
	fire_wall_userdata.BASE_BULLETS_PER_ROW = 17
	fire_wall_userdata.N_OF_ROWS = 5
	fire_wall_userdata.BULLET_DIRECTION = Globals.Directions.DOWN
	fire_wall_userdata.BULLET_Y_POSITION = global_position.y + Globals.SCREEN_SIZE.y * 0.1
	first_row = true
	create_fire_wall(fire_wall_userdata)

func hardest_last_attack_ninth_stage(userdata: Dictionary) -> void:
	var fire_wall_userdata = attack_params.hardest_fire_wall
	fire_wall_userdata.BULLET_DIRECTION = Globals.Directions.UP
	fire_wall_userdata.BULLET_Y_POSITION = positions_list.global.BOTTOM_Y
	first_row = true
	create_fire_wall(fire_wall_userdata)

func hardest_last_attack_last_stage(userdata: Dictionary) -> void:
	ComplexBulletManager.despawn_active_bullets()
	yield(ComplexBulletManager, "all_bullets_despawned")
	SimpleBulletManager.despawn_active_bullets()
	yield(SimpleBulletManager, "all_bullets_despawned")
	emit_signal("enemy_death")

func setup_attack_constants() -> void:
	.setup_attack_constants()
	attack_params["hardest_fire_wall"] = {
		BASE_BULLET_SPEED = 200,
		BASE_BULLET_SIZE = Globals.BulletSizes.STANDARD,
		BASE_BULLETS_PER_ROW = 16,
		BASE_TIME_BETWEEN_ROWS = 0.35,
		BULLET_DIRECTION = Globals.Directions.DOWN,
		BULLET_TYPE = Globals.SimpleBulletTypes.STRAIGHT,
		BULLET_Y_POSITION = global_position.y + Globals.SCREEN_SIZE.y * 0.1,
		N_OF_ROWS = 10,
		SECONDARY_ATTACK = 'shoot_soft_homing_bullet',
		SHOOT_SOFT_HOMING_BULLETS_PARAMS = {
			BASE_TIME_BETWEEN_BULLETS = 3,
			BULLET_DIRECTION = Vector2(1, 1),
			BULLET_SIZE = Globals.BulletSizes.DOUBLE,
			BULLET_SPEED = 300,
			BULLET_TYPE = Globals.SimpleBulletTypes.SOFT_HOMING,
			SPAWN_POSITION_MARGIN_X = 250,
		},
	}
	attack_params["hardest_fireball_circle"] = {
		BASE_BULLET_SPEED = 0,
		BASE_BULLET_SIZE = Globals.BulletSizes.TRIPLE,
		BASE_BULLETS_PER_BURST = 11,
		BASE_BURST_DELAY = .25,
		BASE_BURSTS_PER_SHOT = 1,
		BASE_TIME_BETWEEN_BULLETS = 0.2,
		BASE_TIME_TO_DESTINATION = 1,
		N_OF_FIREBALLS = 10,
		BULLET_TYPE = Globals.ComplexBulletTypes.PULSATING,
		DELAY = 4,
		ENABLE_SECONDARY_ATTACK = 200,
		MIN_DISTANCE_TO_PLAYER = 100000,
	}
	attack_params["hardest_pulsating_fireball"] = {
		BULLET_TYPE = Globals.ComplexBulletTypes.AIMED_PULSATING,
		BULLET_SIZE = Globals.BulletSizes.DOUBLE,
		BULLET_SPEED = Vector2(100, 100),
		N_OF_BULLETS = 4,
		MAX_PROYECTILE_SPEED = 200,
		MIN_PROYECTILE_SPEED = 100,
		MOVEMENT_DIRECTION = 1,
	}
