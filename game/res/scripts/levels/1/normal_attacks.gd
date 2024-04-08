# Class to manage the normal attacks of Parkov
extends "res://juegodetriangulos/res/scripts/levels/1/pieces_management.gd"


var current_queen_id_list: Array = []


func change_boss_phase(new_boss_phase):
	if Utils.is_difficulty_normal():
		continue_attacking = false
		SimpleBulletManager.despawn_active_bullets_by_type_list([
		  Globals.SimpleBulletTypes.PAWN,
		  Globals.SimpleBulletTypes.ROOK,
		  Globals.SimpleBulletTypes.BISHOP,
		])
		yield(SimpleBulletManager, "bullets_despawned_by_type_list")

		emit_signal("clear_used_board_space_spawners")

	.change_boss_phase(new_boss_phase)


func caro_kann_offense(attack_params: Dictionary) -> void:
	var spawn_position: Vector2 
	var current_attack_id: int = current_attack
	while continue_attacking:
		if current_attack_id != current_attack:
			break

		for i in range(attack_params.N_OF_PAWNS):
			spawn_position = select_spawn_space(i % 2 == 0)

			spawn_piece(
				Globals.SimpleBulletTypes.PAWN, spawn_position,
				attack_params.get(Globals.SimpleBulletTypes.PAWN)
			)

		main_attack_timer_start(attack_params.TIME_BETWEEN_ATTACKS)
		yield(main_attack_timer, "timeout")
		emit_signal("clear_used_board_space_spawners")

func gellers_rook_and_pawn(attack_params: Dictionary) -> void:
	var current_column: int = 0
	var column_increment: int = 1
	var column: int = -1
	secondary_attack_thread.start(
		self, attack_params.SECONDARY_ATTACK, attack_params.PAWN_ATTACK_PARAMS
	)
	var current_attack_id: int = current_attack
	while continue_attacking:
		column = current_column
		spawn_piece_illuminating_space(
			Globals.SimpleBulletTypes.ROOK, Vector2(column, 7),
			attack_params.ILLUMINATE_TO_SPAWN_DELAY,
			attack_params.get(Globals.SimpleBulletTypes.ROOK)
		)

		main_attack_timer_start(attack_params.TIME_BETWEEN_ATTACKS)
		yield(main_attack_timer, "timeout")
		current_column += column_increment
		if current_column in [0, 7]:
			column_increment *= -1
		if current_attack_id != current_attack:
			break

func shirovs_bishops(attack_params: Dictionary) -> void:
	var column_increment: int = 0
	var row_increment: int = 0
	var current_attack_id: int = current_attack
	var spawn_position: Dictionary
	while continue_attacking:
		spawn_piece_illuminating_space(
			Globals.SimpleBulletTypes.BISHOP,
			Vector2(column_increment, row_increment),
			attack_params.ILLUMINATE_TO_SPAWN_DELAY,
			attack_params.get(Globals.SimpleBulletTypes.BISHOP)
		)

		spawn_piece_illuminating_space(
			Globals.SimpleBulletTypes.BISHOP,
			Vector2(7 - row_increment, column_increment),
			attack_params.ILLUMINATE_TO_SPAWN_DELAY,
			attack_params.get(Globals.SimpleBulletTypes.BISHOP)
		)

		main_attack_timer_start(attack_params.TIME_BETWEEN_ATTACKS)
		yield(main_attack_timer, "timeout")

		if column_increment < 7 and row_increment == 0:
			column_increment += 1
		elif column_increment == 7 and row_increment < 7:
			row_increment += 1
		elif column_increment > 0 and row_increment == 7:
			column_increment -= 1
		elif column_increment == 0 and row_increment > 0:
			row_increment -= 1

		if current_attack_id != current_attack:
			break

func queens_gambit(attack_params: Dictionary) -> void:
	spawn_piece_illuminating_space(
		Globals.SimpleBulletTypes.QUEEN, Vector2.ZERO,
		attack_params.ILLUMINATE_TO_SPAWN_DELAY, attack_params
	)

