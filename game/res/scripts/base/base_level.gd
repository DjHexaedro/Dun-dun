# Base class for all levels in the game. Original we had an overworld map from
# which you chose which boss to fight, but now we have no such thing so I think
# this file will probably disappear in the not so distant future
extends Node

class_name BaseLevel

signal level_end
signal level_restart

var completed: bool
var max_score: int = -1

func _ready() -> void:
	completed = false
	connect("level_end", SimpleBulletManager, "_reenable_health_refill")
	connect("level_restart", SimpleBulletManager, "_reenable_health_refill")

func start_level() -> void:
	GameStateManager.initialize_game_objects(self)
	Utils.set_map_current_level_node(self)
	Utils.hide_mouse_if_necessary()
	Settings.save_current_level_state(completed, max_score, true)

func end_level(player_victory: bool = false) -> void:
	if player_victory:
		# It should work without the timer but for whatever reason the map
		# node also reads the input so it instantly re-enters the level if
		# you dismiss the screen with the enter key
		var timer = Utils.wait(0.0001)
		yield(timer, "timeout")
		Settings.save_game_statistic("is_lamp_on", false)
		Settings.save_game_statistic("fighting_boss", false)
		Settings.save_game_statistic("current_boss", -1)
	if not completed and player_victory:
		completed = player_victory
		if completed:
			$level_icon.modulate = Color(Globals.Colors.LEVEL_COMPLETED)
	Settings.save_current_level_state(completed, max_score, false)
	clear_level()
	Utils.set_map_current_level_node(null)
	var main_menu = get_tree().get_root().get_node("Main").get_node("main_menu")
	get_tree().get_root().get_node("map").queue_free()
	get_tree().paused = false
	main_menu.show_main_screen()
	emit_signal("level_end")
	

func restart_level() -> void:
	emit_signal("level_restart")
	GameStateManager.reset_game_objects()
	Utils.enable_pause_node()

func exit_to_map() -> void:
	# It should work without the timer but for whatever reason the map
	# node also reads the input so it instantly re-enters the level if
	# you dismiss the screen with the enter key
	var timer = Utils.wait(0.0001)
	yield(timer, "timeout")
	end_level(false)
	Utils.enable_pause_node()

func set_level_state(game_state: Dictionary) -> void:
	set_completion(game_state["completed"])
	set_max_score(game_state["max_score"])

func set_max_score(new_score: int) -> void:
	if new_score > max_score:
		max_score = new_score

func set_completion(completion: bool) -> void:
	completed = completion 
	if completed:
		$level_icon.modulate = Color(Globals.Colors.LEVEL_COMPLETED)

func clear_level() -> void:
	GameStateManager.deinitialize_game_objects()
	PowerupManager.clear_all_powerups()

func _on_victory_screen_hidden() -> void:
	Utils.enable_pause_node()
	end_level(true)

func _filter_spawn_points(point) -> bool:
	return point.enabled

