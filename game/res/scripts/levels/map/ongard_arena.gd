# Script containing the code related to the arena for the Ongard boss fight
extends BaseMapArea

signal level0_fight_started

onready var bgm: AudioStreamPlayer = $bgm
onready var bgm_phase2: AudioStreamPlayer = $bgm_phase2
onready var bgm_phase3: AudioStreamPlayer = $bgm_phase3
onready var bgm_phase4: AudioStreamPlayer = $bgm_phase4
onready var bgm_phase5: AudioStreamPlayer = $bgm_phase5
onready var doors_closed_audio: AudioStreamPlayer = $doors_closed_audio
onready var enemy: Node2D = $enemy
onready var powerup_spawning_zones: Node2D = $powerup_spawning_zones
onready var background_sprite: Sprite = $sprite
onready var show_score_screen_area: Area2D = $show_score_trigger

const SCORE_PANEL_TEXT: String = "Your last achieved score is\n%s\nYour top score is\n%s"
const ENEMY_ID: int = 0

var spawning_zones_list: Array
var open_doors_texture: Texture = preload("res://juegodetriangulos/res/sprites/levels/0/arena/arena_bg_open_doors.png")
var closed_doors_texture: Texture = preload("res://juegodetriangulos/res/sprites/levels/0/arena/arena_bg_closed_doors.png")
var enemy_already_defeated: bool = false

func _ready():
	areas_to_load = ["entrance_hall", "after_ongard_hall"]
	spawning_zones_list = powerup_spawning_zones.get_children()
#	enemy_already_defeated = Settings.get_game_statistic("level0_enemy_defeated", false)
	GameStateManager.connect("level_end", self, "_on_level_reload")
	GameStateManager.connect("level_restart", self, "_on_level_reload")
	if enemy_already_defeated:
		_on_enemy_despawn()
	else:
		enemy.connect("enemy_death", self, "_on_enemy_death")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BGM P2"), true)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BGM P3"), true)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BGM P4"), true)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BGM P5"), true)

func get_enemy_positions_list() -> Dictionary:
	return {
		"global": {
			SCREEN_CENTER = global_position,
			TOP_Y =  global_position.y - 432,
			BOTTOM_Y = global_position.y + 432,
			CENTER_Y = global_position.y,
			LEFT_X = global_position.x - 768,
			RIGHT_X = global_position.x + 768,
			CENTER_X = global_position.x,
		},
		"local": {
			SCREEN_CENTER = Vector2(0, 0),
			TOP_Y = -432,
			BOTTOM_Y = 432,
			CENTER_Y = 0,
			LEFT_X = -768,
			RIGHT_X = 768,
			CENTER_X = 0,
		}
	}

func start_boss_fight(temporary: bool = false) -> void:
	close_arena()
	yield(self, "level0_fight_started")
	EnemyManager.setup_enemy("level0")
	enemy.connect("enemy_death", self, "_on_enemy_death")
	enemy.connect("enemy_despawn", self, "_on_enemy_despawn")
	if not temporary:
		Settings.save_game_statistic("fighting_boss", true)
		Settings.save_game_statistic("current_boss", ENEMY_ID)
	else:
		GameStateManager.set_camera_focus(true, false)
	if PlayerManager.get_player_lamp_on():
		PlayerManager.player_emit_lamp_on_signal()

func open_arena(show_cutscene: bool = true) -> void:
	manage_arena_open_state(show_cutscene, true)

func close_arena(show_cutscene: bool = true) -> void:
	manage_arena_open_state(show_cutscene, false)

func manage_arena_open_state(show_cutscene: bool = true, open: bool = true) -> void:
	background_sprite.texture = open_doors_texture if open else closed_doors_texture
	background_sprite.get_node("left_gate_limits").get_node("collision").set_deferred("disabled", open)
	background_sprite.get_node("right_gate_limits").get_node("collision").set_deferred("disabled", open)
	if show_cutscene:
		for player_id in range(PlayerManager.get_number_of_players()):
			PlayerManager.player_stand_still(player_id)
		CameraManager.shake_screen(null, 0.675, 0.5)
		doors_closed_audio.play()
		yield(doors_closed_audio, "finished")
		for player in PlayerManager.get_player_list():
			player.enable_input = true
		if not open:
			emit_signal("level0_fight_started")
		manage_lights(open)

func manage_powerup_spawn_points(area_name: String, spawn_point_name_list: Array, enabled: bool) -> void:
	var area = powerup_spawning_zones.get_node(area_name)
	for spawn_point_name in spawn_point_name_list:
		var spawn_point = area.get_node("spawn_point_list").get_node(spawn_point_name)
		spawn_point.enabled = enabled 

func get_valid_spawn_points(player_id: int = 0) -> Array:
	var valid_spawn_points: Array = []
	for zone in spawning_zones_list:
		if not player_id in zone.disabled_for:
			var zone_spawn_points = zone.get_node("spawn_point_list").get_children()
			for spawn_point in zone_spawn_points:
				if spawn_point.enabled and not spawn_point.being_used:
					valid_spawn_points.append(spawn_point)
	return valid_spawn_points

func get_bgm_to_play() -> Array:
	if enemy_already_defeated:
		return [ArenaManager.get_default_bgm()]
	else:
		return [bgm, bgm_phase2, bgm_phase3, bgm_phase4, bgm_phase5]

func manage_lights(enabled: bool) -> void:
	var light_list: Array = get_tree().get_nodes_in_group("on_level0_enemy_despawn")
	for light in light_list:
		light.visible = enabled 

func reset() -> void:
	manage_arena_open_state(false, enemy_already_defeated)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BGM P2"), true)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BGM P3"), true)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BGM P4"), true)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BGM P5"), true)

func _on_enemy_death() -> void:
	enemy_already_defeated = true

func _on_enemy_despawn() -> void:
	manage_lights(true)
	show_score_screen_area.enable(
		SCORE_PANEL_TEXT % [Settings.get_game_statistic("level_scores", 0, "level0_last"),
		Settings.get_game_statistic("level_scores", 0, "level0_top")]
	)

func _on_level_reload() -> void:
	if enemy_already_defeated:
		_on_enemy_despawn()
