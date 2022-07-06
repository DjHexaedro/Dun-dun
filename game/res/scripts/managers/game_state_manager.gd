# Helper class that manages the current state of the game (current active
# challenges, current level, etc).
# Can be accessed from anywhere within the project
extends Node


onready var victoryscreenscene = preload("res://juegodetriangulos/scenes/menu/victory_screen.tscn")
onready var youlostscreenscene = preload("res://juegodetriangulos/scenes/menu/you_lost_screen.tscn")

var current_level: Object 
var debug: bool = false
var show_intro_cutscene: bool = true
var difficulty_level: int = 0
var one_hit_death: bool = false
var only_perfect_grabs: bool = false
var missed_grabs_do_damage: bool = false
var edge_touching_does_damage: bool = false
var standing_still_does_damage: bool = false
var moving_does_damage: bool = false
var on_options_menu: bool = false


func set_debug(value: bool) -> void:
	debug = value 

func get_debug() -> bool:
	return debug

func set_one_hit_death(value: bool) -> void:
	one_hit_death = value

func get_one_hit_death() -> bool:
	return one_hit_death

func set_only_perfect_grabs(value: bool) -> void:
	only_perfect_grabs = value

func get_only_perfect_grabs() -> bool:
	return only_perfect_grabs

func set_missed_grabs_do_damage(value: bool) -> void:
	missed_grabs_do_damage = value

func get_missed_grabs_do_damage() -> bool:
	return missed_grabs_do_damage

func set_edge_touching_does_damage(value: bool) -> void:
	edge_touching_does_damage = value

func get_edge_touching_does_damage() -> bool:
	return edge_touching_does_damage 

func set_standing_still_does_damage(value: bool) -> void:
	standing_still_does_damage = value

func get_standing_still_does_damage() -> bool:
	return standing_still_does_damage

func set_moving_does_damage(value: bool) -> void:
	moving_does_damage = value

func get_moving_does_damage() -> bool:
	return moving_does_damage

func set_on_options_menu(value: bool) -> void:
	on_options_menu = value 

func get_on_options_menu() -> bool:
	return on_options_menu

func initialize_game_objects(level: Object) -> void:
	var level_name = level.get_name()
	show_intro_cutscene = not Settings.get_game_statistic("is_lamp_on", false)
	PlayerManager.initialize_player(level_name, show_intro_cutscene)
	EnemyManager.initialize_enemy(level_name)
	ArenaManager.initialize_arena(level_name)
	if show_intro_cutscene:
		Utils.show_message()
	current_level = level

func reset_game_objects() -> void:
	PlayerManager.reset_player()
	EnemyManager.reset_enemy()
	SimpleBulletManager.remove_all_active_bullets()
	ComplexBulletManager.remove_all_active_bullets()
	MinionManager.remove_all_active_minions()
	ArenaManager.reset_arena()
	HudManager.reset_hud()
	Utils.remove_score_labels()
	if GameStateManager.get_difficulty_level() != Globals.DifficultyLevels.HARDEST:
		PowerupManager.reset_powerups()

func deinitialize_game_objects() -> void:
	PlayerManager.unload_player()
	EnemyManager.unload_enemy()
	SimpleBulletManager.clear_all_bullets()
	ComplexBulletManager.clear_all_bullets()
	MinionManager.clear_all_minions()
	ArenaManager.unload_arena()
	HudManager.disable_hud()
	Utils.remove_score_labels()
	CameraManager.clear_camera_target()
	PowerupManager.clear_all_powerups()
	current_level = null

func show_victory_screen() -> void:
	var victory_screen: Node = victoryscreenscene.instance()
	get_tree().get_root().add_child(victory_screen)
	Utils.disable_pause_node()
	victory_screen.connect("victory_screen_hidden", current_level, "_on_victory_screen_hidden")
	victory_screen.show_victory_screen()

func show_you_lost_screen() -> void:
	var you_lost_screen: Node = youlostscreenscene.instance()
	get_tree().get_root().add_child(you_lost_screen)
	you_lost_screen.connect("exit_to_map", current_level, "exit_to_map")
	you_lost_screen.connect("try_again", current_level, "restart_level")
	PlayerManager.get_player_node().connect("player_death", you_lost_screen, "pause_game")
	you_lost_screen.show_you_lost_screen()
	Utils.disable_pause_node()

func set_difficulty_level(new_difficulty: int) -> void:
	difficulty_level = new_difficulty

func get_difficulty_level() -> int:
	return difficulty_level

func enable_powerups() -> void:
	PowerupManager.enable_powerups(current_level.get_name())
