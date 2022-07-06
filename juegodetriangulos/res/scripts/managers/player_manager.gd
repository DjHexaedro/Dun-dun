# Helper class with player-related functions.
# Can be accessed from anywhere within the project
extends Node

var player: BasePlayer

func initialize_player(level_name: String, intro_cutscene: bool) -> void:
	var level_player_scene = load("res://juegodetriangulos/scenes/level_assets/%s/player.tscn" % level_name)
	if level_player_scene == null:
		level_player_scene = load("res://juegodetriangulos/scenes/level_assets/generic/player.tscn")
	player = level_player_scene.instance()
	get_tree().get_root().add_child(player)
	player.connect("player_begin_death", GameStateManager, "show_you_lost_screen")
	player.connect("player_begin_death", ArenaManager, "stop_music")
	player.connect("lamp_on", EnemyManager, "enemy_spawn")
	if not intro_cutscene:
		player.is_lamp_on = true
		player.light.visible = true
	yield(get_tree().create_timer(0.25), "timeout")
	player.enable_input = true

func get_player_node() -> BasePlayer:
	if player and player_exists():
		return player
	else:
		return log_error("get_player_node", null)
	
# No return type defined because it can be any type
func get_player_parameter(parameter_name: String):
	if player and player_exists():
		return player.get(parameter_name)
	else:
		log_error("get_player_parameter", null)

func get_player_max_health() -> int:
	if player and player_exists():
		return player.BASE_HEALTH
	else:
		return log_error("get_player_max_health", 0)

func get_player_health() -> int:
	if player and player_exists():
		return player.current_health
	else:
		return log_error("get_player_health", 0)

func set_player_position(new_position: Vector2) -> void:
	if player and player_exists():
		player.position = new_position
	else:
		log_error("set_player_position", false)

func get_player_position() -> Vector2:
	if player and player_exists():
		return player.position
	else:
		return log_error("get_player_position", Vector2.ZERO)

func get_player_old_position() -> Vector2:
	if player and player_exists():
		return player.old_position
	else:
		return log_error("get_player_old_position", Vector2.ZERO)

func set_player_score(new_score: int) -> void:
	if player and player_exists():
		player.current_score = new_score
		HudManager.update_current_score(player.current_score)
	else:
		log_error("set_player_score")

func get_player_score() -> int:
	if player and player_exists():
		return player.current_score
	else:
		return log_error("get_player_score", -1)

func set_player_velocity(velocity: Vector2) -> void:
	if player and player_exists():
		player.velocity = velocity
	else:
		log_error("set_player_velocity", -1)

func set_player_walking(walking: bool) -> void:
	if player and player_exists():
		if not player.always_show_hitbox:
			player.hitbox_marker_sprite.visible = walking
			player.animation_list.modulate = player.GRAPHICS_WALKING_COLOR if walking else player.GRAPHICS_DEFAULT_COLOR
		player.speed_multiplier = player.WALKING_SPEED_MULTIPLIER if walking else player.BASE_SPEED_MULTIPLIER
		player.get_node("animation_list").get_node("moving_animation").speed_scale = (
			player.WALKING_ANIMATION_SPEED_SCALE if walking else player.BASE_ANIMATION_SPEED_SCALE
		)
	else:
		log_error("set_player_walking")

func get_player_input_enabled() -> bool:
	if player and player_exists():
		return player.enable_input
	else:
		return log_error("get_player_allow_input", false)

func get_player_lamp_on() -> bool:
	if player and player_exists():
		return player.is_lamp_on
	else:
		return log_error("get_player_lamp_on", false)

func player_emit_lamp_on_signal() -> void:
	if player and player_exists():
		player.emit_lamp_on_signal()
	else:
		log_error("get_player_lamp_on", false)

func player_stand_still() -> void:
	if player and player_exists():
		player.stand_still()
	else:
		log_error("player_stand_still", false)

func player_exists():
	var player_ref = weakref(player)
	return player_ref.get_ref()

func reset_player() -> void:
	if player and player_exists():
		player.reset()
	else:
		log_error("reset_player")

func unload_player() -> void:
	if player and player_exists():
		player.unload()
	else:
		log_error("unload_player")

func damage_player(damage_source: Object, dmg: int = 1) -> void:
	if player and player_exists():
		player.get_hit(damage_source, dmg)
	else:
		log_error("damage_player")

func heal_player(heal_amount: int = 1) -> void:
	if player and player_exists():
		player.get_healed(heal_amount)
	else:
		log_error("heal_player")

func add_score(score: int) -> void:
	if player and player_exists():
		player.current_score += score
		HudManager.update_current_score(player.current_score)
	else:
		log_error("add_to_player_score")

# No return value type (both actual return value and return_value parameter)
# because they can both be any type
func log_error(function: String, return_value = false):
	return Utils.log_error("Tried to %s when player was null" % function, return_value)
