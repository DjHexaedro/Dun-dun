extends "res://juegodetriangulos/res/scripts/base/base_board_piece.gd"


func _ready():
	._ready()
	speed = 150

func set_next_position():
	set_direction()
	if vertical_movement:
		if is_player_below:
			next_vertical_position = board_space_vertical_size - 1
		elif is_player_above:
			next_vertical_position = 0
	else:
		if is_player_right:
			next_horizontal_position = board_space_horizontal_size - 1
		elif is_player_left:
			next_horizontal_position = 0

func _on_can_move_timer_timeout():
	set_next_position()
