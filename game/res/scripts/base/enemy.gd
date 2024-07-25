# Base class for all the bosses in the game. Will probably change
# as more bosses are added and I find out which behaviors are common
# and which specific of each boss
extends Node2D 

class_name BaseEnemy

signal enemy_death
signal change_boss_phase 
signal disable_spawnpoints(area_name, spawn_point_list)

const WAIT_TIME_BETWEEN_ATTACKS: int = 1
const TIME_UNTIL_HARDEST_ATTACKS: int = 30

export (String) var DISPLAY_NAME
export (int) var N_OF_PHASES
export (int) var MAX_DAMAGE_TAKEN_PHASE
export (int) var ENEMY_ID
export (float) var HARDEST_MODE_TOTAL_FIGHT_TIME

onready var idle_animation: AnimatedSprite = $idle_animation
onready var on_hit_animation: AnimatedSprite = $on_hit_animation
onready var spawn_animation: AnimatedSprite = $spawn_animation
onready var got_hit_animation: AnimatedSprite = $got_hit_animation
onready var special_animation: AnimatedSprite = $special_animation

var attack_params: Dictionary
var secondary_attack_thread: Thread = Thread.new()
var current_damage_taken: int = 0
var can_get_hit: bool = true
var can_attack: bool
var can_move: bool
var is_moving: bool
var attack_list: Array = []
var current_attack: int = 0
var chosen_attack: String = ""
var chosen_attack_params: Dictionary
var move_to_position: Vector2 = Vector2.ZERO
var allowed_move_positions: Dictionary = {}
var current_boss_phase: int = 1
var continue_attacking: bool = false
var secondary_attack_enabled: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var time_between_attacks_timer: Timer = Timer.new()
var is_waiting_to_begin_next_attack: bool = false
var hardest_mode_time_until_next_stage_timer: Timer = Timer.new()
var hardest_mode_current_fight_time: float = 0.0
var hardest_mode_current_attack_stage: int = 0
var hardest_mode_functions_to_call: Dictionary = {}
var is_defeated: bool = false
var positions_list: Dictionary
var main_attack_timer: Timer
var secondary_attack_timer: Timer
var hardest_mode_accumulated_score: int = 0
var hit_animation_intensity: int = 1
var difficulty_attacks_dict: Dictionary = {
	Globals.DifficultyLevels.NORMAL: "set_normal_mode",
	Globals.DifficultyLevels.HARD: "set_hard_mode",
	Globals.DifficultyLevels.HARDEST: "set_hardest_mode",
}

func _ready() -> void:
	rng.randomize()
	can_get_hit = true
	can_attack = false
	can_move = false
	positions_list = get_parent().get_enemy_positions_list()
	main_attack_timer = Utils.get_main_attack_timer()
	secondary_attack_timer = Utils.get_secondary_attack_timer()
	add_child(time_between_attacks_timer)
	time_between_attacks_timer.set_one_shot(true)
	time_between_attacks_timer.set_wait_time(WAIT_TIME_BETWEEN_ATTACKS)
	time_between_attacks_timer.connect("timeout", self, "begin_next_attack")
	hardest_mode_time_until_next_stage_timer.set_one_shot(false)
	add_child(hardest_mode_time_until_next_stage_timer)
	hardest_mode_time_until_next_stage_timer.connect(
		"timeout", self, "_on_hardest_mode_time_until_next_stage_timer_timeout"
	)
	setup_attack_constants()
	connect("change_boss_phase", self, "start_next_attack_delay")
	connect("enemy_death", self, "enemy_died")
	connect("disable_spawnpoints", ArenaManager, "disable_spawnpoints_from_enemy")
	call(difficulty_attacks_dict[GameStateManager.get_difficulty_level()])

func reset() -> void:
	can_get_hit = true
	can_attack = false
	can_move = false
	current_attack = 0
	current_damage_taken = 0
	current_boss_phase = 1
	hit_animation_intensity = 1
	continue_attacking = false
	secondary_attack_enabled = false
	chosen_attack = ""
	chosen_attack_params = {}
	time_between_attacks_timer.stop()
	if secondary_attack_thread.is_active():
		secondary_attack_thread.wait_to_finish()
	hardest_mode_current_fight_time = 0.0
	hardest_mode_current_attack_stage = 0
	setup_attack_constants()

func spawn() -> void:
	spawn_animation.play()

