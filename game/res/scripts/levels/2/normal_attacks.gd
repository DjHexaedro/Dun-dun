extends "res://juegodetriangulos/res/scripts/levels/2/base.gd"

var BINARY_TREE_BULLET_POSITIONS: Array = [
	Vector2(-810, 0),
	Vector2(0, -560),
	Vector2(810, 0),
	Vector2(0, 560),
]
var last_chosen_linear_algebra_id: int = -1

func reset() -> void:
	if GameStateManager.get_difficulty_level() == Globals.DifficultyLevels.NORMAL:
		BINARY_TREE_BULLET_POSITIONS = [
			Vector2(-810, 0),
			Vector2(0, -560),
			Vector2(810, 0),
			Vector2(0, 560),
		]
		needed_streak = 1
		allowed_operations = [ Operations.SUM ]
		current_answer_time = ANSWER_TIME

	.reset()

func change_boss_phase(new_boss_phase: int) -> void:
	waiting_to_change_phase = true

	if is_attacking:
		yield(self, "attack_finished")

	if GameStateManager.get_difficulty_level() == Globals.DifficultyLevels.NORMAL:
		if new_boss_phase == 2:
			allowed_operations.append(Operations.SUB)
		elif new_boss_phase == 4:
			current_answer_time -= 1
		elif new_boss_phase == 6:
			current_answer_time -= 1
		elif new_boss_phase == 8:
			allowed_operations.erase(Operations.SUM)
			allowed_operations.erase(Operations.SUB)
			allowed_operations.append(Operations.MUL)
			allowed_operations.append(Operations.DIV)
			current_answer_time = ANSWER_TIME
		elif new_boss_phase == 10:
			current_answer_time -= 1
		elif new_boss_phase == 12:
			current_answer_time -= 1
		elif new_boss_phase == 13:
			allowed_operations.append(Operations.SUM)
			allowed_operations.append(Operations.SUB)
			needed_streak = 2
			current_answer_time = ANSWER_TIME * needed_streak
		elif new_boss_phase == 17:
			needed_streak = 3
			current_answer_time = ANSWER_TIME * needed_streak

	.change_boss_phase(new_boss_phase)
	waiting_to_change_phase = false

func zero_storm(attack_params: Dictionary) -> void:
	var starting_angles: Array = [
		(positions_list.local.SCREEN_CENTER - position).angle() - PI/2, # For straight bullets
		(positions_list.local.SCREEN_CENTER - position + Vector2(2500, 2500)).angle() - PI/2, # For circular bullets
	]
	var speeds_list: Array = [
		attack_params.SEMICIRCLE_PARAMS.speed,
		attack_params.SEMICIRCLE_PARAMS.speed + 25,
	]
	var bullet_type_id: int = -1
	var chosen_angle: float
	last_attack_id = current_attack

	while continue_attacking:
		bullet_type_id = randi()%len(attack_params.BULLET_TYPES)
		chosen_angle = starting_angles[bullet_type_id]

		attack_params.SEMICIRCLE_PARAMS.speed = speeds_list[bullet_type_id]

		BulletPatternManager.bullet_hell_semicircle(
			attack_params.BULLET_TYPES[bullet_type_id],
			attack_params.PROYECTILES_PER_EXPLOSION,
			chosen_angle,
			[attack_params.SEMICIRCLE_PARAMS]
		)

		secondary_attack_timer_start(attack_params.TIME_BETWEEN_CIRCLES)
		yield(secondary_attack_timer, "timeout")

		if last_attack_id != current_attack:
			break

func binary_tree_of_perdition(attack_params: Dictionary) -> void:
	last_attack_id = current_attack

	for bullet_position in BINARY_TREE_BULLET_POSITIONS: 
		attack_params.BULLET_PARAMS.screen_center_position = positions_list.global.SCREEN_CENTER
		attack_params.BULLET_PARAMS.global_position = bullet_position
		attack_params.BULLET_PARAMS.direction = -bullet_position.normalized()
		attack_params.BULLET_PARAMS.velocity =\
				attack_params.BULLET_PARAMS.direction * attack_params.BULLET_PARAMS.base_speed
		ComplexBulletManager.shoot_bullet(attack_params.BULLET_TYPE, attack_params.BULLET_PARAMS)

