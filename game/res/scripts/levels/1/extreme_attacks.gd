extends "res://juegodetriangulos/res/scripts/levels/1/hard_attacks.gd"

const TIME_UNTIL_NEXT_STAGE: int = 1
const MARKER_TIMING_LIST: Array = [35.0, 75.0, 125.0]

var current_attack_stage: int = 0
var big_plus_bishops: bool = false
var big_plus_hard_mode: bool = false
var towers_of_doom_list: Array = []

func _ready():
	hardest_mode_time_until_next_stage_timer.set_wait_time(TIME_UNTIL_NEXT_STAGE)

	# For this version of the boss, each stage is timed (i.e., it advances to
	# the next one automatically without the player needing to damage it).
	# This dictionary has, for each attack, a list of functions to call (the value)
	# and at which second to call that function (the key)
	hardest_mode_functions_to_call = {
		"pawn_field": {
			10: "pawn_field_begin", 
			20: "pawn_field_hidden", 
			30: "pawn_field_hide_player", 
			35: "pawn_field_end", 
		},
		"danger_line": {
			40: "danger_line_end",
		},
		"towers_of_doom": {
			20: "towers_of_doom_mix",
			30: "towers_of_doom_update_speed",
			50: "towers_of_doom_end",
		},
		"big_plus": {
			16: "big_plus_enable_bishops",
			30: "big_plus_enable_hard_mode",
			50: "big_plus_end",
		}
	}

func reset(reset_animations: bool = true) -> void:
	if Utils.is_difficulty_hardest():
		hardest_mode_time_until_next_stage_timer.stop()
		hardest_mode_current_fight_time = 0.0
		current_attack_stage = 0
		big_plus_bishops = false
		big_plus_hard_mode = false
		towers_of_doom_list = []
	.reset(reset_animations)

func _on_board_created() -> void:
	if Utils.is_difficulty_hardest():
		hardest_mode_time_until_next_stage_timer.start()
	._on_board_created()

func pawn_field(attack_params: Dictionary) -> void:
	spawn_piece(
		Globals.SimpleBulletTypes.QUEEN, Vector2.ZERO, attack_params.QUEEN_A
	)
	spawn_piece(
		Globals.SimpleBulletTypes.QUEEN, Vector2(7, 0), attack_params.QUEEN_B
	)

func pawn_field_begin(attack_params: Dictionary) -> void:
	var spawn_positions_list: Dictionary = {}
	var initial_row: int = [0, 1][randi()%2]
	for i in range(initial_row, 8, 2):
		spawn_positions_list[i] = [
			[0, 2, 4, 6],
			[1, 3, 5, 7],
		][randi()%2]

	get_parent().make_all_board_spaces_safe()
	for row in spawn_positions_list.keys():
		for column in spawn_positions_list[row]:
			get_parent().manage_spawner_space_by_index(row, column, true)

	yield(get_tree().create_timer(1), "timeout")

	for row in spawn_positions_list.keys():
		for column in spawn_positions_list[row]:
			spawn_piece(
				Globals.SimpleBulletTypes.PAWN, Vector2(column, row),
				attack_params.get(Globals.SimpleBulletTypes.PAWN), true
			)

func pawn_field_hidden(_attack_params: Dictionary) -> void:
	idle_animation.hide()
	special_animation.show()
	special_animation.play()
	yield(self, "special_animation_peak_reached")
	get_parent().make_all_board_spaces_safe()

func pawn_field_hide_player(_attack_params: Dictionary) -> void:
	idle_animation.hide()
	special_animation.show()
	special_animation.play()
	yield(self, "special_animation_peak_reached")
	PlayerManager.manage_player_light(false)

func pawn_field_end(_attack_params: Dictionary) -> void:
	continue_attacking = false
	get_parent().make_all_board_spaces_safe()
	SimpleBulletManager.despawn_active_bullets_by_type_list([
	  Globals.SimpleBulletTypes.PAWN,
	])
	yield(SimpleBulletManager, "bullets_despawned_by_type_list")
	SimpleBulletManager.despawn_active_bullets_by_type(
	  Globals.SimpleBulletTypes.QUEEN
	)
	yield(SimpleBulletManager, "bullets_despawned_by_type")
	change_boss_phase(current_boss_phase + 1)
	PlayerManager.get_player_node().light.visible = true