func enemy_died() -> void:
	is_defeated = true
	continue_attacking = false
	GameStateManager.update_match_history(Globals.MatchEvents.BOSS_DEFEATED)
	Settings.save_game_statistic("level%s_enemy_defeated" % ENEMY_ID, true)
	var current_difficulty: int = GameStateManager.get_difficulty_level()
	if current_difficulty == Globals.DifficultyLevels.HARDEST:
		Settings.increase_game_statistic("level%s_hardest_times_won" % ENEMY_ID, 1)
	if current_difficulty == Globals.DifficultyLevels.HARD:
		Settings.increase_game_statistic("level%s_hard_times_won" % ENEMY_ID, 1)
	else:
		Settings.increase_game_statistic("level%s_normal_times_won" % ENEMY_ID, 1)
	Settings.save_game_statistic(
		"level_scores", PlayerManager.get_player_score(), "level%s_last" % ENEMY_ID
	)
	if Settings.get_game_statistic("level_scores", -1, "level%s_top" % ENEMY_ID) < PlayerManager.get_player_score():
		Settings.save_game_statistic("level_scores", PlayerManager.get_player_score(), "level%s_top" % ENEMY_ID)
	PlayerManager.set_player_score(0)
	ArenaManager.stop_music()
	GameStateManager.show_victory_screen(ENEMY_ID)


func get_hit(dmg_source: BaseBullet) -> void:
	if can_get_hit:
		current_damage_taken += dmg_source.damage
		if (
			not got_hit_animation.is_playing() and
			not is_moving and
			not on_hit_animation.is_playing()
		):
			idle_animation.hide()
			got_hit_animation.show()
			got_hit_animation.play()
		else:
			hit_animation_intensity += 1
		if GameStateManager.get_debug():
			print(
				'Enemy got hit by %s. Current health: %s Current phase: %s' %
				[dmg_source.name, MAX_DAMAGE_TAKEN_PHASE - current_damage_taken, current_boss_phase]
			)
		if current_damage_taken >= MAX_DAMAGE_TAKEN_PHASE:
			if secondary_attack_thread.is_active():
				secondary_attack_thread.wait_to_finish()
			if current_boss_phase >= N_OF_PHASES:
				can_get_hit = false
				emit_signal("enemy_death")
			else:
				can_get_hit = false
				change_boss_phase(current_boss_phase + 1)
				MinionManager.remove_all_active_minions()

func change_boss_phase(new_boss_phase: int) -> void:
	Settings.increase_game_statistic(
		"level%s_%s_times_reached_phase_%s" %
			[ENEMY_ID, GameStateManager.get_difficulty_level(), new_boss_phase],
		1
	)
	current_boss_phase = new_boss_phase
	current_damage_taken = 0
	hardest_mode_current_attack_stage = 0
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
	chosen_attack_params = attack_params.get(chosen_attack, {})
	can_attack = false
	continue_attacking = true
	if chosen_attack_params.has("SPAWN_POINTS_TO_DISABLE"):
		for region in chosen_attack_params.SPAWN_POINTS_TO_DISABLE.keys():
			emit_signal("disable_spawnpoints", region, chosen_attack_params.SPAWN_POINTS_TO_DISABLE[region])
	call(chosen_attack, chosen_attack_params)

func start_next_attack_delay() -> void:
	time_between_attacks_timer.start()
	is_waiting_to_begin_next_attack = true

func begin_next_attack() -> void:
	if is_waiting_to_begin_next_attack:
		is_waiting_to_begin_next_attack = false
		current_attack = current_boss_phase - 1
		can_get_hit = true
		attack()

func main_attack_timer_start(wait_time: float) -> void:
	main_attack_timer.set_wait_time(wait_time)
	main_attack_timer.start()

func secondary_attack_timer_start(wait_time: float) -> void:
	secondary_attack_timer.set_wait_time(wait_time)
	secondary_attack_timer.start()

func unload() -> void:
	get_parent().remove_child(self)
	queue_free()

# Creates a dictionary with the data for each attack (number of bullets, their
# speed, type, etc). Not actually constants because of the way I programmed the
# difficulties for each boss. This function is overloaded on each difficulty
# file for each boss, each just adding their parameters to the dictionary.
func setup_attack_constants() -> void:
	attack_params = {}

func _on_hardest_mode_time_until_next_stage_timer_timeout() -> void:
	hardest_mode_current_attack_stage += 1
	var function_to_call: String = hardest_mode_functions_to_call.get(
		chosen_attack, {}
	).get(hardest_mode_current_attack_stage, "")
	if function_to_call:
		call(function_to_call, chosen_attack_params)
	hardest_mode_current_fight_time += 1.0
	if hardest_mode_current_fight_time > 30:
		PlayerManager.add_score(pow(10, PlayerManager.get_player_health()))
	elif hardest_mode_current_fight_time < 30:
		hardest_mode_accumulated_score += pow(
			10, PlayerManager.get_player_health()
		)
	else:
		PlayerManager.add_score(hardest_mode_accumulated_score)

func _on_got_hit_animation_frame_changed():
	got_hit_animation.offset = Vector2(randi()%8 - 4, randi()%4 - 2)
	if got_hit_animation.get_frame() / 2 == hit_animation_intensity:
		_on_got_hit_animation_animation_finished()

func _on_got_hit_animation_animation_finished():
	hit_animation_intensity = 1
	got_hit_animation.offset = Vector2.ZERO
	got_hit_animation.stop()
	got_hit_animation.set_frame(0)
	got_hit_animation.hide()
	idle_animation.show()