func linear_algebra(attack_params: Dictionary) -> void:
	var chosen_preset_id: int = randi()%len(attack_params.BULLET_PARAMS_PRESETS)
	while chosen_preset_id == last_chosen_linear_algebra_id:
		chosen_preset_id = randi()%len(attack_params.BULLET_PARAMS_PRESETS)
	last_chosen_linear_algebra_id = chosen_preset_id

	var chosen_preset: Dictionary = attack_params.BULLET_PARAMS_PRESETS[
		chosen_preset_id
	]
	var starting_y_position: int = -240
	var ending_y_position: int = 240
	var total_distance: int = ending_y_position - starting_y_position
	var distance_between_lines: int = total_distance / chosen_preset.N_OF_LINES
	var c: int = 0
	var offset: int = 20
	var direction: Vector2 = Vector2(1, 0)
	var x_position: int = -810
	var bullet_params: Dictionary
	var y_offset: int
	last_attack_id = current_attack
	
	while continue_attacking:
		for i in range(chosen_preset.N_OF_LINES):
			bullet_params = attack_params.BULLET_PARAMS.duplicate()
			bullet_params.direction = direction
			bullet_params.speed = chosen_preset.SPEED
			bullet_params.scale = chosen_preset.SCALE
			bullet_params.velocity = bullet_params.speed * bullet_params.direction

			y_offset = ((distance_between_lines * i + offset * c) % total_distance)
			bullet_params.global_position = Vector2(
				x_position, ending_y_position - y_offset
			)
			SimpleBulletManager.shoot_bullet(attack_params.BULLET_TYPE, bullet_params)

			direction *= -1
			x_position *= -1

		secondary_attack_timer_start(chosen_preset.TIME_BETWEEN_BULLETS)
		yield(secondary_attack_timer, "timeout")
		c += 1

		if last_attack_id != current_attack:
			break

func zero_escape(attack_params: Dictionary) -> void:
	last_attack_id = current_attack

	attack_params.BULLET_PARAMS.global_position = BINARY_TREE_BULLET_POSITIONS[
		randi()%len(BINARY_TREE_BULLET_POSITIONS)
	] 

	var target_id: int =\
			respondant_id\
			if PlayerManager.is_player_alive(respondant_id) else\
			PlayerManager.get_random_player_id([respondant_id])
	attack_params.BULLET_PARAMS.followed_player_id = target_id

	ComplexBulletManager.shoot_bullet(attack_params.BULLET_TYPES[0], attack_params.BULLET_PARAMS)

func zero_room(attack_params: Dictionary) -> void:
	var preset: Dictionary = attack_params.PRESETS[randi()%len(attack_params.PRESETS)]
	var row_margin: float = 1080 / preset.N_OF_ROWS
	var bullet_margin: float = 1920 / preset.N_OF_BULLETS_PER_ROW
	var initial_position: Vector2 = Vector2(-960, -540)
	var new_bullet_params: Dictionary
	var bullet_params: Dictionary = preset.BULLET_PARAMS
	last_attack_id = current_attack

	for row in range(preset.N_OF_ROWS):
		for bullet in range(preset.N_OF_BULLETS_PER_ROW):
			new_bullet_params = bullet_params.duplicate()
			new_bullet_params.global_position = initial_position + Vector2(
				bullet_margin * bullet + randi()%int(bullet_margin) - bullet_margin / 2,
				row_margin * row + randi()%int(row_margin) - row_margin / 2
			)
			SimpleBulletManager.spawn_bullet(
				attack_params.BULLET_TYPE, new_bullet_params
			)

	secondary_attack_timer_start(attack_params.DELAY_UNTIL_MOVEMENT)
	yield(secondary_attack_timer, "timeout")

	var target_id: int =\
			respondant_id\
			if PlayerManager.is_player_alive(respondant_id) else\
			PlayerManager.get_random_player_id([respondant_id])

	var bullet_list: Array = SimpleBulletManager.get_active_bullets_ids_by_type(
		attack_params.BULLET_TYPE
	).duplicate()
	var bullet_direction: Vector2
	var current_bullet_index: int = 0
	for bullet in bullet_list:
		bullet_direction = (
			PlayerManager.get_player_global_position(target_id) -
			instance_from_id(bullet).global_position
		).normalized()
		SimpleBulletManager.change_bullet_param(
			bullet, "velocity", bullet_direction * bullet_params.speed
		)

		if preset.BULLET_WAIT_TIME > 0:
			secondary_attack_timer_start(preset.BULLET_WAIT_TIME)
			yield(secondary_attack_timer, "timeout")

		current_bullet_index += 1
		if current_bullet_index >= preset.N_OF_BULLETS_PER_ROW:
			if preset.ROW_WAIT_TIME > 0:
				secondary_attack_timer_start(preset.ROW_WAIT_TIME)
				yield(secondary_attack_timer, "timeout")
			current_bullet_index = 0

		if last_attack_id != current_attack:
			break

	main_attack_timer_start(attack_params.TIME_UNTIL_FINISH)
	yield(main_attack_timer, "timeout")