func danger_line(attack_params: Dictionary) -> void:
	var danger_line_column: int = 3
	var player_data: Node = PlayerManager.get_player_node()
	var is_player_right: bool = player_data.current_position.x > 3
	var current_attack_id: int = current_attack
	if is_player_right:
		get_parent().remove_board_spaces_by_column([0, 1, 2])
	else:
		get_parent().remove_board_spaces_by_column([5, 6, 7])
		danger_line_column = 4
	get_parent().manage_spawner_spaces_column(danger_line_column, true)
	yield(get_parent(), "board_modified")

	idle_animation.hide()
	special_animation.show()
	special_animation.play()
	yield(self, "special_animation_peak_reached")
	PlayerManager.get_player_node().light.visible = false

	var missing_piece_position: int = player_data.current_position.y
	var previous_missing_piece_position: int = missing_piece_position
	var piece_params: Dictionary = attack_params.get(
		Globals.SimpleBulletTypes.ROOK
	).duplicate()
	piece_params.merge({
		"has_direction": true,
		"vertical_movement": false,
		"horizontal_movement": true,
		"is_player_above": false,
		"is_player_below": false,
		"is_player_right": is_player_right,
		"is_player_left": not is_player_right,
	})

	for spawn_row in range(0, 8):
		if spawn_row != missing_piece_position:
			spawn_piece(
				Globals.SimpleBulletTypes.ROOK,
				Vector2(danger_line_column, spawn_row),
				piece_params 
			)

	while previous_missing_piece_position == missing_piece_position:
		missing_piece_position = clamp(
			missing_piece_position + (randi()%2+1) * [1, -1][randi()%2], 0, 7
		)
	previous_missing_piece_position = missing_piece_position

	main_attack_timer_start(attack_params.TIME_BETWEEN_ATTACKS + 1)
	yield(main_attack_timer, "timeout")

	piece_params.initial_wait_time = 0
	var current_attack_time: float = attack_params.TIME_BETWEEN_ATTACKS

	while hardest_mode_current_attack_stage < 15:
		for spawn_row in range(0, 8):
			if spawn_row != missing_piece_position:
				spawn_piece(
					Globals.SimpleBulletTypes.ROOK,
					Vector2(danger_line_column, spawn_row),
					piece_params
				)

		while previous_missing_piece_position == missing_piece_position:
			missing_piece_position = clamp(
				missing_piece_position + (randi()%2+1) * [1, -1][randi()%2], 0, 7
			)
		previous_missing_piece_position = missing_piece_position

		main_attack_timer_start(current_attack_time)
		yield(main_attack_timer, "timeout")

		current_attack_time = clamp(
			current_attack_time - 0.05, 1, current_attack_time
		)

	piece_params.initial_wait_time = 1

	for spawn_row in range(0, 8):
		if spawn_row != missing_piece_position:
			spawn_piece(
				Globals.SimpleBulletTypes.ROOK,
				Vector2(danger_line_column, spawn_row),
				piece_params
			)
		else:
			spawn_piece(
				Globals.SimpleBulletTypes.BISHOP,
				Vector2(danger_line_column, spawn_row),
				piece_params
			)

	while previous_missing_piece_position == missing_piece_position:
		missing_piece_position = clamp(
			missing_piece_position + (randi()%2+1) * [1, -1][randi()%2], 0, 7
		)
	previous_missing_piece_position = missing_piece_position
	main_attack_timer_start(2)
	yield(main_attack_timer, "timeout")

	piece_params.initial_wait_time = 0
	current_attack_time = attack_params.TIME_BETWEEN_ATTACKS - 0.3

	while hardest_mode_current_attack_stage < 40:
		for spawn_row in range(0, 8):
			if spawn_row != missing_piece_position:
				spawn_piece(
					Globals.SimpleBulletTypes.ROOK,
					Vector2(danger_line_column, spawn_row),
					piece_params
				)
			else:
				spawn_piece(
					Globals.SimpleBulletTypes.BISHOP,
					Vector2(danger_line_column, spawn_row),
					piece_params
				)

		while previous_missing_piece_position == missing_piece_position:
			missing_piece_position = clamp(
				missing_piece_position + (randi()%2+1) * [1, -1][randi()%2], 0, 7
			)
		previous_missing_piece_position = missing_piece_position
		main_attack_timer_start(current_attack_time)
		yield(main_attack_timer, "timeout")

		current_attack_time = clamp(
			current_attack_time - 0.05, 0.8, current_attack_time
		)

		if current_attack_id != current_attack:
			break
		

func danger_line_end(attack_params: Dictionary) -> void:
	continue_attacking = false
	PlayerManager.manage_player_light(true)
	SimpleBulletManager.despawn_active_bullets_by_type_list([
	  Globals.SimpleBulletTypes.ROOK,
	  Globals.SimpleBulletTypes.BISHOP,
	])
	yield(SimpleBulletManager, "bullets_despawned_by_type_list")
	get_parent().enable_all_board_spaces()

	yield(get_parent(), "board_space_enabled")

	get_parent().make_all_board_spaces_safe()
	change_boss_phase(current_boss_phase + 1)

