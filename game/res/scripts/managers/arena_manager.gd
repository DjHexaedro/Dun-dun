# Helper class with arena-related functions.
# Can be accessed from anywhere within the project
extends Node


var arena: Node
var current_location: Node
var spawning_zones: Array
var bgm_list: Array 
var currently_loaded_areas: Array

func initialize_arena(chosen_enemy: String) -> void:
	var level_arena_scene: PackedScene = load("res://juegodetriangulos/scenes/level_assets/map/map_areas/level%s_arena.tscn" % chosen_enemy)
	current_location = level_arena_scene.instance()
	arena = current_location
	get_tree().get_root().add_child(current_location)
	update_current_location()
	update_current_bgm()
	if Settings.get_game_statistic("fighting_boss", false):
		current_location.close_arena(false)
	else:
		start_music()

func get_arena() -> Node:
	return current_location

func get_arena_center() -> Vector2:
	return current_location.get_center()

func get_current_location() -> Node:
	if current_location and exists_current_location():
		return current_location
	else:
		return Utils.log_error("get_current_location", null)

func get_current_location_node_path() -> NodePath:
	if current_location and exists_current_location():
		return current_location.get_path()
	else:
		return Utils.log_error("get_current_location_node_path", null)

func get_location(location_name: String) -> Node:
	return current_location 

func set_camera_focus(smoothing: bool) -> void:
	current_location.set_camera_focus(smoothing)

func get_checkpoint_position(checkpoint_name: String = '') -> Vector2:
	if arena and exists_arena():
		if checkpoint_name:
			return arena.get_node("checkpoint_position").global_position
#			return arena.get_node(checkpoint_name).get_node("checkpoint_position").global_position
		else:
			return arena.get_node("checkpoint_position").global_position
#			return arena.get_node(Settings.get_game_statistic("current_player_checkpoint", "entrance_hall")).get_node("checkpoint_position").global_position
	else:
		return Utils.log_error("get_checkpoint_position", Vector2.ZERO)

func get_default_bgm() -> Node:
	return arena.get_node("bgm")

func enable_all_spawnpoints() -> void:
	current_location.manage_powerup_spawn_points(
		"top_left", ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"], true
	)
	current_location.manage_powerup_spawn_points(
		"top_right", ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"], true
	)
	current_location.manage_powerup_spawn_points(
		"bottom_left", ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"], true
	)
	current_location.manage_powerup_spawn_points(
		"bottom_right", ["spawn_point1", "spawn_point2", "spawn_point3", "spawn_point4"], true
	)

func disable_spawnpoints_from_enemy(area_name: String, spawn_point_list: Array) -> void:
	current_location.manage_powerup_spawn_points(area_name, spawn_point_list, false)

func get_valid_spawn_points(player_id: int = 0) -> Array:
	return current_location.get_valid_spawn_points(player_id)

func update_current_location(new_location_name: String = "") -> void:
	if not new_location_name:
		new_location_name = Settings.get_game_statistic("current_player_checkpoint", current_location.name)
	load_areas(current_location.areas_to_load)

func update_current_bgm(start_music: bool = false) -> void:
	if start_music:
		for bgm in bgm_list:
			bgm.stop()
	if current_location.has_method("get_bgm_to_play"):
		bgm_list = current_location.get_bgm_to_play()
	else:
		bgm_list = [current_location.get_node("bgm")]
	if start_music:
		start_music()

func start_music() -> void:
	for bgm in bgm_list:
		if bgm.get_stream_paused():
			bgm.set_stream_paused(false)
		else:
			bgm.play()

func stop_music() -> void:
	for bgm in bgm_list:
		bgm.set_stream_paused(true)

func unmute_phase_bgm(boss_phase: int) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BGM P%s" % boss_phase), false)

func exists_arena() -> WeakRef:
	var arena_ref = weakref(arena)
	return arena_ref.get_ref()

func exists_current_location() -> WeakRef:
	var current_location_ref = weakref(current_location)
	return current_location_ref.get_ref()

func reset_arena() -> void:
	if arena and arena != null:
		enable_all_spawnpoints()
		current_location.reset()
		for bgm in bgm_list:
			bgm.stop()
	else:
		Utils.log_error("reset_arena")

func load_areas(areas_to_load: Array) -> void:
	areas_to_load = [current_location.name]
	current_location.enable_map_area()
	currently_loaded_areas = areas_to_load

func unload_arena() -> void:
	if arena and arena != null:
		arena.queue_free()
	else:
		Utils.log_error("unload_arena")
