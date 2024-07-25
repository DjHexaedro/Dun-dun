# Helper class with player-related functions.
# Can be accessed from anywhere within the project
extends Node

const BASE_HEALTH: int = 3

var player_list: Array
var player_health: int
var current_score: int

func instance_player(player_type: String) -> BasePlayer:
	var level_player_scene: PackedScene = load(
		"res://juegodetriangulos/scenes/level_assets/%s/player.tscn"
		% player_type
	)
	var player = level_player_scene.instance()
	get_tree().get_root().add_child(player)
	return player

func initialize_players(_intro_cutscene: bool, player_type: String = Globals.LevelCodes.GENERIC) -> void:
	player_list = []
	player_health = BASE_HEALTH
	initialize_player(player_type)
	if GameStateManager.get_multiplayer_enabled():
		initialize_player(player_type)

func initialize_player(player_type: String) -> void:
	var player = instance_player(player_type)
	player.connect("player_begin_death", GameStateManager, "show_you_lost_screen")
	player.connect("player_begin_death", ArenaManager, "stop_music")
	player.light.visible = true
	yield(get_tree().create_timer(0.25), "timeout")
	player.set_player_id(len(player_list))
	player_list.append(player)
	set_player_position(ArenaManager.get_arena_center(), player.player_id)

func get_player_list() -> Array:
	return player_list

func get_random_player_id(except: Array = [-1]) -> int:
	var allowed_player_ids: Array = []

	for player_id in range(len(player_list)):
		if not player_id in except:
			allowed_player_ids.append(player_id)

	var random_player_id: int = allowed_player_ids[randi()%len(allowed_player_ids)]
	
	return random_player_id

func get_hittable_players() -> Array:
	var hittable_players: Array = []
	for player in player_list:
		if player.can_be_hit():
			hittable_players.append(player)
	return hittable_players

