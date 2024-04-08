extends "res://juegodetriangulos/res/scripts/levels/1/normal_attacks.gd"


func change_boss_phase(new_boss_phase):
	if Utils.is_difficulty_hard():
		continue_attacking = false
		SimpleBulletManager.despawn_active_bullets_by_type_list([
		  Globals.SimpleBulletTypes.PAWN,
		  Globals.SimpleBulletTypes.ROOK,
		  Globals.SimpleBulletTypes.BISHOP,
		])
		yield(SimpleBulletManager, "bullets_despawned_by_type_list")

		emit_signal("clear_used_board_space_spawners")

	.change_boss_phase(new_boss_phase)

func caro_kann_greater_offense(attack_params: Dictionary) -> void:
	var spawn_position: Vector2 
	var current_attack_id: int = current_attack
	var pawn_attack_params: Dictionary = attack_params.get(
		Globals.SimpleBulletTypes.PAWN
	)
	var base_time_between_attacks: float = attack_params.TIME_BETWEEN_ATTACKS
	var time_between_attacks_decrement: float = 0.0
	var current_iteration: int = 0
	while continue_attacking:
		spawn_position = select_spawn_space(true) 
		spawn_piece(
			Globals.SimpleBulletTypes.PAWN, spawn_position,
			pawn_attack_params, false, true
		)
		main_attack_timer_start(
			base_time_between_attacks - time_between_attacks_decrement
		)
		yield(main_attack_timer, "timeout")
		time_between_attacks_decrement = clamp(
			time_between_attacks_decrement + 1.25, 0, 2
		)
		current_iteration += 1
		if current_iteration % 4 == 0:
			emit_signal("clear_used_board_space_spawners")
		if current_attack_id != current_attack:
			break

func shirovs_bishop_abuse(attack_params: Dictionary) -> void:
	var current_column: int = 0
	var column_increment: int = 1
	var current_attack_id: int = current_attack
	var bishop_up_params: Dictionary = attack_params.get(
		Globals.SimpleBulletTypes.BISHOP
	).duplicate()
	var illuminate_to_spawn_delay: float = attack_params.ILLUMINATE_TO_SPAWN_DELAY
	while continue_attacking:
		if current_column in [0, 7]:
			bishop_up_params.direction.x *= -1

		spawn_piece_illuminating_space(
			Globals.SimpleBulletTypes.BISHOP, Vector2(current_column, 7),
			illuminate_to_spawn_delay, bishop_up_params, false, true
		)

		main_attack_timer_start(attack_params.TIME_BETWEEN_ATTACKS)
		yield(main_attack_timer, "timeout")
		current_column += column_increment
		if current_column in [0, 7]:
			column_increment *= -1
		if current_attack_id != current_attack:
			break

func parkovs_piece_hell(attack_params: Dictionary) -> void:
	var piece_types: Array = [
		Globals.SimpleBulletTypes.PAWN,
		Globals.SimpleBulletTypes.PAWN + "_ex",
		Globals.SimpleBulletTypes.BISHOP,
		Globals.SimpleBulletTypes.BISHOP + "_ex",
		Globals.SimpleBulletTypes.ROOK,
	]
	while continue_attacking:
		var chosen_piece_type_index: int = randi()%len(piece_types)
		var chosen_piece_type: String = piece_types[chosen_piece_type_index]
		var piece_params: Dictionary = attack_params[chosen_piece_type]
		spawn_piece_illuminating_space(
			piece_params.actual_piece_type, get_random_board_space_position(),
			attack_params.ILLUMINATE_TO_SPAWN_DELAY, piece_params, false,
			chosen_piece_type_index % 2 == 1
		)
		main_attack_timer_start(attack_params.TIME_BETWEEN_ATTACKS)
		yield(main_attack_timer, "timeout")


func gellers_improved_rooks(piece_params: Dictionary) -> void:
	var rook_attack_params: Dictionary = piece_params.get(
		Globals.SimpleBulletTypes.ROOK, {}
	).duplicate()
	var current_attack_id: int = current_attack
	var n_of_rooks: int = piece_params.N_OF_ROOKS
	while continue_attacking:
		if current_attack_id != current_attack:
			break
		for _i in range(n_of_rooks):
			spawn_piece(
				Globals.SimpleBulletTypes.ROOK, Vector2.ZERO, rook_attack_params,
				false, true
			)
			yield(get_tree().create_timer(0.15), "timeout")
		main_attack_timer_start(piece_params.TIME_BETWEEN_ATTACKS)
		yield(main_attack_timer, "timeout")