func queens_defense(attack_params: Dictionary) -> void:
	var current_attack_id: int = current_attack
	var current_iteration: int = 0
	var VALID_POSITIONS_LIST: Array = [
		Vector2(3, 3),
		Vector2(4, 3),
		Vector2(4, 4),
		Vector2(3, 4),
	]
	var DIRECTIONS_BY_POSITION: Array = [{
		"vertical_movement": true,
		"is_player_above": true,
		"has_direction": true
	}, {
		"vertical_movement": false,
		"is_player_right": true,
		"has_direction": true
	}, {
		"vertical_movement": true,
		"is_player_below": true,
		"has_direction": true
	}, {
		"vertical_movement": false,
		"is_player_left": true,
		"has_direction": true
	}]
	var additional_params: Dictionary
	while continue_attacking:

		additional_params = attack_params.get(
			Globals.SimpleBulletTypes.ROOK
		).duplicate()

		additional_params.merge(
			DIRECTIONS_BY_POSITION[current_iteration % 4], true
		)

		spawn_piece(
			Globals.SimpleBulletTypes.ROOK,
			VALID_POSITIONS_LIST[current_iteration % 4],
			additional_params
		)

		main_attack_timer_start(attack_params.TIME_BETWEEN_ATTACKS)
		yield(main_attack_timer, "timeout")
		if current_attack_id != current_attack:
			break
		current_iteration += 1

func queens_full_defense(attack_params: Dictionary) -> void:
	var current_attack_id: int = current_attack
	var current_iteration: int = 0
	var PIECE_TYPE_LIST: Array = [
		Globals.SimpleBulletTypes.ROOK,
		Globals.SimpleBulletTypes.BISHOP,
	]
	var current_piece_type: String
	var top_left_piece_params: Dictionary
	var top_right_piece_params: Dictionary
	var bottom_left_piece_params: Dictionary
	var bottom_right_piece_params: Dictionary
	while continue_attacking:
		current_piece_type = PIECE_TYPE_LIST[current_iteration % 2]

		top_left_piece_params = attack_params.get(current_piece_type, {}).duplicate()
		top_left_piece_params.merge({
			"vertical_movement": true,
			"is_player_above": true,
			"is_player_left": true,
			"has_direction": true
		})
		spawn_piece(current_piece_type, Vector2(3, 3), top_left_piece_params)

		top_right_piece_params = attack_params.get(current_piece_type, {}).duplicate()
		top_right_piece_params.merge({
			"vertical_movement": false,
			"is_player_above": true,
			"is_player_right": true,
			"has_direction": true
		})
		spawn_piece(current_piece_type, Vector2(4, 3), top_right_piece_params)

		bottom_right_piece_params = attack_params.get(current_piece_type, {}).duplicate()
		bottom_right_piece_params.merge({
			"vertical_movement": true,
			"is_player_below": true,
			"is_player_right": true,
			"has_direction": true
		})
		spawn_piece(current_piece_type, Vector2(4, 4), bottom_right_piece_params)

		bottom_left_piece_params = attack_params.get(current_piece_type, {}).duplicate()
		bottom_left_piece_params.merge({
			"vertical_movement": false,
			"is_player_below": true,
			"is_player_left": true,
			"has_direction": true
		})
		spawn_piece(current_piece_type, Vector2(3, 4), bottom_left_piece_params)

		main_attack_timer_start(attack_params.TIME_BETWEEN_ATTACKS)
		yield(main_attack_timer, "timeout")
		if current_attack_id != current_attack:
			break
		current_iteration += 1