func towers_of_doom(attack_params: Dictionary) -> void:
	get_parent().remove_board_spaces_by_row([0, 1, 6, 7])
	get_parent().remove_board_spaces_by_column([0, 1, 6, 7])

	yield(get_parent(), "board_modified")
	yield(get_parent(), "board_modified")

	get_parent().enable_board_space(0, 2)
	get_parent().enable_board_space(0, 3)
	get_parent().enable_board_space(0, 4)
	get_parent().enable_board_space(0, 5)
	get_parent().enable_board_space(7, 2)
	get_parent().enable_board_space(7, 3)
	get_parent().enable_board_space(7, 4)
	get_parent().enable_board_space(7, 5)

	for _i in range(8):
		yield(get_parent(), "board_space_enabled")

	get_parent().manage_spawner_spaces_row(0, true)
	get_parent().manage_spawner_spaces_row(7, true)

	var spawn_spaces_list: Dictionary = {
		"top": [2, 4],
		"bottom": [3, 5],
	}
	var top_row_rook_params: Dictionary = (
		attack_params.get(Globals.SimpleBulletTypes.ROOK).duplicate()
	)
	var bottom_row_rook_params: Dictionary = (
		attack_params.get(Globals.SimpleBulletTypes.ROOK).duplicate()
	)

	top_row_rook_params.merge({
		"vertical_movement": true,
		"allowed_movements": [{
			"destination": 7,
			"velocity": [
				Vector2(0, top_row_rook_params.speed),
				Vector2(0, top_row_rook_params.speed - 10),
				Vector2(0, top_row_rook_params.speed - 5),
				Vector2(0, top_row_rook_params.speed + 30),
				Vector2(0, top_row_rook_params.speed + 15),
			]
		}, {
			"destination": 0,
			"velocity": [
				Vector2(0, -top_row_rook_params.speed),
				Vector2(0, -top_row_rook_params.speed + 10),
				Vector2(0, -top_row_rook_params.speed + 5),
				Vector2(0, -top_row_rook_params.speed - 30),
				Vector2(0, -top_row_rook_params.speed - 15),
			]
		}],
	}, true)
	for column in spawn_spaces_list.top:
		towers_of_doom_list.append(spawn_piece(
			Globals.SimpleBulletTypes.ROOK,
			Vector2(column, 0), top_row_rook_params
		))

	bottom_row_rook_params.merge({
		"vertical_movement": true,
		"allowed_movements": [{
			"destination": 0,
			"velocity": [
				Vector2(0, -bottom_row_rook_params.speed),
				Vector2(0, -bottom_row_rook_params.speed + 40),
				Vector2(0, -bottom_row_rook_params.speed + 10),
				Vector2(0, -bottom_row_rook_params.speed - 10),
				Vector2(0, -bottom_row_rook_params.speed - 15),
			]
		}, {
			"destination": 7,
			"velocity": [
				Vector2(0, bottom_row_rook_params.speed),
				Vector2(0, bottom_row_rook_params.speed - 40),
				Vector2(0, bottom_row_rook_params.speed - 10),
				Vector2(0, bottom_row_rook_params.speed + 10),
				Vector2(0, bottom_row_rook_params.speed + 15),
			]
		}],
	}, true)
	for column in spawn_spaces_list.bottom:
		towers_of_doom_list.append(spawn_piece(
			Globals.SimpleBulletTypes.ROOK,
			Vector2(column, 7), bottom_row_rook_params
		))