func gellers_rook_dance(piece_params: Dictionary) -> void:
	var illuminate_to_spawn_delay: float = piece_params.ILLUMINATE_TO_SPAWN_DELAY
	var Q1_ROOKS_SPEED: int = piece_params.speed + 50
	var q1_rook_a_params: Dictionary = piece_params.duplicate()
	q1_rook_a_params.merge({"allowed_movements": [
		{ "destination": 3, "velocity": Vector2(Q1_ROOKS_SPEED, 0) },
		{ "destination": 3, "velocity": Vector2(0, Q1_ROOKS_SPEED) },
		{ "destination": 0, "velocity": Vector2(-Q1_ROOKS_SPEED, 0) },
		{ "destination": 0, "velocity": Vector2(0, -Q1_ROOKS_SPEED) }
	]}, true)
	spawn_piece_illuminating_space(
		Globals.SimpleBulletTypes.ROOK, Vector2(0, 0),
		illuminate_to_spawn_delay, q1_rook_a_params
	)
	var q1_rook_b_params: Dictionary = piece_params.duplicate()
	q1_rook_b_params.merge({"allowed_movements": [
		{ "destination": 0, "velocity": Vector2(-Q1_ROOKS_SPEED, 0) },
		{ "destination": 0, "velocity": Vector2(0, -Q1_ROOKS_SPEED) },
		{ "destination": 3, "velocity": Vector2(Q1_ROOKS_SPEED, 0) },
		{ "destination": 3, "velocity": Vector2(0, Q1_ROOKS_SPEED) }
	]}, true)
	spawn_piece_illuminating_space(
		Globals.SimpleBulletTypes.ROOK, Vector2(3, 3),
		illuminate_to_spawn_delay, q1_rook_b_params
	)

	var Q2_ROOKS_SPEED: int = piece_params.speed - 25 
	var q2_rook_a_params: Dictionary = piece_params.duplicate()
	q2_rook_a_params.merge({"allowed_movements": [
		{ "destination": 0, "velocity": Vector2(0, -Q2_ROOKS_SPEED) },
		{ "destination": 7, "velocity": Vector2(Q2_ROOKS_SPEED, 0) },
		{ "destination": 3, "velocity": Vector2(0, Q2_ROOKS_SPEED) },
		{ "destination": 4, "velocity": Vector2(-Q2_ROOKS_SPEED, 0) }
	]}, true)
	spawn_piece_illuminating_space(
		Globals.SimpleBulletTypes.ROOK, Vector2(4, 3),
		illuminate_to_spawn_delay, q2_rook_a_params
	)
	var q2_rook_b_params: Dictionary = piece_params.duplicate()
	q2_rook_b_params.merge({"allowed_movements": [
		{ "destination": 7, "velocity": Vector2(Q2_ROOKS_SPEED, 0) },
		{ "destination": 3, "velocity": Vector2(0, Q2_ROOKS_SPEED) },
		{ "destination": 4, "velocity": Vector2(-Q2_ROOKS_SPEED, 0) },
		{ "destination": 0, "velocity": Vector2(0, -Q2_ROOKS_SPEED) }
	]}, true)
	spawn_piece_illuminating_space(
		Globals.SimpleBulletTypes.ROOK, Vector2(4, 0), 
		illuminate_to_spawn_delay, q2_rook_b_params
	)
	var q2_rook_c_params: Dictionary = piece_params.duplicate()
	q2_rook_c_params.merge({"allowed_movements": [
		{ "destination": 3, "velocity": Vector2(0, Q2_ROOKS_SPEED) },
		{ "destination": 4, "velocity": Vector2(-Q2_ROOKS_SPEED, 0) },
		{ "destination": 0, "velocity": Vector2(0, -Q2_ROOKS_SPEED) },
		{ "destination": 7, "velocity": Vector2(Q2_ROOKS_SPEED, 0) }
	]}, true)
	spawn_piece_illuminating_space(
		Globals.SimpleBulletTypes.ROOK, Vector2(7, 0),
		illuminate_to_spawn_delay, q2_rook_c_params
	)
	var q2_rook_d_params: Dictionary = piece_params.duplicate()
	q2_rook_d_params.merge({"allowed_movements": [
		{ "destination": 4, "velocity": Vector2(-Q2_ROOKS_SPEED, 0) },
		{ "destination": 0, "velocity": Vector2(0, -Q2_ROOKS_SPEED) },
		{ "destination": 7, "velocity": Vector2(Q2_ROOKS_SPEED, 0) },
		{ "destination": 3, "velocity": Vector2(0, Q2_ROOKS_SPEED) }
	]}, true)
	spawn_piece_illuminating_space(
		Globals.SimpleBulletTypes.ROOK, Vector2(7, 3),
		illuminate_to_spawn_delay, q2_rook_d_params
	)

	var q3_rook_a_params: Dictionary = piece_params.duplicate()
	q3_rook_a_params.merge({"allowed_movements": [
		{ "destination": 0, "velocity": Vector2(-piece_params.speed, 0) },
		{ "destination": 7, "velocity": Vector2(0, piece_params.speed) },
		{ "destination": 3, "velocity": Vector2(piece_params.speed, 0) },
		{ "destination": 4, "velocity": Vector2(0, -piece_params.speed) }
	]}, true)
	spawn_piece_illuminating_space(
		Globals.SimpleBulletTypes.ROOK, Vector2(3, 4),
		illuminate_to_spawn_delay, q3_rook_a_params
	)
	var q3_rook_b_params: Dictionary = piece_params.duplicate()
	q3_rook_b_params.merge({"allowed_movements": [
		{ "destination": 7, "velocity": Vector2(0, piece_params.speed) },
		{ "destination": 3, "velocity": Vector2(piece_params.speed, 0) },
		{ "destination": 4, "velocity": Vector2(0, -piece_params.speed) },
		{ "destination": 0, "velocity": Vector2(-piece_params.speed, 0) }
	]}, true)
	spawn_piece_illuminating_space(
		Globals.SimpleBulletTypes.ROOK, Vector2(0, 4),
		illuminate_to_spawn_delay, q3_rook_b_params
	)
	var q3_rook_c_params: Dictionary = piece_params.duplicate()
	q3_rook_c_params.merge({"allowed_movements": [
		{ "destination": 4, "velocity": Vector2(0, -piece_params.speed) },
		{ "destination": 0, "velocity": Vector2(-piece_params.speed, 0) },
		{ "destination": 7, "velocity": Vector2(0, piece_params.speed) },
		{ "destination": 3, "velocity": Vector2(piece_params.speed, 0) }
	]}, true)
	spawn_piece_illuminating_space(
		Globals.SimpleBulletTypes.ROOK, Vector2(3, 7),
		illuminate_to_spawn_delay, q3_rook_c_params
	)

	var Q4_ROOKS_SPEED: int = piece_params.speed + 150
	var q4_rook_params: Dictionary = piece_params.duplicate()
	q4_rook_params.merge({"allowed_movements": [
		{ "destination": 4, "velocity": Vector2(0, -Q4_ROOKS_SPEED) },
		{ "destination": 4, "velocity": Vector2(-Q4_ROOKS_SPEED, 0) },
		{ "destination": 7, "velocity": Vector2(0, Q4_ROOKS_SPEED) },
		{ "destination": 7, "velocity": Vector2(Q4_ROOKS_SPEED, 0) }
	]}, true)
	spawn_piece_illuminating_space(
		Globals.SimpleBulletTypes.ROOK, Vector2(7, 7),
		illuminate_to_spawn_delay, q4_rook_params
	)

