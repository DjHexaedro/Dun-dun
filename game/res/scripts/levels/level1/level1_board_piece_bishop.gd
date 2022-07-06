extends "res://juegodetriangulos/res/scripts/base/base_board_piece.gd"


func _ready():
	._ready()
	speed = 150

func set_next_position():
	var vertical_increment
	var horizontal_increment
	var previous_vertical_position = current_vertical_position
	var previous_horizontal_position = current_horizontal_position
	set_direction()
	if is_player_below:
		vertical_increment = 1
	elif is_player_above:
		vertical_increment = -1
	else:
		if current_vertical_position == 0:
			vertical_increment = 1
		elif current_vertical_position == (board_space_vertical_size - 1): 
			vertical_increment = -1
		else:
			vertical_increment = [-1, 1][randi()%2]
	if is_player_right:
		horizontal_increment = 1
	elif is_player_left:
		horizontal_increment = -1
	else:
		if current_horizontal_position == 0:
			horizontal_increment = 1
		elif current_horizontal_position == (board_space_horizontal_size - 1): 
			horizontal_increment = -1
		else:
			horizontal_increment = [-1, 1][randi()%2]
	while (
		next_vertical_position < board_space_vertical_size and next_vertical_position > -1
	) and (
		next_horizontal_position < board_space_horizontal_size and next_horizontal_position > -1
	):
		previous_vertical_position = next_vertical_position
		previous_horizontal_position = next_horizontal_position
		next_vertical_position += vertical_increment
		next_horizontal_position += horizontal_increment
	next_vertical_position = previous_vertical_position
	next_horizontal_position = previous_horizontal_position

func _on_can_move_timer_timeout():
	set_next_position()