func setup_attack_constants() -> void:
	.setup_attack_constants()
	if GameStateManager.get_difficulty_level() == Globals.DifficultyLevels.NORMAL:
		attack_params["zero_storm"] = {
			SEMICIRCLE_PARAMS = {
				"global_position": global_position,
				"scale": Globals.BulletSizes.STANDARD,
				"rotation_direction": 1,
				"speed": 75,
			},
			NUMBER_OF_LAYERS = 15,
			TIME_BETWEEN_CIRCLES = 0.75,
			ATTACK_DURATION = 15,
			PROYECTILES_PER_EXPLOSION = 18,
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
				"base_speed": 5,
				"time_until_explosion": 1.5,
				"look_at": true,
			},
			ATTACK_DURATION = 13,
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
				SPEED = 200,
				TIME_BETWEEN_BULLETS = 0.5,
				N_OF_BULLETS = 35,
				N_OF_LINES = 8,
			}, {
				SCALE = Globals.BulletSizes.DOUBLE,
				SPEED = 100,
				TIME_BETWEEN_BULLETS = 0.8,
				N_OF_BULLETS = 20,
				N_OF_LINES = 6,
			}, {
				SCALE = Globals.BulletSizes.STANDARD,
				SPEED = 300,
				TIME_BETWEEN_BULLETS = 0.6,
				N_OF_BULLETS = 15,
				N_OF_LINES = 8,
			}, {
				SCALE = Globals.BulletSizes.QUADRUPLE,
				SPEED = 120,
				TIME_BETWEEN_BULLETS = 1.2,
				N_OF_BULLETS = 10,
				N_OF_LINES = 4,
			}],
			ATTACK_DURATION = 15,
			BULLET_TYPE = Globals.SimpleBulletTypes.STRAIGHT_ZERO,
		}
		attack_params["zero_escape"] = {
			BULLET_PARAMS = {
				"max_bursts": 1,
				"n_of_bullets_in_explosion": 16,
				"base_speed": 200,
				"explosion_bullets_speed": 200,
				"follow_time": 10,
				"spawn_time": 2,
				"spawned_bullet_params": {
					"bullet_type": Globals.ComplexBulletTypes.PULSATING_ZERO,
					"proyectiles_per_explosion": 16,
					"proyectile_speed": 200,
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
				N_OF_BULLETS_PER_ROW = 10,
				BULLET_WAIT_TIME = 0.2,
				ROW_WAIT_TIME = 0.8,
				BULLET_PARAMS = {
					"speed": 200,
					"velocity": Vector2.ZERO,
					"scale": Globals.BulletSizes.STANDARD,
				},
			}, {
				N_OF_ROWS = 8,
				N_OF_BULLETS_PER_ROW = 12,
				BULLET_WAIT_TIME = 0,
				ROW_WAIT_TIME = 1.25,
				BULLET_PARAMS = {
					"speed": 150,
					"velocity": Vector2.ZERO,
					"scale": Globals.BulletSizes.STANDARD,
				},
			}, {
				N_OF_ROWS = 20,
				N_OF_BULLETS_PER_ROW = 5,
				BULLET_WAIT_TIME = 0.2,
				ROW_WAIT_TIME = 0,
				BULLET_PARAMS = {
					"speed": 120,
					"velocity": Vector2.ZERO,
					"scale": Globals.BulletSizes.DOUBLE,
				},
			}, {
				N_OF_ROWS = 5,
				N_OF_BULLETS_PER_ROW = 10,
				BULLET_WAIT_TIME = 0.1,
				ROW_WAIT_TIME = 0,
				BULLET_PARAMS = {
					"speed": 300,
					"velocity": Vector2.ZERO,
					"scale": Globals.BulletSizes.STANDARD,
				},
			}],
			TIME_UNTIL_FINISH = 3,
			DELAY_UNTIL_MOVEMENT = 1.5,
			BULLET_TYPE = Globals.SimpleBulletTypes.STRAIGHT_ZERO,
		}