func caro_kann_hidden_offense(piece_params: Dictionary) -> void:
	var spawn_position: Vector2 
	var current_attack_id: int = current_attack
	while continue_attacking:
		if current_attack_id != current_attack:
			break

		for i in range(piece_params.N_OF_PAWNS):
			spawn_position = select_spawn_space(i % 2 == 0)

			spawn_piece(
				Globals.SimpleBulletTypes.PAWN, spawn_position,
				piece_params.get(Globals.SimpleBulletTypes.PAWN),
				true
			)

		main_attack_timer_start(piece_params.TIME_BETWEEN_ATTACKS)
		yield(main_attack_timer, "timeout")
		emit_signal("clear_used_board_space_spawners")

func gellers_hidden_rooks(piece_params: Dictionary) -> void:
	var r1_rook_params: Dictionary = piece_params.duplicate()
	r1_rook_params.merge({"allowed_movements": [
		{ "destination": 7, "velocity": Vector2(piece_params.speed, 0) },
		{ "destination": 0, "velocity": Vector2(-(piece_params.speed), 0) }
	]}, true)
	spawn_piece(
		Globals.SimpleBulletTypes.ROOK, Vector2(0, 1), r1_rook_params, true
	)

	var R2_ROOK_SPEED: int = piece_params.speed + 25
	var r2_rook_params: Dictionary = piece_params.duplicate()
	r2_rook_params.merge({"allowed_movements": [
		{ "destination": 0, "velocity": Vector2(-R2_ROOK_SPEED, 0) },
		{ "destination": 7, "velocity": Vector2(R2_ROOK_SPEED, 0) }
	]}, true)
	spawn_piece(
		Globals.SimpleBulletTypes.ROOK, Vector2(7, 2), r2_rook_params, true
	)

	var R5_ROOK_SPEED: int = piece_params.speed - 35
	var r5_rook_params: Dictionary = piece_params.duplicate()
	r5_rook_params.merge({"allowed_movements": [
		{ "destination": 7, "velocity": Vector2(R5_ROOK_SPEED, 0) },
		{ "destination": 0, "velocity": Vector2(-R5_ROOK_SPEED, 0) }
	]}, true)
	spawn_piece(
		Globals.SimpleBulletTypes.ROOK, Vector2(0, 5), r5_rook_params, true
	)

	var r6_rook_params: Dictionary = piece_params.duplicate()
	r6_rook_params.merge({"allowed_movements": [
		{ "destination": 0, "velocity": Vector2(-piece_params.speed, 0) },
		{ "destination": 7, "velocity": Vector2(piece_params.speed, 0) }
	]}, true)
	spawn_piece(
		Globals.SimpleBulletTypes.ROOK, Vector2(7, 6), r6_rook_params, true
	)

	yield(get_tree().create_timer(5), "timeout")

	get_parent().manage_spawner_space_by_index(1, 0, false)
	get_parent().manage_spawner_space_by_index(5, 0, false)
	get_parent().manage_spawner_space_by_index(2, 7, false)
	get_parent().manage_spawner_space_by_index(6, 7, false)

