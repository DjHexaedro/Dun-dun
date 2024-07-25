# Contains the functions to manage the different pieces Parkov can spawn
extends "res://juegodetriangulos/res/scripts/levels/1/base.gd"


const BASE_PIECE_DICTIONARY: Dictionary = {
	"is_player_below": false,
	"is_player_above": false,
	"is_player_right": false,
	"is_player_left": false,
	"vertical_movement": false,
	"has_direction": false,
	"can_move": true,
	"velocity": Vector2.ZERO,
	"current_position": Vector2.ZERO,
	"next_position": Vector2.ZERO
}
const VECTOR_OOB: Vector2 = Vector2(-1, -1)
const SPIRAL_ROOK_OUTER_RIGHT_POSITIONS: Array = [
	Vector2(7, 0), Vector2(7, 7), Vector2(0, 7),
	Vector2(0, 1), Vector2(6, 1), Vector2(6, 6), Vector2(1, 6),
	Vector2(1, 2), Vector2(5, 2), Vector2(5, 5), Vector2(2, 5),
	Vector2(2, 3), Vector2(4, 3), Vector2(4, 4), Vector2(3, 4),
]
const SPIRAL_ROOK_OUTER_RIGHT_DIRECTIONS: Array = [
	Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)
]

var current_queen_positions: Dictionary = {}

func _ready():
	SimpleBulletMovementManager.connect(
		"destination_reached", self, "_on_piece_destination_reached"
	)

func set_direction(piece_params: Dictionary) -> void:
	var chosen_player_id: int = randi() % PlayerManager.get_number_of_players()
	var player_data: Node = PlayerManager.get_player_node(chosen_player_id)

	piece_params.is_player_below = false 
	piece_params.is_player_above = false 
	piece_params.is_player_right = false 
	piece_params.is_player_left = false 
	piece_params.vertical_movement = false

	if player_data.current_position.y > piece_params.current_position.y:
		piece_params.is_player_below = true 
	elif player_data.current_position.y < piece_params.current_position.y:
		piece_params.is_player_above = true
		
	if player_data.current_position.x > piece_params.current_position.x:
		piece_params.is_player_right = true
	elif player_data.current_position.x < piece_params.current_position.x:
		piece_params.is_player_left = true 

	var vertical_distance: int = abs(
		player_data.current_position.y - piece_params.current_position.y
	)
	var horizontal_distance: int = abs(
		player_data.current_position.x - piece_params.current_position.x
	)

	if vertical_distance > horizontal_distance:
		piece_params.vertical_movement = true
	elif vertical_distance < horizontal_distance:
		piece_params.vertical_movement = false
	else:
		piece_params.vertical_movement = [true, false][randi()%2]

	piece_params.has_direction = true

func queen_set_next_position(piece_params: Dictionary, piece_id: int) -> void:
	var chosen_player_id: int = randi() % PlayerManager.get_number_of_players()
	var player_data: Node = PlayerManager.get_player_node(chosen_player_id)
	var vertical_movement: bool = false
	var horizontal_movement: bool = false

	set_direction(piece_params)

	vertical_movement =\
			piece_params.is_player_below or piece_params.is_player_above
	horizontal_movement =\
			piece_params.is_player_right or piece_params.is_player_left

	if vertical_movement and horizontal_movement:
		var best_position: Vector2 = queen_calc_best_move(
			player_data.current_position, piece_params, piece_id
		)
		piece_params.next_position = best_position

	else:
		if piece_params.is_player_below or piece_params.is_player_above:
			piece_params.next_position = Vector2(
				piece_params.current_position.x, player_data.current_position.y
			)

		elif piece_params.is_player_left or piece_params.is_player_right:
			piece_params.next_position = Vector2(
				player_data.current_position.x, piece_params.current_position.y
			)

		else:
			piece_params.next_position = piece_params.current_position

	current_queen_positions[piece_id] = piece_params.next_position


	var new_velocity: Vector2 = Vector2.ZERO

	if piece_params.next_position.y != piece_params.current_position.y:
		if piece_params.is_player_below:
			new_velocity.y = piece_params.speed
		elif piece_params.is_player_above:
			new_velocity.y = -piece_params.speed

	if piece_params.next_position.x != piece_params.current_position.x:
		if piece_params.is_player_right:
			new_velocity.x = piece_params.speed
		elif piece_params.is_player_left:
			new_velocity.x = -piece_params.speed


	# Diagonal movement is faster than horizontal movement,
	# so we reduce its speed a little bit
	if new_velocity.x != 0 and new_velocity.y != 0:
		new_velocity *= 0.75

	piece_params.velocity = new_velocity
	piece_params.can_move = true