func queens_rooks(attack_params: Dictionary) -> void:
	var top_left_rook_params: Dictionary = attack_params.duplicate()
	var top_right_rook_params: Dictionary = attack_params.duplicate()
	var bottom_left_rook_params: Dictionary = attack_params.duplicate()
	var bottom_right_rook_params: Dictionary = attack_params.duplicate()

	top_left_rook_params.merge({
		"horizontal_movement": true,
		"has_direction": true,
		"current_movement": 0,
		"allowed_movements": [{
			"destination": 7,
			"velocity": Vector2(attack_params.speed, 0)
		}, {
			"destination": 0,
			"velocity": Vector2(-attack_params.speed, 0)
		}],
	}, true)
	spawn_piece(
		Globals.SimpleBulletTypes.ROOK, Vector2.ZERO, top_left_rook_params
	)

	top_right_rook_params.merge({
		"vertical_movement": true,
		"has_direction": true,
		"current_movement": 0,
		"allowed_movements": [{
			"destination": 7,
			"velocity": Vector2(0, attack_params.speed)
		}, {
			"destination": 0,
			"velocity": Vector2(0, -attack_params.speed)
		}],
	}, true)
	spawn_piece(
		Globals.SimpleBulletTypes.ROOK, Vector2(7, 0), top_right_rook_params
	)

	bottom_right_rook_params.merge({
		"vertical_movement": true,
		"has_direction": true,
		"current_movement": 0,
		"allowed_movements": [{
			"destination": 0,
			"velocity": Vector2(-attack_params.speed, 0)
		}, {
			"destination": 7,
			"velocity": Vector2(attack_params.speed, 0)
		}],
	}, true)
	spawn_piece(
		Globals.SimpleBulletTypes.ROOK, Vector2(7, 7), bottom_right_rook_params
	)

	bottom_left_rook_params.merge({
		"horizontal_movement": true,
		"has_direction": true,
		"current_movement": 0,
		"allowed_movements": [{
			"destination": 0,
			"velocity": Vector2(0, -attack_params.speed)
		}, {
			"destination": 7,
			"velocity": Vector2(0, attack_params.speed)
		}],
	}, true)
	spawn_piece(
		Globals.SimpleBulletTypes.ROOK, Vector2(0, 7), bottom_left_rook_params
	)

func enrage_queen(attack_params: Dictionary) -> void:
	spawn_piece_illuminating_space(
		Globals.SimpleBulletTypes.QUEEN, Vector2.ZERO,
		attack_params.ILLUMINATE_TO_SPAWN_DELAY, attack_params
	)

func queens_ire(attack_params: Dictionary) -> void:
	pass

func queens_fury(attack_params: Dictionary) -> void:
	var c = 0
	for queen_id in current_queen_id_list:
		SimpleBulletManager.update_bullet_params_dict(queen_id, attack_params.get(c))
		c += 1

func spawn_piece_illuminating_space(
	piece_type: String, spawn_position: Vector2,
	illuminate_to_spawn_delay: float,
	additional_piece_params: Dictionary = {},
	hides_in_dark: bool = false, invert_colors: bool = false
) -> int:
	get_parent().manage_spawner_space_by_index(spawn_position.y, spawn_position.x, true)
	yield(get_tree().create_timer(illuminate_to_spawn_delay), "timeout")
	var piece_id: int = spawn_piece(
		piece_type, spawn_position,
		additional_piece_params,
		hides_in_dark, invert_colors
	)
	yield(get_tree().create_timer(illuminate_to_spawn_delay), "timeout")
	get_parent().manage_spawner_space_by_index(spawn_position.y, spawn_position.x, false)
	return piece_id