func queens_stealthy_gambit(piece_params: Dictionary) -> void:
	# Timer so the board spaces actually illuminate properly
	yield(get_tree().create_timer(1.5), "timeout")

	spawn_piece_illuminating_space(
		Globals.SimpleBulletTypes.QUEEN, Vector2.ZERO,
		piece_params.ILLUMINATE_TO_SPAWN_DELAY, piece_params.QUEEN_A
	)
	spawn_piece_illuminating_space(
		Globals.SimpleBulletTypes.QUEEN, Vector2(7, 7),
		piece_params.ILLUMINATE_TO_SPAWN_DELAY, piece_params.QUEEN_B
	)

func hide_queens(_piece_params: Dictionary) -> void:
	for queen_id in current_queen_id_list: 
		var queen_piece = instance_from_id(queen_id)
		queen_piece.get_node("shows_in_dark").visible = false
		queen_piece.get_node("hides_in_dark").visible = true 

func absolute_darkness(_piece_params: Dictionary) -> void:
	for queen_id in current_queen_id_list: 
		var queen_piece = instance_from_id(queen_id)
		queen_piece.get_node("shows_in_dark").visible = true 
		queen_piece.get_node("hides_in_dark").visible = false 
	PlayerManager.manage_player_light(false)

func _pawn_explode(pawn_params: Dictionary, attack_params: Dictionary) -> void:
	var vertical_rook_params: Dictionary = attack_params.get(
		Globals.SimpleBulletTypes.ROOK, {}
	).duplicate()

	# One of these two could be unset, so we use get() to avoid exceptions
	vertical_rook_params.vertical_movement = pawn_params.get(
		"vertical_movement", false
	)
	vertical_rook_params.horizontal_movement = pawn_params.get(
		"horizontal_movement", false
	)

	vertical_rook_params.is_player_below = pawn_params.is_player_below
	vertical_rook_params.is_player_above = pawn_params.is_player_above
	vertical_rook_params.is_player_left = pawn_params.is_player_left
	vertical_rook_params.is_player_right = pawn_params.is_player_right
	spawn_piece(
		Globals.SimpleBulletTypes.ROOK,
		pawn_params.current_position,
		vertical_rook_params
	)

	var left_bishop_params: Dictionary = attack_params.get(
		Globals.SimpleBulletTypes.BISHOP, {}
	).duplicate()
	left_bishop_params.is_player_below = (
		pawn_params.is_player_below or pawn_params.is_player_left
	)
	left_bishop_params.is_player_above = (
		pawn_params.is_player_above or pawn_params.is_player_right
	)
	left_bishop_params.is_player_left = (
		pawn_params.is_player_below or pawn_params.is_player_left
	)
	left_bishop_params.is_player_right = (
		pawn_params.is_player_above or pawn_params.is_player_right
	)
	spawn_piece(
		Globals.SimpleBulletTypes.BISHOP,
		pawn_params.current_position,
		left_bishop_params
	)

	var right_bishop_params: Dictionary = attack_params.get(
		Globals.SimpleBulletTypes.BISHOP, {}
	).duplicate()
	right_bishop_params.is_player_below = (
		pawn_params.is_player_below or pawn_params.is_player_right
	)
	right_bishop_params.is_player_above = (
		pawn_params.is_player_above or pawn_params.is_player_left
	)
	right_bishop_params.is_player_left = (
		pawn_params.is_player_above or pawn_params.is_player_left
	)
	right_bishop_params.is_player_right = (
		pawn_params.is_player_below or pawn_params.is_player_right
	)
	spawn_piece(
		Globals.SimpleBulletTypes.BISHOP,
		pawn_params.current_position,
		right_bishop_params
	)

