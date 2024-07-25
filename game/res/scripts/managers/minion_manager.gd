# Helper class that creates and manages the state of all the minions
# avaliable to the current boss when playing.
# Can be accessed from anywhere within the project
extends Node2D 

# This will be changed in the future as it references the minions of the first
# boss specifically
const MINION_SCENE_DICT: Dictionary = {
	"wide_shoot": preload("res://juegodetriangulos/scenes/level_assets/0/wide_shoot_minion.tscn"),
	"fully_automatic":  preload("res://juegodetriangulos/scenes/level_assets/0/fully_automatic_shoot_minion.tscn"),
}

var idle_minions: Dictionary = {}
var active_minions: Dictionary = {}


func initializate_minions(minion_types_dict: Dictionary) -> void:
	var new_minion
	var minion_scene
	for minion_type in minion_types_dict:
		if not idle_minions.get(minion_type, false):
			idle_minions[minion_type] = []
		var n_of_minions = clamp(minion_types_dict[minion_type] - len(idle_minions[minion_type]), 0, 20)
		minion_scene = MINION_SCENE_DICT[minion_type]
		for _i in range(n_of_minions):
			new_minion = create_minion(minion_scene)
			idle_minions[minion_type].append(new_minion.get_instance_id())

func clear_all_minions() -> void:
	for minion_type in idle_minions:
		for minion_id in idle_minions[minion_type]:
			instance_from_id(minion_id).queue_free()
		if active_minions.get(minion_type, false):
			for minion_id in active_minions[minion_type]:
				instance_from_id(minion_id).queue_free()
	active_minions = {}
	idle_minions = {}

func clear_active_minions() -> void:
	for minion_type in active_minions:
		for minion_id in active_minions[minion_type]:
			instance_from_id(minion_id).queue_free()
	active_minions = {}

func clear_idle_minions() -> void:
	for minion_type in idle_minions:
		for minion_id in idle_minions[minion_type]:
			instance_from_id(minion_id).queue_free()
	idle_minions = {}

func get_avaliable_minion(minion_type: String) -> Object:
	var avaliable_minion_id = idle_minions[minion_type].pop_back()
	if not active_minions.get(minion_type, false):
		active_minions[minion_type] = []
	active_minions[minion_type].append(avaliable_minion_id)
	return instance_from_id(avaliable_minion_id)

func remove_active_minion(minion_type: String, minion_id: int, reset: bool = false) -> void:
	instance_from_id(minion_id).despawn(reset)
	active_minions[minion_type].erase(minion_id)
	idle_minions[minion_type].append(minion_id)

func remove_all_active_minions(reset: bool = false) -> void:
	var active_minions_aux: Dictionary = active_minions.duplicate(true)
	for minion_type in active_minions_aux:
		for minion in active_minions_aux[minion_type]:
			remove_active_minion(minion_type, minion, reset)

func create_minion(minionscene: PackedScene) -> AnimatedSprite:
	var minion = minionscene.instance()
	return minion

func spawn_minion(minion_type: String, params_dict: Dictionary) -> void:
	var new_minion = get_avaliable_minion(minion_type)
	ArenaManager.get_current_location().add_child(new_minion)
	new_minion.set_position(Globals.OUT_OF_BOUNDS_POSITION)
	new_minion.spawn(params_dict)
