extends "res://juegodetriangulos/res/scripts/levels/2/normal_attacks.gd"

func reset() -> void:
	if GameStateManager.get_difficulty_level() == Globals.DifficultyLevels.HARD:
		BINARY_TREE_BULLET_POSITIONS = [
			Vector2(-810, -560),
			Vector2(-810, 0),
			Vector2(-810, 560),
			Vector2(0, -560),
			Vector2(810, -560),
			Vector2(810, 0),
			Vector2(810, 560),
			Vector2(0, 560),
		]
		needed_streak = 2
		allowed_operations = [
			Operations.SUM, Operations.SUB, Operations.MUL, Operations.DIV, 
		]
		current_answer_time = ANSWER_TIME * needed_streak * 0.75

	.reset()

func _ready():
	if GameStateManager.get_difficulty_level() == Globals.DifficultyLevels.HARD:
		BINARY_TREE_BULLET_POSITIONS = [
			Vector2(-810, -560),
			Vector2(-810, 0),
			Vector2(-810, 560),
			Vector2(0, -560),
			Vector2(810, -560),
			Vector2(810, 0),
			Vector2(810, 560),
			Vector2(0, 560),
		]
		allowed_operations.append(Operations.SUB)
		allowed_operations.append(Operations.MUL)
		allowed_operations.append(Operations.DIV)
		needed_streak = 2
		current_answer_time = ANSWER_TIME * needed_streak * 0.75

func change_boss_phase(new_boss_phase: int) -> void:
	waiting_to_change_phase = true

	if is_attacking:
		yield(self, "attack_finished")

	if GameStateManager.get_difficulty_level() == Globals.DifficultyLevels.HARD:
		if new_boss_phase == 3:
			needed_streak = 3
			current_answer_time = ANSWER_TIME * needed_streak * 0.7
		elif new_boss_phase == 5:
			needed_streak = 1
			current_answer_time = ANSWER_TIME
			hide_sign = true
		elif new_boss_phase == 9:
			current_answer_time -= 1
		elif new_boss_phase == 11:
			needed_streak = 2
			current_answer_time = ANSWER_TIME * needed_streak * 0.75
		elif new_boss_phase == 13:
			current_answer_time -= 0.5
		elif new_boss_phase == 16:
			needed_streak = 4
			current_answer_time = ANSWER_TIME * needed_streak * 0.6
		elif new_boss_phase == 18:
			current_answer_time -= 0.6

	.change_boss_phase(new_boss_phase)
	waiting_to_change_phase = false

