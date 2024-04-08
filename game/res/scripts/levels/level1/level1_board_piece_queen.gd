extends "res://juegodetriangulos/res/scripts/base/base_board_piece.gd"


var can_move = false

func _ready():
	._ready()
	speed = 100

func _physics_process(delta):
	if can_move:
		set_next_position()
	._physics_process(delta)

func on_collision(collider):
	collider.get_hit(self)

func on_destination_reached():
	current_vertical_position = next_vertical_position
	current_horizontal_position = next_horizontal_position
	$can_move_timer.start()

func set_next_position():
	var vertical_movement = false
	var horizontal_movement = false
	set_direction()
	vertical_movement = is_player_below or is_player_above
	horizontal_movement = is_player_right or is_player_left
	if vertical_movement and horizontal_movement:
		var best_position = calc_best_move()
		next_vertical_position = best_position.get('row', 0)
		next_horizontal_position = best_position.get('column', 0) 
	else:
		if is_player_below or is_player_above:
			next_vertical_position = player_data.current_vertical_position
		elif is_player_left or is_player_right:
			next_horizontal_position = player_data.current_horizontal_position
	can_move = false

func calc_best_move():
	var vertical_increment = 1
	var horizontal_increment = 1
	if is_player_above:
		vertical_increment = -1
	if is_player_left:
		horizontal_increment = -1
	var new_vertical_position = current_vertical_position + vertical_increment
	var new_horizontal_position = current_horizontal_position + horizontal_increment
	var current_min_value = 999
	var new_value
	var current_best_position = {'row': 0, 'column': 0}
	while new_vertical_position != -1 and new_vertical_position != board_space_vertical_size:
		new_value = abs(player_data.current_vertical_position - new_vertical_position) + abs(player_data.current_horizontal_position - current_horizontal_position)
		if current_min_value != new_value:
			current_min_value = min(current_min_value, new_value)
			if current_min_value == new_value:
				current_best_position['row'] = new_vertical_position
				current_best_position['column'] = current_horizontal_position
		else:
			var new_posible_best_position = {'row': new_vertical_position, 'column': current_horizontal_position}
			current_best_position = [new_posible_best_position, current_best_position][randi()%2]
		new_vertical_position += vertical_increment
	while new_horizontal_position != -1 and new_horizontal_position != board_space_horizontal_size:
		new_value = abs(player_data.current_vertical_position - current_vertical_position) + abs(player_data.current_horizontal_position - new_horizontal_position)
		if current_min_value != new_value:
			current_min_value = min(current_min_value, new_value)
			if current_min_value == new_value:
				current_best_position['row'] = current_vertical_position
				current_best_position['column'] = new_horizontal_position
		else:
			var new_posible_best_position = {'row': current_vertical_position, 'column': new_horizontal_position}
			current_best_position = [new_posible_best_position, current_best_position][randi()%2]
		new_horizontal_position += horizontal_increment
	new_vertical_position = current_vertical_position + vertical_increment
	new_horizontal_position = current_horizontal_position + horizontal_increment
	while (
		new_vertical_position != -1 and new_vertical_position != board_space_vertical_size
	) and (
		new_horizontal_position != -1 and new_horizontal_position != board_space_horizontal_size
	):
		new_value = abs(player_data.current_vertical_position - new_vertical_position) + abs(player_data.current_horizontal_position - current_horizontal_position)
		if current_min_value != new_value:
			current_min_value = min(current_min_value, new_value)
			if current_min_value == new_value:
				current_best_position['row'] = new_vertical_position
				current_best_position['column'] = new_horizontal_position
		else:
			var new_posible_best_position = {'row': new_vertical_position, 'column': new_horizontal_position}
			current_best_position = [new_posible_best_position, current_best_position][randi()%2]
		new_vertical_position += vertical_increment
		new_horizontal_position += horizontal_increment
	return current_best_position

func _on_can_move_timer_timeout():
	can_move = true
