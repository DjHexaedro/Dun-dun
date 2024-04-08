# Helper class that creates and manages the state of all the powerups
# avaliable to the player when playing.
# Can be accessed from anywhere within the project
extends Node


const BASE_POWERUP_SCENE_PATH: String =\
	"res://juegodetriangulos/scenes/level_assets/%s/powerup.tscn"
const BASE_SCORE: int = 5
const POWERUP_SPAWN_TIME: int = 4
const BASE_POOL_SIZE: int = 3
const COMBO_INCREASE_INTERVAL: int = 5

var powerup_scene: PackedScene
var idle_powerup_list: Array = []
var active_powerup_list: Array = []
var powerup_timer: Timer = null
var perfect_powerups_combo: int = 0
var powerup_spawnpoint_reference: Dictionary = {}
var powerup_spawn_deviation: bool
var current_pool_size: int = BASE_POOL_SIZE
var dead_player_collected_crystals: Array = [1, 1]

func enable_powerups(
	enable_powerup_spawn_deviation: bool = true,
	powerup_type: String = Globals.LevelCodes.GENERIC
) -> void:
	perfect_powerups_combo = 0
	set_powerup_scene(BASE_POWERUP_SCENE_PATH % powerup_type)
	if GameStateManager.get_multiplayer_enabled():
		current_pool_size += BASE_POOL_SIZE
	set_powerup_pool()
	powerup_spawn_deviation = enable_powerup_spawn_deviation
	ComplexBulletManager.initializate_bullets({
		Globals.ComplexBulletTypes.POWERUP: 15
	})
	create_and_start_powerup_timer()

func disable_powerups() -> void:
	for powerup_id in active_powerup_list:
		instance_from_id(powerup_id).break_powerup(true)
	powerup_timer.stop()

func reset_powerups():
	if powerup_timer != null:
		powerup_timer.stop()
	perfect_powerups_combo = 0
	if len(active_powerup_list):
		var aux: Array = active_powerup_list.duplicate()
		for powerup_id in aux:
			remove_active_powerup(powerup_id)
	dead_player_collected_crystals = [1, 1]

func set_powerup_pool() -> void:
	var n_of_powerups: int = current_pool_size - len(idle_powerup_list)
	for _i in range(n_of_powerups):
		var new_powerup = powerup_scene.instance()
		get_tree().get_root().add_child(new_powerup)
		idle_powerup_list.append(new_powerup.get_instance_id())

func get_avaliable_powerup(player_id: int) -> BasePowerup:
	var avaliable_powerup_id: int = idle_powerup_list.pop_back()
	active_powerup_list.append(avaliable_powerup_id)
	var avaliable_powerup: BasePowerup = instance_from_id(avaliable_powerup_id)
	avaliable_powerup.set_allowed_player_id(player_id)
	return avaliable_powerup

func remove_active_powerup(active_powerup_id: int) -> void:
	var active_powerup = instance_from_id(active_powerup_id)
	active_powerup.set_global_position(Globals.OUT_OF_BOUNDS_POSITION)
	active_powerup.reset_powerup()
	free_spawn_point(active_powerup_id)
	active_powerup_list.erase(active_powerup_id)
	idle_powerup_list.append(active_powerup_id)

func clear_all_powerups() -> void:
	clear_powerup_list(idle_powerup_list)
	idle_powerup_list = []
	clear_powerup_list(active_powerup_list)
	active_powerup_list = []

	for key in powerup_spawnpoint_reference:
		instance_from_id(powerup_spawnpoint_reference[key]).being_used = false

	powerup_spawnpoint_reference = {}
	if powerup_timer and not powerup_timer.is_stopped():
		powerup_timer.stop()
	powerup_timer = null
	for child in get_children():
		remove_child(child)
		child.queue_free()

	dead_player_collected_crystals = [1, 1]

func clear_powerup_list(powerup_list: Array) -> void:
	for powerup_id in powerup_list:
		instance_from_id(powerup_id).unload()

func set_powerup_scene(powerup_scene_path: String) -> void:
	powerup_scene = load(powerup_scene_path)

func spawn_powerup() -> void:
	for player_id in range(PlayerManager.get_number_of_players()):
		if (
			not PlayerManager.is_player_alive(player_id) and
			dead_player_collected_crystals[player_id]%10 == 0
		): 
			PlayerManager.get_player_node(player_id).instance_revive_heart()
			increase_dead_player_collected_crystals(player_id)
		else:
			var valid_spawn_points: Array = ArenaManager.get_valid_spawn_points(
				player_id
			)
			if len(valid_spawn_points):
				_spawn_powerup(valid_spawn_points, player_id)

func _spawn_powerup(valid_spawn_points: Array, player_id: int) -> void: 
	var avaliable_powerup: BasePowerup = get_avaliable_powerup(player_id)
	var chosen_spawn_point: Position2D =\
		valid_spawn_points[randi()%len(valid_spawn_points)]
	chosen_spawn_point.being_used = true
	avaliable_powerup.set_position_from_spawn_point_data(
		chosen_spawn_point.global_position, powerup_spawn_deviation
	)
	powerup_spawnpoint_reference[
		avaliable_powerup.get_instance_id()
	] = chosen_spawn_point.get_instance_id()

func increase_dead_player_collected_crystals(player_id: int, amount: int = 1) -> void:
	dead_player_collected_crystals[player_id] += amount

func restore_dead_player_collected_crystals(player_id: int) -> void:
	dead_player_collected_crystals[player_id] = 1 

func free_spawn_point(powerup_id: int) -> void:
	instance_from_id(powerup_spawnpoint_reference[powerup_id]).being_used = false

func create_and_start_powerup_timer() -> void:
	powerup_timer = Timer.new()
	add_child(powerup_timer)
	powerup_timer.connect("timeout", self, "_on_powerup_spawner_timer_timeout")
	powerup_timer.set_wait_time(POWERUP_SPAWN_TIME)
	powerup_timer.start()

func reset_perfect_powerups_combo():
	perfect_powerups_combo = 0

func add_score(n_of_bullets: int) -> void:
	if n_of_bullets == 5:
		perfect_powerups_combo += 1
	else:
		reset_perfect_powerups_combo()
	var total_score: int =\
		pow(BASE_SCORE * n_of_bullets, 2) *\
		(int(perfect_powerups_combo / COMBO_INCREASE_INTERVAL) + 1)
	PlayerManager.add_score(total_score)

func start_powerup_timer() -> void:
	if exists_powerup_timer():
		powerup_timer.start()

func stop_powerup_timer() -> void:
	if exists_powerup_timer():
		powerup_timer.stop()

func _on_powerup_spawner_timer_timeout() -> void:
	spawn_powerup()

func exists_powerup_timer() -> WeakRef:
	var timer_ref: WeakRef = weakref(powerup_timer)
	return timer_ref.get_ref()
