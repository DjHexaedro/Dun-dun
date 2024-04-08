# Helper class that creates and manages all the possible trayectories a simple
# bullet can have. Function names must follow the following format, as they are
# called dynamically based on the name of the bullet type: [bullet_type_name]_pattern.
# They also must receive three parameters (an AnimatedSprite, a Dictionary and
# the delta value) for the same reason
# Can be accessed from anywhere within the project
extends Node


# Circular bullet params
const CIRCULAR_DEVIATION_INCREMENT: int = 20
const CIRCULAR_MAX_DEVIATION_DEGREES: int = 90

# Soft homing bullet params 
const SOFT_HOMING_MAX_DISTANCE: int = 50
const SOFT_HOMING_SPEED_INCREMENT: float = 1.5
var soft_homing_y_speed: int = 0
var soft_homing_x_speed: int = 0
var soft_homing_current_distance: int = 0

# Delayed bullet params
signal delayed_bullet_stopped(bullet)

# Delayed circular bullet params
signal arena_center_reached()

# Board pieces params
signal destination_reached(piece_params, bullet_id)


func straight_bullet_pattern(
	bullet: AnimatedSprite, bullet_params: Dictionary, delta: float
) -> void:
	bullet.position.x += bullet_params.velocity.x * delta
	bullet.position.y += bullet_params.velocity.y * delta

func circular_bullet_pattern(
	bullet: AnimatedSprite, bullet_params: Dictionary, delta: float
) -> void:
	bullet.move_local_x(bullet_params.velocity.x * delta)
	bullet.move_local_y(bullet_params.velocity.y * delta)
	bullet.rotation_degrees = clamp(
		bullet.rotation_degrees + (
			CIRCULAR_DEVIATION_INCREMENT * delta *
			bullet_params.rotation_direction
		),
		-CIRCULAR_MAX_DEVIATION_DEGREES, CIRCULAR_MAX_DEVIATION_DEGREES
	)

func soft_homing_bullet_pattern(
	bullet: AnimatedSprite, bullet_params: Dictionary, delta: float
) -> void:
	var chosen_player_id: int = randi()%PlayerManager.get_number_of_players()
	if bullet_params.where_goes == "goes_right":
		bullet_params.soft_homing_current_distance = -clamp(
			bullet.position.y - PlayerManager.get_player_old_position(chosen_player_id).y,
			-SOFT_HOMING_MAX_DISTANCE, SOFT_HOMING_MAX_DISTANCE
		)
		if bullet.position.x <= PlayerManager.get_player_old_position(chosen_player_id).x:
			bullet_params.soft_homing_y_speed = (
				(bullet_params.velocity.y / 2) * delta *
				(bullet_params.soft_homing_current_distance / SOFT_HOMING_MAX_DISTANCE)
			)
			bullet_params.soft_homing_x_speed = bullet_params.velocity.x * (
				SOFT_HOMING_SPEED_INCREMENT
				if abs(bullet_params.soft_homing_current_distance) != SOFT_HOMING_MAX_DISTANCE
				else 1.0
			) * delta
	elif bullet_params.where_goes == "goes_left":
		bullet_params.soft_homing_current_distance = -clamp(
			bullet.position.y - PlayerManager.get_player_old_position(chosen_player_id).y,
			-SOFT_HOMING_MAX_DISTANCE, SOFT_HOMING_MAX_DISTANCE
		)
		if bullet.position.x >= PlayerManager.get_player_old_position(chosen_player_id).x:
			bullet_params.soft_homing_y_speed = (
				(bullet_params.velocity.y / 2) * delta *
				(bullet_params.soft_homing_current_distance / SOFT_HOMING_MAX_DISTANCE)
			)
			bullet_params.soft_homing_x_speed = bullet_params.velocity.x * (
				-SOFT_HOMING_SPEED_INCREMENT
				if abs(bullet_params.soft_homing_current_distance) != SOFT_HOMING_MAX_DISTANCE
				else -1.0
			) * delta
	elif bullet_params.where_goes == "goes_up":
		bullet_params.soft_homing_current_distance = -clamp(
			bullet.position.x - PlayerManager.get_player_old_position(chosen_player_id).x,
			-SOFT_HOMING_MAX_DISTANCE, SOFT_HOMING_MAX_DISTANCE
		)
		if bullet.position.y >= PlayerManager.get_player_old_position(chosen_player_id).y:
			bullet_params.soft_homing_x_speed = (
				(bullet_params.velocity.x / 2) * delta *
				(bullet_params.soft_homing_current_distance / SOFT_HOMING_MAX_DISTANCE)
			)
			bullet_params.soft_homing_y_speed = bullet_params.velocity.y * (
				-SOFT_HOMING_SPEED_INCREMENT
				if abs(bullet_params.soft_homing_current_distance) != SOFT_HOMING_MAX_DISTANCE
				else -1.0
			) * delta
	else:
		bullet_params.soft_homing_current_distance = -clamp(
			bullet.position.x - PlayerManager.get_player_old_position(chosen_player_id).x,
			-SOFT_HOMING_MAX_DISTANCE, SOFT_HOMING_MAX_DISTANCE
		)
		if bullet.position.y <= PlayerManager.get_player_old_position(chosen_player_id).y:
			bullet_params.soft_homing_x_speed = (
				(bullet_params.velocity.x / 2) * delta *
				(bullet_params.soft_homing_current_distance / SOFT_HOMING_MAX_DISTANCE)
			)
			bullet_params.soft_homing_y_speed = bullet_params.velocity.y * (
				SOFT_HOMING_SPEED_INCREMENT
				if abs(bullet_params.soft_homing_current_distance) != SOFT_HOMING_MAX_DISTANCE 
				else 1.0
			) * delta
	bullet.position.x += bullet_params.soft_homing_x_speed
	bullet.position.y += bullet_params.soft_homing_y_speed

