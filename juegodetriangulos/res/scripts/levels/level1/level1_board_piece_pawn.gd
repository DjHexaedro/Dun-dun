extends "res://juegodetriangulos/res/scripts/base/base_board_piece.gd"


var can_move = false
var has_direction = false

func _ready():
	._ready()
	speed = 25

func _physics_process(delta):
	if can_move:
		set_next_position()
	._physics_process(delta)

func on_destination_reached():
	current_vertical_position = next_vertical_position
	current_horizontal_position = next_horizontal_position

func set_next_position():
	if not has_direction:
		set_direction()
		has_direction = true
	if vertical_movement:
		if is_player_below:
			next_vertical_position = current_vertical_position + 1
		elif is_player_above:
			next_vertical_position = current_vertical_position - 1
	else:
		if is_player_right:
			next_horizontal_position = current_horizontal_position + 1
		elif is_player_left:
			next_horizontal_position = current_horizontal_position - 1
	if (
		next_vertical_position > (board_space_vertical_size - 1) or next_vertical_position < 0
	) or (
		next_horizontal_position > (board_space_horizontal_size - 1) or next_horizontal_position < 0
	):
		unload()
		next_vertical_position = current_vertical_position
		next_horizontal_position = current_horizontal_position
	can_move = false

func _on_can_move_timer_timeout():
	can_move = true