func _exists_queen_position_overlap(queen_id: int, new_position: Vector2) -> bool:
	for entry_id in current_queen_positions:
		if (
			entry_id != queen_id and
			current_queen_positions[entry_id] == new_position
		):
			return true 
	return false

func queen_check_movement(
	starting_position: Vector2, player_position: Vector2,
	piece_id: int, step: Vector2, global_best: Dictionary
) -> Dictionary:
	var new_value: int = -1
	var new_position: Vector2 = starting_position + step
	var current_best_position: Vector2 = global_best.position
	var current_min_value: int = global_best.min_value

	while _new_position_is_valid(new_position):

		if not get_board_space(new_position).enabled:
			break

		if not _exists_queen_position_overlap(piece_id, new_position):

			new_value = (
				abs(player_position.y - new_position.y)
				+
				abs(player_position.x - new_position.x)
			)

			if current_min_value != new_value:
				current_min_value = min(current_min_value, new_value)
				if current_min_value == new_value:
					current_best_position = new_position
			else:
				current_best_position = [
					new_position, current_best_position
				][randi()%2]

		new_position += step
	
	return {
		"position": current_best_position,
		"min_value": current_min_value
	}

func queen_calc_best_move(
	player_position: Vector2, piece_params: Dictionary, piece_id: int
) -> Vector2:
	var vertical_increment: int = 1
	var horizontal_increment: int = 1

	if piece_params.is_player_above:
		vertical_increment = -1
	if piece_params.is_player_left:
		horizontal_increment = -1

	var global_best: Dictionary = {
		"position": Vector2.ZERO,
		"min_value": 999,
	}

	var movement_list: Array = [
		Vector2(0, vertical_increment), # Vertical movement
		Vector2(horizontal_increment, 0), # Horizontal movement
		Vector2(horizontal_increment, vertical_increment), # Diagonal movement
	]

	# Check which movement direction is the best
	for movement in movement_list:
		global_best = queen_check_movement(
			piece_params.current_position, player_position,
			piece_id, movement, global_best
		)

	return global_best.position

func pawn_set_next_position(piece_params: Dictionary, pawn_id: int = -1) -> void:
	var vertical_direction: int = 0
	var horizontal_direction: int = 0
	var direction_vector: Vector2 = Vector2.ZERO
	var current_position: Vector2 = piece_params.current_position
	var projected_position: Vector2

	if piece_params.vertical_movement:
		# Unsetting unused directions resolves bugs related to pieces spawning
		# using a pawn's parameters as a base (e.g. like in _pawn_explode())
		piece_params.is_player_left = false
		piece_params.is_player_right = false

		vertical_direction = 1 if piece_params.is_player_below else -1
		horizontal_direction = 0
		projected_position = current_position + Vector2(0, vertical_direction)
		if (
			projected_position.y < len(board_space_list) and
			get_board_space(projected_position).being_used
		):
			horizontal_direction = (
				1 if current_position.x == 0 else
				-1 if (current_position.x == len(
					board_space_list[current_position.y]
				) - 1) else
				[1, -1][randi()%2]
			)

	else:
		# Unsetting unused directions resolves bugs related to pieces spawning
		# using a pawn's parameters as a base (e.g. like in _pawn_explode())
		piece_params.is_player_above = false
		piece_params.is_player_below = false

		horizontal_direction = 1 if piece_params.is_player_right else -1
		vertical_direction = 0
		projected_position = current_position + Vector2(horizontal_direction, 0)
		if (
			projected_position.x < len(board_space_list[projected_position.y])
			and get_board_space(projected_position).being_used
		):
			vertical_direction = (
				1 if current_position.y == 0 else
				-1 if current_position.y == (len(board_space_list) - 1) else
				[1, -1][randi()%2]
			)
	
	direction_vector = Vector2(horizontal_direction, vertical_direction)
	piece_params["velocity"] = direction_vector * piece_params.speed
	piece_params["next_position"] = current_position + direction_vector

	if not _new_position_is_valid(piece_params.get("next_position", VECTOR_OOB)):
		SimpleBulletManager.remove_active_bullet(piece_params.piece_type, pawn_id)
		piece_params["next_position"] = piece_params.current_position
	else:
		piece_params.can_move = true 