func spawn_piece(
	piece_type: String, spawn_position: Vector2,
	additional_piece_params: Dictionary = {},
	hides_in_dark: bool = false, invert_colors: bool = false
) -> int:
	var piece_id: int = -1
	var board_space = board_space_list[spawn_position.y][spawn_position.x]

	if board_space.enabled:
		SimpleBulletManager.update_screen_center_position()
		var piece_params: Dictionary = BASE_PIECE_DICTIONARY.duplicate()

		piece_params["global_position"] = board_space.global_position
		piece_params["current_position"] = spawn_position
		piece_params["next_position"] = spawn_position
		piece_params["piece_type"] = piece_type
		piece_params.merge(additional_piece_params, true)

		if PlayerManager.player_exists():
			if piece_type == Globals.SimpleBulletTypes.QUEEN:
				var current_queen_id: int = SimpleBulletManager.get_avaliable_bullet(
					piece_type, piece_params
				).get_instance_id()
				var queen_piece: Node2D = instance_from_id(current_queen_id)
				queen_piece.get_node("shows_in_dark").visible = not hides_in_dark
				queen_piece.get_node("hides_in_dark").visible = hides_in_dark
				SimpleBulletManager.shoot_bullet_by_id(current_queen_id, piece_type)
				current_queen_id_list.append(current_queen_id)
				piece_id = current_queen_id
			else:
				var current_piece_id: int = SimpleBulletManager.get_avaliable_bullet(
					piece_type, piece_params
				).get_instance_id()
				var current_piece: Node2D = instance_from_id(current_piece_id)
				current_piece.get_node("shows_in_dark").visible = not hides_in_dark
				current_piece.get_node("hides_in_dark").visible = hides_in_dark
				current_piece.get_node("shows_in_dark").material = (
					invert_shader if invert_colors else null
				)
				current_piece.get_node("hides_in_dark").material = (
					invert_shader if invert_colors else null
				)
				SimpleBulletManager.shoot_bullet_by_id(current_piece_id, piece_type)
				piece_id = current_piece_id

	return piece_id

# Generic function to spawn pawns in as a secondary attack
func secondary_piece_spawner(attack_params: Dictionary) -> void:
	var spawn_position: Vector2 
	var parent_attack_id: int = current_attack
	while continue_attacking:
		for _i in range(attack_params.N_OF_PIECES):
			match attack_params.get("SPAWN_STRATEGY", ""):

				"SET_POSITION": # The position is set in the attack_params dict
					spawn_position = attack_params.SPAWN_POSITION

				"COLUMN_ONLY": # The row is fixed, but we need to choose a column
					spawn_position = select_spawn_space_in_row(
						attack_params.SPAWN_ROW,
						attack_params.get("RANDOM_SPAWN", false)
					)

				"ROW_ONLY": # The column is fixed, but we need to choose a row 
					continue # To be implemented

				_: # Choose a spawn position using the function logic
					spawn_position = select_spawn_space(
						attack_params.get("RANDOM", false)
					)

			spawn_piece(
				attack_params.PIECE_TYPE, spawn_position,
				attack_params.get("ADDITIONAL_SPAWN_PARAMETERS", {})
			)

		secondary_attack_timer_start(attack_params.TIME_BETWEEN_ATTACKS)
		yield(secondary_attack_timer, "timeout")
		if parent_attack_id != current_attack:
			break
		emit_signal("clear_used_board_space_spawners")