func towers_of_doom_mix(attack_params: Dictionary) -> void:
	get_parent().enable_board_space(2, 0)
	get_parent().enable_board_space(3, 0)
	get_parent().enable_board_space(4, 0)
	get_parent().enable_board_space(5, 0)
	get_parent().enable_board_space(2, 7)
	get_parent().enable_board_space(3, 7)
	get_parent().enable_board_space(4, 7)
	get_parent().enable_board_space(5, 7)

	for _i in range(8):
		yield(get_parent(), "board_space_enabled")

	get_parent().manage_spawner_spaces_column(0, true)
	get_parent().manage_spawner_spaces_column(7, true)

	var spawn_spaces_list: Dictionary = {
		"left": [2, 4],
		"right": [3, 5],
	}
	var left_col_rook_params: Dictionary = (
		attack_params.get(Globals.SimpleBulletTypes.ROOK).duplicate()
	)
	var right_col_rook_params: Dictionary = (
		attack_params.get(Globals.SimpleBulletTypes.ROOK).duplicate()
	)

	left_col_rook_params.merge({
		"vertical_movement": false,
		"horizontal_movement": true,
		"allowed_movements": [{
			"destination": 7,
			"velocity": [
				Vector2(left_col_rook_params.speed, 0),
				Vector2(left_col_rook_params.speed + 5, 0),
				Vector2(left_col_rook_params.speed - 20, 0),
				Vector2(left_col_rook_params.speed + 25, 0),
				Vector2(left_col_rook_params.speed - 10, 0),
			 ]
		}, {
			"destination": 0,
			"velocity": [
				Vector2(-left_col_rook_params.speed, 0),
				Vector2(-left_col_rook_params.speed - 5, 0),
				Vector2(-left_col_rook_params.speed + 20, 0),
				Vector2(-left_col_rook_params.speed - 25, 0),
				Vector2(-left_col_rook_params.speed + 10, 0),
			 ]
		}],
	}, true)
	for row in spawn_spaces_list.left:
		towers_of_doom_list.append(spawn_piece(
			Globals.SimpleBulletTypes.ROOK,
			Vector2(0, row), left_col_rook_params
		))

	right_col_rook_params.merge({
		"horizontal_movement": true,
		"allowed_movements": [{
			"destination": 0,
			"velocity": [
				Vector2(-right_col_rook_params.speed, 0),
				Vector2(-right_col_rook_params.speed - 15, 0),
				Vector2(-right_col_rook_params.speed + 20, 0),
				Vector2(-right_col_rook_params.speed - 10, 0),
				Vector2(-right_col_rook_params.speed + 30, 0),
			 ]
		}, {
			"destination": 7,
			"velocity": [
				Vector2(right_col_rook_params.speed, 0),
				Vector2(right_col_rook_params.speed + 15, 0),
				Vector2(right_col_rook_params.speed - 20, 0),
				Vector2(right_col_rook_params.speed + 10, 0),
				Vector2(right_col_rook_params.speed - 30, 0),
			 ]
		}],
	}, true)
	for row in spawn_spaces_list.right:
		towers_of_doom_list.append(spawn_piece(
			Globals.SimpleBulletTypes.ROOK,
			Vector2(7, row), right_col_rook_params
		))

func towers_of_doom_update_speed(_attack_params: Dictionary) -> void:
	for tower_id in towers_of_doom_list:
		SimpleBulletManager.update_bullet_params_dict(
			tower_id, { "choose_random": true }
		)

func towers_of_doom_end(_attack_params: Dictionary) -> void:
	continue_attacking = false
	SimpleBulletManager.despawn_active_bullets_by_type_list([
	  Globals.SimpleBulletTypes.ROOK,
	])
	yield(SimpleBulletManager, "bullets_despawned_by_type_list")
	change_boss_phase(current_boss_phase + 1)
	get_parent().enable_all_board_spaces()

	for _i in range(64):
		yield(get_parent(), "board_space_enabled")

	get_parent().make_all_board_spaces_safe()

func big_plus(attack_params: Dictionary) -> void:
	for _i in range(32):
		yield(get_parent(), "board_space_enabled")

	get_parent().manage_spawner_space_by_index(3, 4, true)
	get_parent().manage_spawner_space_by_index(4, 3, true)
	get_parent().remove_all_board_spaces_except([
		[3, 4], [4, 3], [4, 4], [4, 5], [5, 4],
	])

	yield(get_parent(), "board_modified")

	var allowed_spawn_positions: Array = [Vector2(3, 4), Vector2(4, 3)]
	var first_piece_position: int
	var second_piece_position: int
	var first_piece_params: Dictionary = attack_params.get("first_piece")
	var second_piece_params: Dictionary = attack_params.get("second_piece")
	var allowed_piece_types: Array = [
		Globals.SimpleBulletTypes.ROOK,
		Globals.SimpleBulletTypes.BISHOP,
	]
	var first_piece_type: String
	var wait_time_increment: float = 0.5
	var first_piece_wait_time: float = first_piece_params.initial_wait_time 

	while continue_attacking:
		first_piece_position = randi()%2
		if big_plus_bishops:
			first_piece_type = allowed_piece_types[randi()%2]
		else:
			first_piece_type = allowed_piece_types[0]
		first_piece_params.merge({
			"vertical_movement": first_piece_position == 1,
			"horizontal_movement": first_piece_position == 0,
			"is_player_above": false,
			"is_player_below": true,
			"is_player_right": true,
			"is_player_left": false,
			"has_direction": true,
			"initial_wait_time": first_piece_wait_time + wait_time_increment,
		}, true)
		spawn_piece(
			first_piece_type,
			allowed_spawn_positions[first_piece_position],
			first_piece_params	
		)

		if big_plus_hard_mode:
			second_piece_position = 0 if first_piece_position else 1
			second_piece_params.merge({
				"is_player_above": false,
				"is_player_below": true,
				"is_player_right": true,
				"is_player_left": false,
				"has_direction": true,
			}, true)
			spawn_piece(
				Globals.SimpleBulletTypes.BISHOP,
				allowed_spawn_positions[second_piece_position],
				second_piece_params
			)

		wait_time_increment = clamp(wait_time_increment - 0.05, 0, 0.5)

		main_attack_timer_start(attack_params.TIME_BETWEEN_ATTACKS + wait_time_increment)
		yield(main_attack_timer, "timeout")