func get_player_node(player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> BasePlayer:
	if player_list and player_exists(player_id):
		return player_list[player_id]
	else:
		return log_error("get_player_node", null)
	
# No return type defined because it can be any type
func get_player_parameter(parameter_name: String, player_id: int = Globals.PlayerIDs.PLAYER_ONE):
	if player_list and player_exists(player_id):
		return player_list[player_id].get(parameter_name)
	else:
		log_error("get_player_parameter", null)

func get_player_max_health(player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> int:
	if player_list and player_exists(player_id):
		return player_list[player_id].BASE_HEALTH
	else:
		return log_error("get_player_max_health", 0)

func get_player_health() -> int:
	return player_health

func get_player_type(player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> String:
	if player_list and player_exists(player_id):
		return player_list[player_id].player_type
	else:
		return log_error("get_player_type", "unknown")

func set_player_position(new_position: Vector2, player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> void:
	if player_list and player_exists(player_id):
		player_list[player_id].position = new_position
	else:
		log_error("set_player_position", false)

func get_player_position(player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> Vector2:
	if player_list and player_exists(player_id):
		return player_list[player_id].position
	else:
		return log_error("get_player_position", Vector2.ZERO)

func get_player_global_position(player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> Vector2:
	if player_list and player_exists(player_id):
		return player_list[player_id].global_position
	else:
		return log_error("get_player_global_position", Vector2.ZERO)

func get_player_old_position(player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> Vector2:
	if player_list and player_exists(player_id):
		return player_list[player_id].old_position
	else:
		return log_error("get_player_old_position", Vector2.ZERO)

func set_player_score(new_score: int) -> void:
	current_score = new_score

func get_player_score() -> int:
	return current_score

func set_player_velocity(velocity: Vector2, player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> void:
	if player_list and player_exists(player_id):
		player_list[player_id]._player_move(velocity)
	else:
		log_error("set_player_velocity", -1)

func set_player_walking(walking: bool, player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> void:
	if player_list and player_exists(player_id):
		player_list[player_id]._player_walk(walking)
	else:
		log_error("set_player_walking")

func set_player_velocity_touch(relative: Vector2, player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> void:
	if player_list and player_exists(player_id):
		player_list[player_id]._player_move_touch(relative)
	else:
		log_error("set_player_velocity", -1)

func set_player_walking_touch(walking: bool, player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> void:
	if player_list and player_exists(player_id):
		player_list[player_id]._player_walk_touch(walking)
	else:
		log_error("set_player_walking")

func get_player_input_enabled(player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> bool:
	if player_list and player_exists(player_id):
		return player_list[player_id].enable_input
	else:
		return log_error("get_player_allow_input", false)

func get_player_lamp_on(player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> bool:
	if player_list and player_exists(player_id):
		return player_list[player_id].is_lamp_on
	else:
		return log_error("get_player_lamp_on", false)

func get_player_node_path(player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> NodePath:
	if player_list and player_exists(player_id):
		return player_list[player_id].get_path()
	else:
		return log_error("get_player_lamp_on", null)

func player_emit_lamp_on_signal(player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> void:
	if player_list and player_exists(player_id):
		player_list[player_id].emit_lamp_on_signal()
	else:
		log_error("get_player_lamp_on", false)

func player_stand_still(player_id: int = Globals.PlayerIDs.PLAYER_ONE) -> void:
	if player_list and player_exists(player_id):
		player_list[player_id].stand_still()
	else:
		log_error("player_stand_still", false)

func player_exists(player_id: int = Globals.PlayerIDs.PLAYER_ONE):
	if len(player_list) and player_id < len(player_list):
		var player_ref = weakref(player_list[player_id])
		return player_ref.get_ref()
	else:
		return false

func reset_players() -> void:
	for player in player_list:
		player.reset()
	player_health = BASE_HEALTH

func unload_players() -> void:
	var aux_list: Array = player_list.duplicate()
	for player in aux_list:
		player_list.erase(player)
		player.unload()

func damage_player(damage_source: Object, player_id: int = Globals.PlayerIDs.PLAYER_ONE, dmg: int = 1) -> void:
	if player_list and player_exists(player_id):
		player_list[player_id].get_hit(damage_source, dmg)
	else:
		log_error("damage_player")

func player_increase_health(health_increase: int = 1) -> void:
	player_health = clamp(player_health + health_increase, 0, BASE_HEALTH)
	update_player_list_idle_animation_speed()

func player_lose_health(dmg: int = 1) -> void:
	player_health = (
		0 if GameStateManager.get_one_hit_death() else (player_health - dmg)
	)
	update_player_list_idle_animation_speed()

func heal_player() -> void:
	if player_health == BASE_HEALTH:
		GameStateManager.update_match_history(Globals.MatchEvents.PLAYER_HEAL_AS_SCORE)
	elif not GameStateManager.multiplayer_enabled:
		GameStateManager.update_match_history(Globals.MatchEvents.PLAYER_HEALED)
		player_list[Globals.PlayerIDs.PLAYER_ONE].get_healed()

func update_player_list_idle_animation_speed() -> void:
	for player in player_list:
		player.update_idle_animation_speed(player_health)

func can_player_be_hit(player_id: int) -> bool:
	if player_list and player_exists(player_id):
		return player_list[player_id].can_be_hit()
	else:
		return log_error("can_player_be_hit", false)

func is_player_alive(player_id: int) -> bool:
	if player_list and player_exists(player_id):
		return player_list[player_id].alive
	else:
		return log_error("is_player_alive", false)

func all_players_are_dead() -> bool:
	for player in player_list:
		if player.alive:
			return false
	return true

func manage_player_light(on: bool) -> void:
	for player in player_list:
		player.manage_light(on)

func get_number_of_players() -> int:
	if player_list:
		return len(player_list)
	else:
		return log_error("get_number_of_players", -1)

func revive_player(player_id: int) -> void:
	if player_list and player_exists(player_id):
		player_list[player_id].revive()
	else:
		log_error("revive_player")

# No return value type (both the actual return value and
# the return_value parameter) because they can be of any type
func log_error(function: String, return_value = false):
	return Utils.log_error(
		"Tried to %s when player was null" % function, return_value
	)