func setup_attack_constants() -> void:
	.setup_attack_constants()
	attack_params['caro_kann_offense'] = {
		Globals.SimpleBulletTypes.PAWN: {
			"vertical_movement": true,
			"is_player_below": true,
			"has_direction": true,
			"speed": PAWN_BASE_SPEED,
			"wait_time": 0.7,
		},
		TIME_BETWEEN_ATTACKS = 2.8,
		N_OF_PAWNS = 3,
	}
	attack_params['gellers_rook_and_pawn'] = {
		Globals.SimpleBulletTypes.ROOK: {
			"vertical_movement": true,
			"is_player_above": true,
			"has_direction": true,
			"speed": ROOK_BASE_SPEED,
			"wait_time": 0.25,
			"max_number_of_movements": 1,
		},
		ILLUMINATE_TO_SPAWN_DELAY = 0.5,
		SECONDARY_ATTACK = "secondary_piece_spawner",
		PAWN_ATTACK_PARAMS = {
			N_OF_PIECES = 1,
			ADDITIONAL_SPAWN_PARAMETERS = {
				"vertical_movement": true,
				"is_player_below": true,
				"has_direction": true,
				"speed": PAWN_BASE_SPEED,
				"wait_time": 0.6,
			},
			RANDOM_SPAWN = true,
			SPAWN_STRATEGY = "COLUMN_ONLY",
			SPAWN_ROW = 0,
			PIECE_TYPE = Globals.SimpleBulletTypes.PAWN,
			TIME_BETWEEN_ATTACKS = 1.8,
		},
		TIME_BETWEEN_ATTACKS = 0.75,
	}
	attack_params['shirovs_bishops'] = {
		Globals.SimpleBulletTypes.BISHOP: {
			"speed": BISHOP_BASE_SPEED,
			"wait_time": 0.25,
			"max_number_of_movements": 1,
		},
		ILLUMINATE_TO_SPAWN_DELAY = 0.25,
		TIME_BETWEEN_ATTACKS = 1,
	}
	attack_params['queens_gambit'] = {
		"speed": QUEEN_BASE_SPEED - 30,
		"wait_time": 1,
		"remove_bullet_on_hit": false,
		ILLUMINATE_TO_SPAWN_DELAY = 0.5,
	}
	attack_params['queens_defense'] = {
		Globals.SimpleBulletTypes.ROOK: {
			"speed": ROOK_BASE_SPEED - 25,
			"wait_time": 1,
			"max_number_of_movements": 1,
		},
		TIME_BETWEEN_ATTACKS = 1,
	}
	attack_params['queens_full_defense'] = {
		Globals.SimpleBulletTypes.ROOK: {
			"speed": ROOK_BASE_SPEED - 25,
			"wait_time": 1.25,
			"max_number_of_movements": 1,
		},
		Globals.SimpleBulletTypes.BISHOP: {
			"speed": BISHOP_BASE_SPEED,
			"wait_time": 1.25,
			"max_number_of_movements": 1,
		},
		TIME_BETWEEN_ATTACKS = 2.5,
	}
	attack_params['queens_rooks'] = {
		"speed": ROOK_BASE_SPEED + 50,
		"wait_time": 0.3,
		"remove_bullet_on_hit": false,
		"can_be_health": false,
	}
	attack_params['enrage_queen'] = {
		"speed": QUEEN_BASE_SPEED - 15,
		"wait_time": 0.85,
		"remove_bullet_on_hit": false,
		ILLUMINATE_TO_SPAWN_DELAY = 0.5,
	}
	attack_params['queens_ire'] = { }
	attack_params['queens_fury'] = {
		0: {
			"speed": QUEEN_BASE_SPEED + 50,
			"wait_time": 1,
		},
		1: {
			"speed": QUEEN_BASE_SPEED - 50,
			"wait_time": 0.25,
		}
	}