func delayed_bullet_pattern(
	bullet: AnimatedSprite, bullet_params: Dictionary, delta: float
) -> void:
	if (
		not bullet_params.get("continue_moving", false) and
		ArenaManager.get_arena_center().distance_squared_to(bullet.position) < 100
	):
		if bullet_params.get("can_emit_signal", true):
			emit_signal("delayed_bullet_stopped", bullet.get_instance_id())
	else:
		bullet.position.x += bullet_params.velocity.x * delta
		bullet.position.y += bullet_params.velocity.y * delta

func delayed_circular_bullet_pattern(
	bullet: AnimatedSprite, bullet_params: Dictionary, delta: float
) -> void:
	if ArenaManager.get_arena_center().distance_squared_to(bullet.position) < 200:
		if bullet_params.get("can_emit_signal", true):
			emit_signal("arena_center_reached")
	bullet.move_local_x(bullet_params.velocity.x * delta)
	bullet.move_local_y(bullet_params.velocity.y * delta)
	if bullet_params.change_rotation_direction:
		bullet_params.current_deviation += (
			bullet_params.current_rotation_speed *
			delta * bullet_params.rotation_direction
		)
		if abs(bullet_params.current_deviation) > Globals.Angles.DEGREES45:
			bullet_params.change_rotation_direction = false
			bullet_params.rotation_direction *= -1
	bullet.rotation_degrees += (
		bullet_params.current_rotation_speed *
		delta * bullet_params.rotation_direction
	)

func pawn_bullet_pattern(
	bullet: AnimatedSprite, bullet_params: Dictionary, delta: float
) -> void:
	_board_piece_movement_pattern(bullet, bullet_params, delta)

func rook_bullet_pattern(
	bullet: AnimatedSprite, bullet_params: Dictionary, delta: float
) -> void:
	_board_piece_movement_pattern(bullet, bullet_params, delta)

func bishop_bullet_pattern(
	bullet: AnimatedSprite, bullet_params: Dictionary, delta: float
) -> void:
	_board_piece_movement_pattern(bullet, bullet_params, delta)

func queen_bullet_pattern(
	bullet: AnimatedSprite, bullet_params: Dictionary, delta: float
) -> void:
	_board_piece_movement_pattern(bullet, bullet_params, delta)

func _board_piece_movement_pattern(
	piece: AnimatedSprite, piece_params: Dictionary, delta: float
) -> void:
	if piece_params.can_move:
		var destination: Vector2 = (
			ArenaManager.get_current_location().get_board_info()[
				piece_params.next_position.y][piece_params.next_position.x
			].global_position
		)

		piece.global_position += piece_params.velocity * delta
		if piece.global_position.distance_squared_to(destination) < 5:
			piece_params.can_move = false
			piece.global_position = destination
			emit_signal("destination_reached", piece_params, piece.get_instance_id())

