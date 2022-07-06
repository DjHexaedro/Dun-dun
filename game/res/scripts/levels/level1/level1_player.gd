extends "res://juegodetriangulos/res/scripts/base/base_player.gd"


export (float) var CAN_MOVE_DELAY

var board_space_list = []
var current_vertical_position
var current_horizontal_position
var old_horizontal_position
var old_vertical_position
var board_space_vertical_size
var board_space_horizontal_size
var level_data
var can_move = true

func _ready():
	level_data = get_tree().get_root().get_node("map").get_node("level_list").get_node("level1")
	board_space_list = level_data.board_space_list
	board_space_vertical_size = level_data.board_vertical_size
	board_space_horizontal_size = level_data.board_horizontal_size
	current_vertical_position = int(board_space_vertical_size / 2)
	current_horizontal_position = int(board_space_horizontal_size / 2)
	position = board_space_list[current_vertical_position][current_horizontal_position].global_position
	$can_move.set_wait_time(CAN_MOVE_DELAY)
	._ready()
	$update_old_position_timer.stop()
	old_vertical_position = current_vertical_position
	old_horizontal_position = current_horizontal_position

func _input(event):
	._input(event)

func _process(delta):
	var board_rotation = level_data.board_center.rotation_degrees
	if can_move:
		if board_rotation == 0:
			if Input.is_action_pressed("player_movedown"):
				current_vertical_position += 1
			if Input.is_action_pressed("player_moveup"):
				current_vertical_position -= 1
			if Input.is_action_pressed("player_moveright"):
				current_horizontal_position += 1
			if Input.is_action_pressed("player_moveleft"):
				current_horizontal_position -= 1
		#elif board_rotation == 45:
		#	if Input.is_action_pressed("player_movedown"):
		#		current_vertical_position += 1
		#		current_horizontal_position += 1
		#	if Input.is_action_pressed("player_moveup"):
		#		current_vertical_position -= 1
		#		current_horizontal_position -= 1
		#	if Input.is_action_pressed("player_moveright"):
		#		current_horizontal_position += 1
		#		current_vertical_position -= 1
		#	if Input.is_action_pressed("player_moveleft"):
		#		current_horizontal_position -= 1
		#		current_vertical_position += 1
		if current_vertical_position > (board_space_vertical_size - 1) or current_vertical_position < 0:
			current_vertical_position = old_vertical_position
		else:
			old_vertical_position = current_vertical_position
		if current_horizontal_position > (board_space_horizontal_size - 1) or current_horizontal_position < 0:
			current_horizontal_position = old_horizontal_position
		else:
			old_horizontal_position = current_horizontal_position
		can_move = false
		$can_move.start()
	position = board_space_list[current_vertical_position][current_horizontal_position].global_position

func _on_can_move_timeout():
	can_move = true
