# Helper class with arena-related functions.
# Can be accessed from anywhere within the project
extends Node

signal doors_closed


var arena: Node
var spawning_zones: Array
var bgm: AudioStreamPlayer
var closed_doors_texture: Texture = preload("res://juegodetriangulos/res/sprites/levels/0/arena/arena_bg_closed_doors.png")

func initialize_arena(level_name: String) -> void:
	var level_arena_scene = load("res://juegodetriangulos/scenes/level_assets/%s/arena.tscn" % level_name)
	if level_arena_scene == null:
		level_arena_scene = load("res://juegodetriangulos/scenes/level_assets/generic/arena.tscn")
	arena = level_arena_scene.instance()
	get_tree().get_root().add_child(arena)
	arena.position = Globals.Positions.SCREEN_CENTER
	spawning_zones = arena.get_node("powerup_spawning_zones").get_children()
	PlayerManager.set_player_position(get_starting_position())
	bgm = arena.get_node("bgm")
	if Settings.get_game_statistic("fighting_boss", false):
		close_arena(false)
	else:
		arena.get_node("hall_bgm").play()

func close_arena(show_cutscene: bool = true) -> void:
	arena.get_node("hall_bgm").stop()
	arena.get_node("background").texture = closed_doors_texture
	arena.get_node("background").get_node("left_limits").get_node("left_wall3").set_deferred("disabled", false)
	if show_cutscene:
		PlayerManager.player_stand_still()
		CameraManager.shake_screen(null, 0.675, 0.5)
		var doors_closed_audio: AudioStreamPlayer = arena.get_node("doors_closed_audio")
		doors_closed_audio.play()
		yield(doors_closed_audio, "finished")
		PlayerManager.player.enable_input = true
		emit_signal("doors_closed")

func get_arena() -> Node:
	if arena and exists_arena():
		return arena
	else:
		return Utils.log_error("get_arena", null)

func get_arena_center() -> Vector2:
	if arena and exists_arena():
		return arena.get_node("fighting_starting_position").global_position
	else:
		return Utils.log_error("get_arena_center", Vector2.ZERO)

func get_valid_spawn_points() -> Array:
	var valid_spawn_points = []
	for zone in spawning_zones:
		if zone.enabled:
			var zone_spawn_points = zone.get_node("spawn_point_list").get_children()
			for spawn_point in zone_spawn_points:
				if spawn_point.enabled and not spawn_point.being_used:
					valid_spawn_points.append(spawn_point)
	return valid_spawn_points

func get_starting_position() -> Vector2:
	if arena and exists_arena():
		if Settings.get_game_statistic("fighting_boss", false):
			return arena.get_node("fighting_starting_position").global_position
		else:
			return arena.get_node("initial_starting_position").global_position
	else:
		return Utils.log_error("get_starting_position", Vector2.ZERO)

func enable_all_spawnpoints() -> void:
	manage_powerup_spawn_points("top_left", ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"], true)
	manage_powerup_spawn_points("top_right", ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"], true)
	manage_powerup_spawn_points("bottom_left", ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"], true)
	manage_powerup_spawn_points("bottom_right", ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"], true)

func disable_spawnpoints_from_enemy(area_name: String, spawn_point_list: Array) -> void:
	manage_powerup_spawn_points(area_name, spawn_point_list, false)

func manage_powerup_spawn_points(area_name: String, spawn_point_name_list: Array, enabled: bool) -> void:
	var area = arena.get_node("powerup_spawning_zones").get_node(area_name)
	for spawn_point_name in spawn_point_name_list:
		var spawn_point = area.get_node("spawn_point_list").get_node(spawn_point_name)
		spawn_point.enabled = enabled 

func start_music() -> void:
	if bgm.get_stream_paused():
		bgm.set_stream_paused(false)
	else:
		bgm.play()

func stop_music() -> void:
	bgm.set_stream_paused(true)

func exists_arena() -> WeakRef:
	var arena_ref = weakref(arena)
	return arena_ref.get_ref()

func reset_arena() -> void:
	if arena and arena != null:
		PlayerManager.set_player_position(get_starting_position())
		enable_all_spawnpoints()
		bgm.stop()
	else:
		Utils.log_error("reset_arena")

func unload_arena() -> void:
	if arena and arena != null:
		arena.queue_free()
	else:
		Utils.log_error("unload_arena")