func big_plus_enable_bishops(_attack_params: Dictionary) -> void:
	big_plus_bishops = true

func big_plus_enable_hard_mode(_attack_params: Dictionary) -> void:
	big_plus_hard_mode = true

func big_plus_end(_attack_params: Dictionary) -> void:
	continue_attacking = false
	SimpleBulletManager.despawn_active_bullets_by_type_list([
	  Globals.SimpleBulletTypes.ROOK,
	  Globals.SimpleBulletTypes.BISHOP,
	])
	yield(SimpleBulletManager, "bullets_despawned_by_type_list")

	main_attack_timer_start(1)
	yield(main_attack_timer, "timeout")
	emit_signal("enemy_death")

func _on_hardest_mode_time_until_next_stage_timer_timeout() -> void:
	._on_hardest_mode_time_until_next_stage_timer_timeout()
	_update_board(hardest_mode_current_fight_time)

func setup_attack_constants() -> void:
	.setup_attack_constants()
	attack_params['pawn_field'] = {
		"QUEEN_A": {
			"speed": QUEEN_BASE_SPEED + 200,
			"wait_time": 1.5,
			"remove_bullet_on_hit": false,
		},
		"QUEEN_B": {
			"speed": QUEEN_BASE_SPEED - 100,
			"wait_time": 0,
			"remove_bullet_on_hit": false,
		},
		Globals.SimpleBulletTypes.PAWN: {
			"vertical_movement": false,
			"horizontal_movement": false,
			"is_player_below": false, 
			"is_player_above": false, 
			"is_player_left": false, 
			"is_player_right": false, 
			"has_direction": true,
			"speed": 0,
			"wait_time": 999,
		},
		Globals.SimpleBulletTypes.ROOK: {
			"vertical_movement": false,
			"is_player_below": false, 
			"is_player_above": false, 
			"speed": ROOK_BASE_SPEED,
			"wait_time": 0.75,
			"max_number_of_movements": 1,
		},
	}
	attack_params["danger_line"] = {
		TIME_BETWEEN_ATTACKS = 1.5,
		Globals.SimpleBulletTypes.ROOK: {
			"speed": ROOK_BASE_SPEED + 100,
			"initial_wait_time": 1,
			"wait_time": 0.2,
			"max_number_of_movements": 1,
		},
		Globals.SimpleBulletTypes.BISHOP: {
			"speed": BISHOP_BASE_SPEED + 100,
			"wait_time": 0.2,
			"max_number_of_movements": 1,
		},
	}
	attack_params["towers_of_doom"] = {
		Globals.SimpleBulletTypes.ROOK: {
			"speed": ROOK_BASE_SPEED - 50,
			"remove_bullet_on_hit": false,
			"wait_time": 0.5,
			"has_direction": true,
			"current_movement": 0,
			"choose_random": false,
		},
	}
	attack_params["big_plus"] = {
		TIME_BETWEEN_ATTACKS = 0.8,
		"first_piece": {
			"speed": 350,
			"initial_wait_time": 0.5,
			"wait_time": 0.1,
			"max_number_of_movements": 1,
		},
		"second_piece": {
			"speed": 350,
			"initial_wait_time": 0.5,
			"wait_time": 0.1,
			"max_number_of_movements": 1,
		},
	}

func _update_board(boss_phase: int = 1) -> void:
	._update_board(boss_phase)
	if Utils.is_difficulty_hardest():
		if boss_phase == 1:
			get_parent().make_all_board_spaces_safe()
			get_parent().manage_spawner_space_by_index(0, 0, true)
			get_parent().manage_spawner_space_by_index(0, 7, true)
