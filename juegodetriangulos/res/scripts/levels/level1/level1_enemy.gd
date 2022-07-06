extends "res://juegodetriangulos/res/scripts/base/base_enemy.gd"

onready var pawnscene = preload("res://juegodetriangulos/scenes/level_assets/level1/board_piece_pawn.tscn")
onready var rookscene = preload("res://juegodetriangulos/scenes/level_assets/level1/board_piece_rook.tscn")
onready var bishopscene = preload("res://juegodetriangulos/scenes/level_assets/level1/board_piece_bishop.tscn")
onready var queenscene = preload("res://juegodetriangulos/scenes/level_assets/level1/board_piece_queen.tscn")

export (float) var SPAWN_PAWN_DELAY

var level_data
var board_space_spawners
var used_board_space_spawners = {}
var spawned_pieces_list = []
var player_position

func _ready():
	._ready()
	position.x = screensize.x / 2
	position.y = screensize.y * 0.1
	attack_list = ['spawn_pawn', 'spawn_rook', 'spawn_bishop']
	can_move = false
	can_attack = true
	$attack_delay.set_wait_time(SPAWN_PAWN_DELAY)
	level_data = get_tree().get_root().get_node("map").get_node("level_list").get_node("level1")
	board_space_spawners = level_data.board_space_spawners

func change_boss_phase(new_boss_phase):
	.change_boss_phase(new_boss_phase)
	if new_boss_phase == 2:
		spawn_queen(null)

func spawn_pawn(userdata):
	spawn_piece(pawnscene)

func spawn_rook(userdata):
	spawn_piece(rookscene)

func spawn_bishop(userdata):
	spawn_piece(bishopscene)

func spawn_queen(userdata):
	spawn_piece(queenscene)

func spawn_piece(piecescene):
	if len(board_space_spawners) and player != null:
		var spawn_space_dict = new_select_spawn_space()
		var piece = piecescene.instance()
		get_tree().get_root().add_child(piece)
		piece.set_initial_position(spawn_space_dict)
		spawned_pieces_list.append(piece)
		if not used_board_space_spawners.get(spawn_space_dict['row'], false):
			used_board_space_spawners[spawn_space_dict['row']] = []
		used_board_space_spawners[spawn_space_dict['row']].append(spawn_space_dict['column'])
		board_space_spawners[spawn_space_dict['row']].erase(spawn_space_dict['column'])
		$attack_delay.start()

func select_spawn_space():
	var avaliable_rows = board_space_spawners.keys()
	var selected_row_index = randi()%len(avaliable_rows)
	var selected_row = avaliable_rows[selected_row_index]
	var avaliable_columns = board_space_spawners[selected_row]
	var selected_column_index = randi()%len(avaliable_columns)
	var selected_column = board_space_spawners[selected_row][selected_column_index]
	return {'row': selected_row, 'row_index': selected_row_index, 'column': selected_column, 'column_index': selected_column_index}

func new_select_spawn_space():
	var current_min_value = 999
	var spawn_space_dict = {'row': 0, 'column': 0}
	for row in board_space_spawners.keys():
		for column in board_space_spawners[row]:
			var new_value = abs(player.current_vertical_position - row) + abs(player.current_horizontal_position - column)
			if current_min_value != new_value:
				current_min_value = min(current_min_value, new_value)
				if current_min_value == new_value:
					spawn_space_dict['row'] = row
					spawn_space_dict['column'] = column 
			else:
				var possible_spawn_dict = {'row': row, 'column': column}
				spawn_space_dict = [possible_spawn_dict, spawn_space_dict][randi()%2]
	return spawn_space_dict


func unload():
	var spawned_pieces_list_copy = spawned_pieces_list.duplicate()
	for piece in spawned_pieces_list_copy:
		piece.unload()
	spawned_pieces_list = []
	.unload()

func _on_attack_delay_timeout():
	can_attack = true

func _on_readd_spawner_timer_timeout():
	if len(used_board_space_spawners):
		var first_row = used_board_space_spawners.keys()[0]
		var n_columns = 0
		for row in used_board_space_spawners.values():
			n_columns += len(row)
		if n_columns > 5:
			board_space_spawners[first_row].append(used_board_space_spawners[first_row][0])
			used_board_space_spawners[first_row].remove(0)
			if not len(used_board_space_spawners[first_row]):
				used_board_space_spawners.erase(first_row)
			first_row = used_board_space_spawners.keys()[0]
		board_space_spawners[first_row].append(used_board_space_spawners[first_row][0])
		used_board_space_spawners[first_row].remove(0)
		if not len(used_board_space_spawners[first_row]):
			used_board_space_spawners.erase(first_row)
	$readd_spawner_timer.start()