func bishop_set_next_position(piece_params: Dictionary) -> void:
	if piece_params.get("allowed_movements", {}):
		var movement_info: Dictionary = piece_params.allowed_movements[
			piece_params.current_movement%len(piece_params.allowed_movements)
		]
		piece_params["next_position"] = movement_info.destination
		piece_params["velocity"] = movement_info.velocity
		piece_params.current_movement += 1
		piece_params.can_move = true
	else:
		var vertical_increment: int
		var horizontal_increment: int
		var previous_position: Vector2 = piece_params.current_position
		piece_params["next_position"] = piece_params.current_position


		if piece_params.is_player_below or piece_params.current_position.y == 0:
			vertical_increment = 1
		elif (
			piece_params.is_player_above or
			piece_params.current_position.y == len(board_space_list)
		):
			vertical_increment = -1
		else:
			vertical_increment = [-1, 1][randi()%2]


		if piece_params.is_player_right or piece_params.current_position.x == 0:
			horizontal_increment = 1
		elif piece_params.is_player_left or piece_params.current_position.x == len(
			board_space_list[piece_params.current_position.y]
		):
			horizontal_increment = -1
		else:
			horizontal_increment = [-1, 1][randi()%2]


		var direction_vector: Vector2 = Vector2(
			horizontal_increment, vertical_increment
		)

		while _new_position_is_valid(piece_params.get("next_position", VECTOR_OOB)):
			previous_position = piece_params["next_position"]
			piece_params["next_position"] += direction_vector

		piece_params["next_position"] = previous_position
		piece_params["velocity"] = piece_params.speed * direction_vector 
		piece_params.can_move = true

func zigzag_bishop_set_next_position(piece_params: Dictionary, bishop_id: int) -> void:
	var direction_vector: Vector2 = piece_params.get("direction", Vector2.ZERO)
	if direction_vector == Vector2.ZERO:
		direction_vector.x = 1 if piece_params.get("is_player_right", false) else -1
		direction_vector.y = 1 if piece_params.get("is_player_below", false) else -1

		# When no direction_vector is specified, the desired behaviour of the
		# piece (go_up, go_down, go_left or go_right) is also left undefined.
		# We set it here, based on the position of the player
		var chosen_player_id: int = randi() % PlayerManager.get_number_of_players()
		var player_data: Node = PlayerManager.get_player_node(chosen_player_id)

		var vertical_difference: int =\
				player_data.current_position.y - piece_params.current_position.y 

		var horizontal_difference: int =\
				player_data.current_position.x - piece_params.current_position.x 

		if abs(vertical_difference) > abs(horizontal_difference):
			piece_params.go_up = vertical_difference < 0
			piece_params.go_down = vertical_difference > 0
		elif abs(vertical_difference) < abs(horizontal_difference):
			piece_params.go_left = horizontal_difference < 0
			piece_params.go_right = horizontal_difference > 0
		else:
			var possible_behaviours: Array =\
					["go_up", "go_down", "go_left", "go_right"]
			var chosen_behaviour_index: int = randi()%len(possible_behaviours)
			piece_params[possible_behaviours[chosen_behaviour_index]] = true



	piece_params.direction_vector = direction_vector
	piece_params["next_position"] = piece_params.current_position + direction_vector
	
	if not _new_position_is_valid(piece_params.get("next_position", VECTOR_OOB)):
		SimpleBulletManager.remove_active_bullet(piece_params.piece_type, bishop_id)
		piece_params["next_position"] = piece_params.current_position

	piece_params["velocity"] = piece_params.speed * direction_vector 

	if piece_params.get("go_up", false) or piece_params.get("go_down", false):
		direction_vector.x *= -1
	elif piece_params.get("go_left", false) or piece_params.get("go_right", false):
		direction_vector.y *= -1

	piece_params.direction = direction_vector 
	piece_params.can_move = true

