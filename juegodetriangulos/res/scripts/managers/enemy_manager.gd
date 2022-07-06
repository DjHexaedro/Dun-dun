# Helper class with enemy-related functions.
# Can be accessed from anywhere within the project
extends Node


var enemy

func initialize_enemy(level_name: String) -> void:
	var level_enemy_scene = load("res://juegodetriangulos/scenes/level_assets/%s/enemy.tscn" % level_name)
	enemy = level_enemy_scene.instance()
	get_tree().get_root().add_child(enemy)

func get_enemy() -> BaseEnemy:
	if enemy and enemy_exists():
		return enemy
	else:
		return Utils.log_error("get_enemy", null)

func get_enemy_name() -> String:
	if enemy and enemy_exists():
		return enemy.DISPLAY_NAME
	else:
		return Utils.log_error("get_enemy_name", "N/A")

func get_enemy_position() -> Vector2:
	if enemy and enemy_exists():
		return enemy.position
	else:
		return Utils.log_error("get_enemy_position", Vector2.ZERO)

func get_enemy_current_damage_taken() -> int:
	if enemy and enemy_exists():
		return enemy.current_damage_taken
	else:
		return Utils.log_error("get_enemy_current_damage_taken", -1)

func get_enemy_current_boss_phase() -> int:
	if enemy and enemy_exists():
		return enemy.current_boss_phase
	else:
		return Utils.log_error("get_enemy_current_boss_phase", -1)

func get_enemy_max_health() -> int:
	if enemy and enemy_exists():
		return enemy.MAX_DAMAGE_TAKEN_PHASE * enemy.N_OF_PHASES
	else:
		return Utils.log_error("get_enemy_max_health", -1)

func enemy_spawn() -> void:
	yield(get_tree().create_timer(2, false), "timeout")
	if enemy_exists():
		enemy.spawn()

func enemy_exists() -> WeakRef:
	var enemy_ref = weakref(enemy)
	return enemy_ref.get_ref()

func damage_enemy(dmg_source: Node) -> void:
	if enemy and enemy_exists():
		enemy.get_hit(dmg_source)
	else:
		Utils.log_error("damage_enemy")

func reset_enemy() -> void:
	if enemy and enemy_exists():
		enemy.reset()
	else:
		Utils.log_error("reset_enemy")

func unload_enemy() -> void:
	if enemy and enemy != null:
		enemy.unload()
	else:
		Utils.log_error("unload_enemy")