func setup_attack_constants() -> void:
	.setup_attack_constants()
	if GameStateManager.get_difficulty_level() == Globals.DifficultyLevels.HARD:
		attack_params["zero_storm"] = {
			SEMICIRCLE_PARAMS = {
				"global_position": global_position,
				"scale": Globals.BulletSizes.STANDARD,
				"rotation_direction": 1,
				"speed": 150,
			},
			NUMBER_OF_LAYERS = 20,
			TIME_BETWEEN_CIRCLES = 0.3,
			ATTACK_DURATION = 12,
			PROYECTILES_PER_EXPLOSION = 24,
			BULLET_TYPES = [
				Globals.SimpleBulletTypes.STRAIGHT_ZERO,
				Globals.SimpleBulletTypes.CIRCULAR_ZERO,
			],
		}
		attack_params["binary_tree_of_perdition"] = {
			BULLET_PARAMS = {
				"n_of_bullets_in_explosion": 2,
				"scale": Vector2(10, 10),
				"minimum_size": Vector2(0.3375, 0.3375),
				"base_speed": 6,
				"time_until_explosion": 1.25,
				"look_at": true,
			},
			ATTACK_DURATION = 11.5,
			BULLET_TYPE = Globals.ComplexBulletTypes.DIVIDING,
		}
		attack_params["linear_algebra"] = {
			BULLET_PARAMS = {
				"scale": Globals.BulletSizes.STANDARD,
				"direction": Vector2(1, 0),
				"speed": 200,
			},
			BULLET_PARAMS_PRESETS = [{
				SCALE = Globals.BulletSizes.STANDARD,
				SPEED = 350,
				TIME_BETWEEN_BULLETS = 0.75,
				N_OF_BULLETS = 30,
				N_OF_LINES = 13,
				TIME_AFTER_FINISH = 6,
			}, {
				SCALE = Globals.BulletSizes.TRIPLE,
				SPEED = 150,
				TIME_BETWEEN_BULLETS = 0.8,
				N_OF_BULLETS = 20,
				N_OF_LINES = 10,
				TIME_AFTER_FINISH = 10,
			}, {
				SCALE = Globals.BulletSizes.STANDARD,
				SPEED = 100,
				TIME_BETWEEN_BULLETS = 0.675,
				N_OF_BULLETS = 15,
				N_OF_LINES = 13,
				TIME_AFTER_FINISH = 7,
			}, {
				SCALE = Globals.BulletSizes.QUADRUPLE,
				SPEED = 200,
				TIME_BETWEEN_BULLETS = 0.85,
				N_OF_BULLETS = 10,
				N_OF_LINES = 7,
				TIME_AFTER_FINISH = 12,
			}],
			ATTACK_DURATION = 16,
			BULLET_TYPE = Globals.SimpleBulletTypes.STRAIGHT_ZERO,
		}
		attack_params["zero_escape"] = {
			BULLET_PARAMS = {
				"max_bursts": 7,
				"n_of_bullets_in_explosion": 28,
				"base_speed": 350,
				"explosion_bullets_speed": 250,
				"follow_time": 8,
				"spawn_time": 1.5,
				"spawned_bullet_params": {
					"bullet_type": Globals.ComplexBulletTypes.PULSATING_ZERO,
					"proyectiles_per_explosion": 16,
					"proyectile_speed": 250,
					"max_bursts": 1,
					"scale": Globals.BulletSizes.QUADRUPLE,
				},
			},
			ATTACK_DURATION = 15,
			BULLET_TYPES = [
				Globals.ComplexBulletTypes.ACTUAL_HOMMING,
				Globals.ComplexBulletTypes.PULSATING_ZERO,
				Globals.SimpleBulletTypes.STRAIGHT_ZERO,
			],
		}
		attack_params["zero_room"] = {
			PRESETS = [{
				N_OF_ROWS = 10,
				N_OF_BULLETS_PER_ROW = 18,
				BULLET_WAIT_TIME = 0.1,
				ROW_WAIT_TIME = 0,
				BULLET_PARAMS = {
					"speed": 400,
					"velocity": Vector2.ZERO,
					"scale": Globals.BulletSizes.STANDARD,
				},
			}, {
				N_OF_ROWS = 8,
				N_OF_BULLETS_PER_ROW = 36,
				BULLET_WAIT_TIME = 0,
				ROW_WAIT_TIME = 2,
				BULLET_PARAMS = {
					"speed": 100,
					"velocity": Vector2.ZERO,
					"scale": Globals.BulletSizes.STANDARD,
				},
			}, {
				N_OF_ROWS = 40,
				N_OF_BULLETS_PER_ROW = 5,
				BULLET_WAIT_TIME = 0.1,
				ROW_WAIT_TIME = 0,
				BULLET_PARAMS = {
					"speed": 180,
					"velocity": Vector2.ZERO,
					"scale": Globals.BulletSizes.DOUBLE,
				},
			}, {
				N_OF_ROWS = 4,
				N_OF_BULLETS_PER_ROW = 30,
				BULLET_WAIT_TIME = 0,
				ROW_WAIT_TIME = 0,
				BULLET_PARAMS = {
					"speed": 200,
					"velocity": Vector2.ZERO,
					"scale": Globals.BulletSizes.STANDARD,
				},
			}],
			TIME_UNTIL_FINISH = 3,
			DELAY_UNTIL_MOVEMENT = 1,
			BULLET_TYPE = Globals.SimpleBulletTypes.STRAIGHT_ZERO,
		}