func rook_set_next_position(piece_params: Dictionary) -> void:
	if piece_params.get("allowed_movements", {}):
		var movement_info: Dictionary = piece_params.allowed_movements[
			piece_params.current_movement%len(piece_params.allowed_movements)
		]

		if movement_info.velocity is Array:
			if piece_params.get("choose_random", true):
				piece_params["velocity"] = movement_info.velocity[
					randi()%len(movement_info.velocity)
				]
			else:
				piece_params["velocity"] = movement_info.velocity[0]
		else:
			piece_params["velocity"] = movement_info.velocity

		var final_destination: Vector2 = (
			Vector2(piece_params.current_position.x, movement_info.destination)
			if piece_params.velocity.y != 0 else
			Vector2(movement_info.destination, piece_params.current_position.y)
		)
		piece_params["next_position"] = final_destination

		piece_params.current_movement += 1

	else:
		var next_position: int
		var direction: int

		if piece_params.vertical_movement:
			if piece_params.is_player_below:
				next_position = len(board_space_list) - 1
				direction = 1
			elif piece_params.is_player_above:
				next_position = 0
				direction = -1

			while not board_space_list[next_position][piece_params.current_position.x].enabled:
				next_position -= direction
			piece_params["next_position"].y = next_position
			piece_params["next_position"].x = piece_params.current_position.x
			piece_params["velocity"] = Vector2(0, piece_params.speed * direction)

		else:
			if piece_params.is_player_right:
				next_position =\
					len(board_space_list[piece_params.current_position.y]) - 1
				direction = 1
			elif piece_params.is_player_left:
				next_position = 0
				direction = -1

			while not board_space_list[piece_params.current_position.y][next_position].enabled:
				next_position -= direction
			piece_params["next_position"].y = piece_params.current_position.y
			piece_params["next_position"].x = next_position
			piece_params["velocity"] = Vector2(piece_params.speed * direction, 0)

	piece_params.can_move = true

func spiral_rook_set_next_position(piece_params: Dictionary, rook_id: int) -> void:
	var current_iteration: int = piece_params.get("current_iteration", 0) 
	if current_iteration < len(SPIRAL_ROOK_OUTER_RIGHT_POSITIONS):
		piece_params.next_position = SPIRAL_ROOK_OUTER_RIGHT_POSITIONS[
			current_iteration
		]
		piece_params.velocity = (
			piece_params.speed * SPIRAL_ROOK_OUTER_RIGHT_DIRECTIONS[
				current_iteration % 4
			]
		)
		piece_params.can_move = true
		piece_params.current_iteration = current_iteration + 1
	else:
		SimpleBulletManager.remove_active_bullet(piece_params.piece_type, rook_id)
		piece_params["next_position"] = piece_params.current_position

func _new_position_is_valid(new_position: Vector2) -> bool:
	return (
		new_position.y >= 0 and
		new_position.y < len(board_space_list) and
		new_position.x >= 0 and
		new_position.x < len(board_space_list[new_position.y]) and
		board_space_list[new_position.y][new_position.x].enabled
	)

func _on_piece_destination_reached(
	piece_params: Dictionary, piece_id: int
) -> void:
	var initial_wait_time: float = piece_params.get("initial_wait_time", 0.0)
	if initial_wait_time:
		yield(get_tree().create_timer(initial_wait_time), "timeout")
		piece_params.erase("initial_wait_time")
	elif piece_params.wait_time > 0:
		yield(get_tree().create_timer(piece_params.wait_time), "timeout")
	
	var current_piece_type: String =\
			piece_params.get("piece_type", Globals.SimpleBulletTypes.ROOK)
	
	piece_params.current_position = piece_params.next_position
	var max_number_of_movements: int =\
			piece_params.get("max_number_of_movements", -1)
	
	var current_number_of_movements: int =\
			piece_params.get("current_number_of_movements", 0)

	if not piece_params.has_direction:
		set_direction(piece_params)

	if max_number_of_movements >= 0:
		if current_number_of_movements >= max_number_of_movements:
			var on_movements_consumed_function: String = piece_params.get(
				"on_movements_consumed", ""
			)
			if on_movements_consumed_function:
				call(
					on_movements_consumed_function, piece_params,
					piece_params.get("on_movements_consumed_params", {})
				)
			SimpleBulletManager.remove_active_bullet(current_piece_type, piece_id)
		else:
			piece_params[
				"current_number_of_movements"
			] = current_number_of_movements + 1

	if current_piece_type == Globals.SimpleBulletTypes.PAWN:
		pawn_set_next_position(piece_params, piece_id)
	elif current_piece_type == Globals.SimpleBulletTypes.QUEEN:
		queen_set_next_position(piece_params, piece_id)
	elif current_piece_type == Globals.SimpleBulletTypes.BISHOP:
		if piece_params.get("zigzag", false):
			zigzag_bishop_set_next_position(piece_params, piece_id)
		else:
			bishop_set_next_position(piece_params)
	else:
		if piece_params.get("spiral", false):
			spiral_rook_set_next_position(piece_params, piece_id)
		else:
			rook_set_next_position(piece_params)

	SimpleBulletManager.update_bullet_params_dict(piece_id, piece_params)
