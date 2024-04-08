# Base class for all the bosses in the game. Will probably change
# as more bosses are added and I find out which behaviors are common
# and which specific of each boss
extends Node2D 

class_name BaseEnemy

signal enemy_death
signal change_boss_phase 
signal enable_all_spawnpoints
signal disable_spawnpoints(area_name, spawn_point_list)

const WAIT_TIME_BETWEEN_ATTACKS: int = 1

export (String) var DISPLAY_NAME 
export (int) var N_OF_PHASES
export (int) var MAX_DAMAGE_TAKEN_PHASE

var attack_params: Dictionary
var secondary_attack_thread: Thread = Thread.new()
var current_damage_taken: int = 0
var can_get_hit: bool = true
var can_attack: bool
var can_move: bool
var took_damage: bool
var is_moving: bool
var attack_list: Array = []
var current_attack: int = 0
var chosen_attack: String = ""
var chosen_attack_id: int = -1
var chosen_attack_params: Dictionary
var move_to_position: Vector2 = Vector2.ZERO
var allowed_move_positions: Dictionary = {}
var current_boss_phase: int = 1
var continue_attacking: bool = false
var secondary_attack_enabled: bool = false
var normal_mode: bool = false 
var hard_mode: bool = false
var hardest_mode: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var time_between_attacks_timer: Timer = Timer.new()
var is_waiting_to_begin_next_attack: bool = false


func _ready() -> void:
	rng.randomize()
	can_attack = false
	can_move = false
	add_child(time_between_attacks_timer)
	time_between_attacks_timer.set_one_shot(true)
	time_between_attacks_timer.set_wait_time(WAIT_TIME_BETWEEN_ATTACKS)
	time_between_attacks_timer.connect("timeout", self, "begin_next_attack")
	setup_attack_constants()
	connect("change_boss_phase", self, "start_next_attack_delay")
	connect("finished_moving", self, "begin_next_attack")
	connect("enemy_death", self, "enemy_died")
	connect("disable_spawnpoints", ArenaManager, "disable_spawnpoints_from_enemy")
	connect("enable_all_spawnpoints", ArenaManager, "enable_all_spawnpoints")

func reset() -> void:
	can_attack = false
	can_move = false
	current_attack = 0
	current_damage_taken = 0
	current_boss_phase = 1
	continue_attacking = false
	secondary_attack_enabled = false
	chosen_attack = ""
	chosen_attack_params = {}
	time_between_attacks_timer.stop()
	secondary_attack_thread.wait_to_finish()
	setup_attack_constants()

func spawn() -> void:
	if GameStateManager.debug:
		Utils.log_error("Spawn method not defined")

func enemy_died() -> void:
	GameStateManager.show_victory_screen()

func get_hit(dmg_source: BaseBullet) -> void:
	if can_get_hit:
		current_damage_taken += dmg_source.damage
		if GameStateManager.get_debug():
			print('Enemy got hit by %s. Current health: %s Current phase: %s' % [dmg_source.name, MAX_DAMAGE_TAKEN_PHASE - current_damage_taken, current_boss_phase])
		if current_damage_taken >= MAX_DAMAGE_TAKEN_PHASE:
			if secondary_attack_thread.is_active():
				secondary_attack_thread.wait_to_finish()
			if current_boss_phase >= N_OF_PHASES:
				emit_signal("enemy_death")
			else:
				change_boss_phase(current_boss_phase + 1)
				MinionManager.remove_all_active_minions()
		update_hud_health()

func change_boss_phase(new_boss_phase: int) -> void:
	current_boss_phase = new_boss_phase
	current_damage_taken = 0
	continue_attacking = false
	secondary_attack_enabled = false
	emit_signal("change_boss_phase")

func move(new_position: Vector2 = Vector2.ZERO) -> void:
	move_to_position = new_position
	if not move_to_position:
		move_to_position = allowed_move_positions[randi()%int(len(allowed_move_positions))]
		while move_to_position == position:
			move_to_position = allowed_move_positions[randi()%int(len(allowed_move_positions))]
	can_move = false
	is_moving = true

func attack() -> void:
	chosen_attack = attack_list[current_attack]
	chosen_attack_id = randi()%999999
	chosen_attack_params = attack_params.get(chosen_attack, {})
	can_attack = false
	continue_attacking = true
	if chosen_attack_params.has("SPAWN_POINTS_TO_DISABLE"):
		for region in chosen_attack_params.SPAWN_POINTS_TO_DISABLE.keys():
			emit_signal("disable_spawnpoints", region, chosen_attack_params.SPAWN_POINTS_TO_DISABLE[region])
	call(chosen_attack, chosen_attack_params)

func start_next_attack_delay() -> void:
	if chosen_attack_params.has("MOVE_TO"):
		move(chosen_attack_params.MOVE_TO)
	else:
		time_between_attacks_timer.start()
	is_waiting_to_begin_next_attack = true

func begin_next_attack() -> void:
	if is_waiting_to_begin_next_attack:
		is_waiting_to_begin_next_attack = false
		emit_signal("enable_all_spawnpoints")
		current_attack = current_boss_phase - 1
		attack()

func unload() -> void:
	get_tree().get_root().remove_child(self)
	queue_free()

# Creates a dictionary with the data for each attack (number of bullets, their
# speed, type, etc). Not actually constants because of the way I programmed the
# difficulties for each boss. This function is overloaded on each difficulty
# file for each boss, each just adding their parameters to the dictionary.
func setup_attack_constants() -> void:
	attack_params = {}

func update_hud_health() -> void:
	HudManager.update_enemy_health(current_damage_taken, current_boss_phase, MAX_DAMAGE_TAKEN_PHASE * 5)

func _on_movement_delay_timeout() -> void:
	can_move = true
	is_moving = false
