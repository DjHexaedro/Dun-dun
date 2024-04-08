# Helper class that contains functions for common bullet patterns.
# Can be accessed from anywhere within the project
extends Node

const HEALTH_MAX_ALLOWED_DEVIATION: float = 0.2

var bullet_wall_last_starting_x_position_deviation: int = -1


func bullet_hell_semicircle(
	bullet_type: String, total_bullet_number: int, starting_angle: float, bullet_params_list: Array
) -> void:
	var distance_between_bullets: float = PI / total_bullet_number
	var deviation: float = distance_between_bullets * (randi() % 3)
	var params_dict: Dictionary
	var angle_to_player: float 
	var n_of_players: int = PlayerManager.get_number_of_players()
	var chosen_player_id: int
	for current_bullet_number in range(total_bullet_number):
		chosen_player_id = randi()%n_of_players
		params_dict = bullet_params_list[posmod(current_bullet_number, len(bullet_params_list))]
		angle_to_player = (PlayerManager.get_player_position(chosen_player_id) - params_dict.global_position).angle()
		params_dict["velocity"] = Vector2(cos(starting_angle + deviation), sin(starting_angle + deviation)) * params_dict["speed"]
		SimpleBulletManager.shoot_bullet(bullet_type, params_dict)
		deviation += distance_between_bullets

func bullet_hell_circle(bullet_type: String, total_bullet_number: int, bullet_params_list: Array) -> void:
	var distance_between_bullets: float = TAU / total_bullet_number
	var deviation: float = distance_between_bullets * randf()
	var params_dict: Dictionary
	var angle_to_player: float 
	var n_of_players: int = PlayerManager.get_number_of_players()
	var chosen_player_id: int
	for current_bullet_number in range(total_bullet_number):
		chosen_player_id = randi()%n_of_players
		params_dict = bullet_params_list[posmod(current_bullet_number, len(bullet_params_list))]
		angle_to_player = (PlayerManager.get_player_position(chosen_player_id) - params_dict.global_position).angle()
		params_dict["velocity"] = Vector2(cos(deviation), sin(deviation)) * params_dict["speed"]
		SimpleBulletManager.shoot_bullet(bullet_type, params_dict)
		deviation += distance_between_bullets

func bullet_wall(
	bullet_type: String, wall_starting_position: int, spawn_bullets: bool,
	bullet_wall_size: int, total_bullet_number: int, bullet_params_list: Array
) -> void:
	var starting_x_position_deviation: int = randi()%5
	while starting_x_position_deviation == bullet_wall_last_starting_x_position_deviation:
		starting_x_position_deviation = randi()%5
	bullet_wall_last_starting_x_position_deviation = starting_x_position_deviation
	var params_dict: Dictionary
	var distance_between_bullets = bullet_wall_size / total_bullet_number
	var starting_x_pos_increase = distance_between_bullets / 5
	var starting_bullet_x_position = starting_x_pos_increase * starting_x_position_deviation
	var can_be_health: bool = false
	for bullet_number in range(total_bullet_number):
		params_dict = bullet_params_list[posmod(bullet_number, len(bullet_params_list))]
		params_dict["global_position"] = Vector2(wall_starting_position + starting_bullet_x_position + distance_between_bullets * bullet_number, params_dict.bullet_y_position)
		params_dict["velocity"] = params_dict.direction * params_dict.base_speed
		if params_dict.global_position.x <= PlayerManager.get_player_position().x + 200 and params_dict.global_position.x >= PlayerManager.get_player_position().x - 200:
			can_be_health = true
		else:
			can_be_health = false
		if spawn_bullets:
			SimpleBulletManager.spawn_bullet(bullet_type, params_dict)
		else:
			SimpleBulletManager.shoot_bullet(bullet_type, params_dict)