func _update_board(boss_phase: int = 1) -> void:
	._update_board(boss_phase)
	if Utils.is_difficulty_normal():
		if boss_phase == 1:
			get_parent().manage_spawner_spaces_row(0, true)
			get_parent().enable_powerup_spawning_spaces({
				4: [0, 1, 2, 3, 4, 5, 6, 7],
				5: [0, 1, 2, 3, 4, 5, 6, 7],
				6: [0, 1, 2, 3, 4, 5, 6, 7],
			})
		if boss_phase == 2:
			get_parent().disable_powerup_spawning_spaces()
			get_parent().enable_powerup_spawning_spaces({
				3: [1, 2, 3, 4, 5, 6],
				4: [1, 2, 3, 4, 5, 6],
			})
		if boss_phase == 3:
			get_parent().make_all_board_spaces_safe()
			get_parent().disable_powerup_spawning_spaces()
			get_parent().enable_powerup_spawning_spaces({
				2: [2, 3, 4, 5],
				3: [2, 3, 4, 5],
				4: [2, 3, 4, 5],
				5: [2, 3, 4, 5],
			})
		if boss_phase == 4:
			get_parent().disable_powerup_spawning_spaces()
			get_parent().enable_powerup_spawning_spaces({
				0: [1, 2, 3, 4, 5, 6, 7],
				1: [0, 1, 2, 3, 4, 5, 6, 7],
				2: [0, 1, 2, 3, 4, 5, 6, 7],
				3: [0, 1, 6, 7],
				4: [0, 1, 6, 7],
				5: [0, 1, 2, 3, 4, 5, 6, 7],
				6: [0, 1, 2, 3, 4, 5, 6, 7],
				7: [0, 1, 2, 3, 4, 5, 6, 7],
			})
		if boss_phase == 5:
			get_parent().manage_spawner_space_by_index(3, 3, true)
			get_parent().manage_spawner_space_by_index(3, 4, true)
			get_parent().manage_spawner_space_by_index(4, 3, true)
			get_parent().manage_spawner_space_by_index(4, 4, true)
			get_parent().disable_powerup_spawning_spaces()
			get_parent().enable_powerup_spawning_spaces({
				0: [0, 1, 2, 4, 5, 6, 7],
				1: [0, 1, 2, 4, 5, 6, 7],
				2: [0, 1, 6, 7],
				3: [0, 1],
				4: [6, 7],
				5: [0, 1, 6, 7],
				6: [0, 1, 2, 3, 5, 6, 7],
				7: [0, 1, 2, 3, 5, 6, 7],
			})
		if boss_phase == 6:
			get_parent().disable_powerup_spawning_spaces()
			get_parent().enable_powerup_spawning_spaces({
				0: [1, 2, 4, 5, 6],
				1: [0, 2, 4, 5, 7],
				2: [0, 1, 6, 7],
				3: [0, 1],
				4: [6, 7],
				5: [0, 1, 6, 7],
				6: [0, 2, 3, 5, 7],
				7: [1, 2, 3, 5, 6],
			})
		if boss_phase == 7:
			get_parent().make_all_board_spaces_safe()
			get_parent().manage_spawner_space_by_index(0, 0, true)
			get_parent().manage_spawner_space_by_index(0, 7, true)
			get_parent().manage_spawner_space_by_index(7, 0, true)
			get_parent().manage_spawner_space_by_index(7, 7, true)
			get_parent().disable_powerup_spawning_spaces()
			get_parent().enable_powerup_spawning_spaces({
				0: [3, 4],
				3: [0, 7],
				4: [0, 7],
				7: [3, 4],
			})
		if boss_phase == 8:
			get_parent().make_all_board_spaces_safe()
			get_parent().enable_powerup_spawning_spaces({
				0: [1, 2, 3, 4, 5, 6],
				1: [1, 2, 3, 4, 5, 6],
				2: [1, 2, 3, 4, 5, 6],
				3: [1, 2, 3, 4, 5, 6],
				4: [1, 2, 3, 4, 5, 6],
				5: [1, 2, 3, 4, 5, 6],
				6: [1, 2, 3, 4, 5, 6],
				7: [1, 2, 3, 4, 5, 6],
			})
		if boss_phase == 9:
			get_parent().enable_powerup_spawning_spaces({
				1: [1, 2, 3, 4, 5, 6],
				2: [1, 2, 3, 4, 5, 6],
				3: [1, 2, 3, 4, 5, 6],
				4: [1, 2, 3, 4, 5, 6],
				5: [1, 2, 3, 4, 5, 6],
				6: [1, 2, 3, 4, 5, 6],
			})
			get_parent().remove_board_spaces_by_column([0, 7])
		if boss_phase == 10:
			get_parent().enable_powerup_spawning_spaces({
				2: [2, 3, 4, 5],
				3: [2, 3, 4, 5],
				4: [2, 3, 4, 5],
				5: [2, 3, 4, 5],
			})
			get_parent().remove_board_spaces_by_row([0, 7])

