# Helper class that manages the current state of the game (current active
# challenges, current level, etc).
# Can be accessed from anywhere within the project
extends Node

signal level_end
signal level_restart

onready var victoryscreenscene = preload(
	"res://juegodetriangulos/scenes/menu/victory_screen.tscn"
)
onready var youlostscreenscene = preload(
	"res://juegodetriangulos/scenes/menu/you_lost_screen.tscn"
)

const USES_SPECIAL_PLAYER_BOSS_CODE_LIST: Array = [
	Globals.LevelCodes.CHESSBOARD,
]

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
var multiplayer_enabled: bool = false
var score_multiplier: int = 1
var current_enemy: String = "0"
var current_player: String = Globals.LevelCodes.GENERIC
var match_history: Array = []


func set_debug(value: bool) -> void:
	debug = value 

func get_debug() -> bool:
	return debug

func set_difficulty_level(new_difficulty: int) -> void:
	difficulty_level = new_difficulty
	if difficulty_level == Globals.DifficultyLevels.HARD:
		clamp(score_multiplier + 2, 1, 99)

func get_difficulty_level() -> int:
	return difficulty_level

func set_one_hit_death(value: bool) -> void:
	one_hit_death = value
	score_multiplier = clamp(score_multiplier + (1 if value else -1), 1, 99)

func get_one_hit_death() -> bool:
	return one_hit_death

func set_only_perfect_grabs(value: bool) -> void:
	only_perfect_grabs = value
	score_multiplier = clamp(score_multiplier + (1 if value else -1), 1, 99)

func get_only_perfect_grabs() -> bool:
	return only_perfect_grabs

func set_missed_grabs_do_damage(value: bool) -> void:
	missed_grabs_do_damage = value
	score_multiplier = clamp(score_multiplier + (1 if value else -1), 1, 99)

func get_missed_grabs_do_damage() -> bool:
	return missed_grabs_do_damage

func set_edge_touching_does_damage(value: bool) -> void:
	edge_touching_does_damage = value
	score_multiplier = clamp(score_multiplier + (1 if value else -1), 1, 99)

func get_edge_touching_does_damage() -> bool:
	return edge_touching_does_damage 

func set_standing_still_does_damage(value: bool) -> void:
	standing_still_does_damage = value
	score_multiplier = clamp(score_multiplier + (1 if value else -1), 1, 99)

func get_standing_still_does_damage() -> bool:
	return standing_still_does_damage

func set_moving_does_damage(value: bool) -> void:
	moving_does_damage = value
	score_multiplier = clamp(score_multiplier + (1 if value else -1), 1, 99)

func get_moving_does_damage() -> bool:
	return moving_does_damage

func set_on_options_menu(value: bool) -> void:
	on_options_menu = value 

func get_on_options_menu() -> bool:
	return on_options_menu

func set_multiplayer_enabled(value: bool) -> void:
	multiplayer_enabled = value 

func get_multiplayer_enabled() -> bool:
	return multiplayer_enabled

func set_score_multiplier(value: int) -> void:
	score_multiplier = value 

func get_score_multiplier() -> int:
	return score_multiplier

func set_current_enemy(enemy_code: String) -> void:
	current_player = enemy_code if enemy_code in USES_SPECIAL_PLAYER_BOSS_CODE_LIST else Globals.LevelCodes.GENERIC
	current_enemy = enemy_code

func get_current_enemy() -> String:
	return current_enemy

func get_match_history() -> Array:
	return match_history

func _ready() -> void:
	Settings.connect("game_statistic_updated", self, "_on_game_statistic_updated")

func initialize_game_objects() -> void:
	match_history = []
	show_intro_cutscene = not Settings.get_game_statistic("is_lamp_on", false)
	ArenaManager.initialize_arena(current_enemy)
	PlayerManager.initialize_players(show_intro_cutscene, current_player)
	EnemyManager.initialize_enemy(current_enemy)
	if show_intro_cutscene:
		Utils.show_message()
	set_camera_focus(Settings.get_game_statistic("fighting_boss", false), false)
	Utils.hide_mouse_if_necessary()

func reset_game_objects() -> void:
	match_history = []
	ArenaManager.reset_arena()
	PlayerManager.reset_players()
	EnemyManager.reset_enemy()
	SimpleBulletManager.remove_all_active_bullets()
	ComplexBulletManager.remove_all_active_bullets()
	MinionManager.remove_all_active_minions()
	if GameStateManager.get_difficulty_level() != Globals.DifficultyLevels.HARDEST:
		PowerupManager.reset_powerups()
	set_camera_focus(Settings.get_game_statistic("fighting_boss", false), false)

func deinitialize_game_objects() -> void:
	PlayerManager.unload_players()
	EnemyManager.unload_enemy()
	SimpleBulletManager.clear_all_bullets()
	ComplexBulletManager.clear_all_bullets()
	MinionManager.clear_all_minions()
	ArenaManager.stop_music()
	ArenaManager.unload_arena()
	CameraManager.reset_camera()
	PowerupManager.clear_all_powerups()
	HudManager.disable_hud()

func show_victory_screen(level_index: int) -> void:
	var victory_screen: Node = victoryscreenscene.instance()
	get_tree().get_root().add_child(victory_screen)
	victory_screen.connect("victory_screen_hidden", self, "exit_to_map")
	Utils.disable_pause_node()
	victory_screen.show_victory_screen(level_index)

func show_you_lost_screen() -> void:
	var you_lost_screen: Node = youlostscreenscene.instance()
	get_tree().get_root().add_child(you_lost_screen)
	you_lost_screen.connect("exit_to_map", self, "exit_to_map")
	you_lost_screen.connect("try_again", self, "restart_level")
	for player in PlayerManager.get_player_list():
		player.connect("player_death", you_lost_screen, "pause_game")
	you_lost_screen.show_you_lost_screen()
	Utils.disable_pause_node()

func exit_to_map():
	clear_level()
	Utils.get_main_menu().show_main_menu()
	emit_signal("level_end")

func restart_level() -> void:
	emit_signal("level_restart")
	reset_game_objects()
	Utils.enable_pause_node()

func clear_level() -> void:
	deinitialize_game_objects()
	PowerupManager.clear_all_powerups()

func set_camera_focus(focus_arena: bool, smoothing: bool) -> void:
	if focus_arena:
		# CameraManager.set_camera_target(ArenaManager.get_current_location_node_path(), smoothing)
		ArenaManager.set_camera_focus(smoothing)
	else:
		CameraManager.set_camera_target(PlayerManager.get_player_node_path(), smoothing)

func update_match_history(event: String, additional_info: int = -1) -> void:
	match_history.append({
		"boss_phase": EnemyManager.get_enemy_current_boss_phase(),
		"boss_current_damage":
			EnemyManager.get_enemy_hardest_mode_current_fight_time()
			if difficulty_level == Globals.DifficultyLevels.HARDEST else
			EnemyManager.get_enemy_current_damage_taken(),
		"event": event,
		"additional_info": additional_info,
	})

func _on_game_statistic_updated(game_statistic: String, value) -> void:
	if game_statistic == "fighting_boss":
		set_camera_focus(value, true)