func setup_attack_constants() -> void:
	.setup_attack_constants()
	attack_params['caro_kann_greater_offense'] = {
		Globals.SimpleBulletTypes.PAWN: {
			"vertical_movement": true,
			"is_player_below": true,
			"has_direction": true,
			"speed": PAWN_BASE_SPEED,
			"wait_time": 0.5,
			"can_be_health": false,
			"max_number_of_movements": 3,
			"on_movements_consumed": "_pawn_explode",
			"on_movements_consumed_params": {
				Globals.SimpleBulletTypes.ROOK: {
					"has_direction": true,
					"speed": ROOK_BASE_SPEED + 50,
					"wait_time": 0.5,
					"max_number_of_movements": 1,
				},
				Globals.SimpleBulletTypes.BISHOP: {
					"is_player_below": true,
					"has_direction": true,
					"speed": BISHOP_BASE_SPEED + 50,
					"wait_time": 0.5,
					"max_number_of_movements": 1,
				},
			},
		},
		TIME_BETWEEN_ATTACKS = 4,
	}
	attack_params['shirovs_bishop_abuse'] = {
		Globals.SimpleBulletTypes.BISHOP: {
			"zigzag": true,
			"go_up": true,
			"direction": Vector2(-1, -1),
			"has_direction": true,
			"speed": BISHOP_BASE_SPEED + 75,
			"wait_time": 0.2,
		},
		ILLUMINATE_TO_SPAWN_DELAY = 0.8,
		TIME_BETWEEN_ATTACKS = 1,
	}
	attack_params['gellers_improved_rooks'] = {
		N_OF_ROOKS = 1,
		Globals.SimpleBulletTypes.ROOK: {
			"spiral": true,
			"has_direction": true,
			"speed": ROOK_BASE_SPEED + 100,
			"wait_time": 0.25,
			"initial_wait_time": 1,
		},
		TIME_BETWEEN_ATTACKS = 4,
	}
	attack_params['parkovs_piece_hell'] = {
		TIME_BETWEEN_ATTACKS = 1.25,
		ILLUMINATE_TO_SPAWN_DELAY = 0.75,
		Globals.SimpleBulletTypes.PAWN: {
			"actual_piece_type": Globals.SimpleBulletTypes.PAWN,
			"speed": PAWN_BASE_SPEED + 50,
			"wait_time": 0.25,
			"initial_wait_time": 0.75,
		},
		(Globals.SimpleBulletTypes.PAWN + "_ex"): {
			"actual_piece_type": Globals.SimpleBulletTypes.PAWN,
			"speed": PAWN_BASE_SPEED + 25,
			"wait_time": 0.25,
			"initial_wait_time": 0.75,
			"max_number_of_movements": 3,
			"on_movements_consumed": "_pawn_explode",
			"on_movements_consumed_params": {
				Globals.SimpleBulletTypes.ROOK: {
					"has_direction": true,
					"speed": ROOK_BASE_SPEED + 50,
					"wait_time": 0.5,
					"max_number_of_movements": 1,
				},
				Globals.SimpleBulletTypes.BISHOP: {
					"has_direction": true,
					"speed": BISHOP_BASE_SPEED + 50,
					"wait_time": 0.5,
					"max_number_of_movements": 1,
				},
			},
		},
		Globals.SimpleBulletTypes.BISHOP: {
			"actual_piece_type": Globals.SimpleBulletTypes.BISHOP,
			"speed": BISHOP_BASE_SPEED + 125,
			"wait_time": 0.25,
			"initial_wait_time": 0.75,
			"max_number_of_movements": 1,
		},
		(Globals.SimpleBulletTypes.BISHOP + "_ex"): {
			"actual_piece_type": Globals.SimpleBulletTypes.BISHOP,
			"zigzag": true,
			"speed": BISHOP_BASE_SPEED + 100,
			"wait_time": 0.25,
			"initial_wait_time": 0.75,
		},
		Globals.SimpleBulletTypes.ROOK: {
			"actual_piece_type": Globals.SimpleBulletTypes.ROOK,
			"speed": ROOK_BASE_SPEED + 125,
			"wait_time": 0.25,
			"initial_wait_time": 0.75,
			"max_number_of_movements": 1,
		},
	}
	attack_params['gellers_rook_dance'] = {
		"speed": ROOK_BASE_SPEED,
		"wait_time": 0,
		"initial_wait_time": 1.25,
		"remove_bullet_on_hit": false,
		"can_be_health": false,
		"has_direction": true,
		"current_movement": 0,
		ILLUMINATE_TO_SPAWN_DELAY = 1,
	}
	attack_params['caro_kann_hidden_offense'] = {
		Globals.SimpleBulletTypes.PAWN: {
			"horizontal_movement": true,
			"is_player_left": true,
			"has_direction": true,
			"speed": PAWN_BASE_SPEED,
			"wait_time": 0.25,
		},
		TIME_BETWEEN_ATTACKS = 2,
		N_OF_PAWNS = 2,
	}
	attack_params['gellers_hidden_rooks'] = {
		"has_direction": true,
		"current_movement": 0,
		"speed": ROOK_BASE_SPEED + 100,
		"wait_time": 0.5,
		"initial_wait_time": 1.25,
		"remove_bullet_on_hit": false,
		"can_be_health": false,
	}
	attack_params['queens_stealthy_gambit'] = {
		ILLUMINATE_TO_SPAWN_DELAY = 1,
		"QUEEN_A": {
			"speed": QUEEN_BASE_SPEED + 25,
			"wait_time": 3,
			"remove_bullet_on_hit": false,
		},
		"QUEEN_B": {
			"speed": QUEEN_BASE_SPEED - 45,
			"wait_time": 1,
			"remove_bullet_on_hit": false,
		}
	}
	attack_params['hide_queens'] = {}
	attack_params['absolute_darkness'] = {}

