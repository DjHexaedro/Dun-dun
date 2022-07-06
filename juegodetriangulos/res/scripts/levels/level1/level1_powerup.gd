extends "res://juegodetriangulos/res/scripts/base/base_powerup.gd"


var player = null
var level_data
var board_space_list
var safe_board_space_list
var board_space_vertical_size
var board_space_horizontal_size
var current_vertical_position
var current_horizontal_position


func _ready():
	._ready()
	player = get_tree().get_root().get_node(Globals.NodeNames.PLAYER)
	level_data = get_tree().get_root().get_node("map").get_node("level_list").get_node("level1")
	board_space_list = level_data.board_space_list
	safe_board_space_list = level_data.safe_board_space_list
	board_space_vertical_size = level_data.board_vertical_size
	board_space_horizontal_size = level_data.board_horizontal_size
	set_initial_position()
	position = board_space_list[current_vertical_position][current_horizontal_position].global_position

func set_initial_position():
	var avaliable_rows = safe_board_space_list.keys()
	var selected_row = avaliable_rows[randi()%len(avaliable_rows)]
	var avaliable_columns = safe_board_space_list[selected_row]
	var selected_column = avaliable_columns[randi()%len(avaliable_columns)]
	while player.current_vertical_position == current_vertical_position and player.current_horizontal_position == current_horizontal_position:
		avaliable_rows = safe_board_space_list.keys()
		selected_row = avaliable_rows[randi()%len(avaliable_rows)]
		avaliable_columns = safe_board_space_list[selected_row]
		selected_column = avaliable_columns[randi()%len(avaliable_columns)]
	current_vertical_position = selected_row
	current_horizontal_position = selected_column