func _update_board(boss_phase: int = 1) -> void:
	._update_board(boss_phase)
	if Utils.is_difficulty_hard():
		if boss_phase == 1:
			get_parent().manage_spawner_spaces_row(0, true)
			get_parent().disable_powerup_spawning_spaces()
			get_parent().enable_powerup_spawning_spaces({
				5: [2, 3, 4, 5],
				6: [2, 3, 4, 5],
			})
		if boss_phase == 2:
			get_parent().make_all_board_spaces_safe()
			get_parent().disable_powerup_spawning_spaces()
			get_parent().enable_powerup_spawning_spaces({
				3: [1, 2, 3, 4, 5, 6],
				4: [1, 2, 3, 4, 5, 6],
			})
		if boss_phase == 3:
			get_parent().make_all_board_spaces_safe()
			get_parent().manage_spawner_space_by_index(0, 0, true)
			get_parent().disable_powerup_spawning_spaces()
			get_parent().enable_powerup_spawning_spaces({
				2: [0, 1, 6, 7],
				3: [0, 1, 6, 7],
				4: [0, 1, 6, 7],
				5: [0, 1, 6, 7],
			})
		if boss_phase == 4:
			get_parent().make_all_board_spaces_safe()
			get_parent().disable_powerup_spawning_spaces()
			get_parent().enable_powerup_spawning_spaces({
				0: [0, 1, 2, 3, 4, 5, 6, 7],
				1: [0, 1, 2, 3, 4, 5, 6, 7],
				2: [0, 1, 2, 3, 4, 5, 6, 7],
				3: [0, 1, 2, 3, 4, 5, 6, 7],
				4: [0, 1, 2, 3, 4, 5, 6, 7],
				5: [0, 1, 2, 3, 4, 5, 6, 7],
				6: [0, 1, 2, 3, 4, 5, 6, 7],
				7: [0, 1, 2, 3, 4, 5, 6, 7],
			})
		if boss_phase == 5:
			get_parent().make_all_board_spaces_safe()
			get_parent().manage_spawner_space_by_index(0, 0, true)
			get_parent().manage_spawner_space_by_index(3, 4, true)
			get_parent().manage_spawner_space_by_index(4, 3, true)
			get_parent().manage_spawner_space_by_index(7, 7, true)
			get_parent().disable_powerup_spawning_spaces()
			get_parent().enable_powerup_spawning_spaces({
				1: [1, 2, 5, 6],
				2: [1, 2, 5, 6],
				5: [1, 2, 5, 6],
				6: [1, 2, 5, 6],
			})
		if boss_phase == 6:
			get_parent().make_all_board_spaces_safe()
			get_parent().manage_spawner_spaces_column(7, true)
			get_parent().disable_powerup_spawning_spaces()
			get_parent().enable_powerup_spawning_spaces({
				1: [1, 2],
				2: [1, 2],
				3: [1, 2],
				4: [1, 2],
				5: [1, 2],
				6: [1, 2],
			})
		if boss_phase == 7:
			get_parent().arena_light.visible = true
			get_parent().make_all_board_spaces_safe()
			get_parent().manage_spawner_space_by_index(1, 0, true)
			get_parent().manage_spawner_space_by_index(2, 7, true)
			get_parent().manage_spawner_space_by_index(5, 0, true)
			get_parent().manage_spawner_space_by_index(6, 7, true)

			get_parent().disable_powerup_spawning_spaces()
			get_parent().enable_powerup_spawning_spaces({
				0: [3],
				7: [4],
			})

			get_parent().remove_board_space(0, 0)
			get_parent().remove_board_space(0, 1)
			get_parent().remove_board_space(0, 2)
			get_parent().remove_board_space(0, 4)
			get_parent().remove_board_space(0, 5)
			get_parent().remove_board_space(0, 6)
			get_parent().remove_board_space(0, 7)
			get_parent().remove_board_space(7, 0)
			get_parent().remove_board_space(7, 1)
			get_parent().remove_board_space(7, 2)
			get_parent().remove_board_space(7, 3)
			get_parent().remove_board_space(7, 5)
			get_parent().remove_board_space(7, 6)
			get_parent().remove_board_space(7, 7)

			for _i in range(14):
				yield(get_parent(), "board_modified")

			get_parent().arena_light.visible = false
		if boss_phase == 8:
			get_parent().enable_all_board_spaces()
			get_parent().make_all_board_spaces_safe()
		if boss_phase == 9:
			get_parent().make_all_board_spaces_safe()
			get_parent().disable_powerup_spawning_spaces()
			get_parent().enable_powerup_spawning_spaces({
				0: [0, 1, 2, 3, 4, 5, 6, 7],
				1: [0, 1, 2, 3, 4, 5, 6, 7],
				2: [0, 1, 2, 3, 4, 5, 6, 7],
				3: [0, 1, 2, 3, 4, 5, 6, 7],
				4: [0, 1, 2, 3, 4, 5, 6, 7],
				5: [0, 1, 2, 3, 4, 5, 6, 7],
				6: [0, 1, 2, 3, 4, 5, 6, 7],
				7: [0, 1, 2, 3, 4, 5, 6, 7],
			})
		if boss_phase == 10:
			get_parent().make_all_board_spaces_safe()

