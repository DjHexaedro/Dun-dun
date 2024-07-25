# Base class for the third boss in the game, THE MATHMAGICIAN. Contains all the
# methods that are used by most of the different difficulties
extends BaseEnemy

signal attack_finished

enum Operations {
	SUM = 0,
	SUB = 1,
	MUL = 2,
	DIV = 3,
}

const OPERATIONS_TEXT: Array = ["+", "-", "×", "/"]
const OPERATIONS_OPERANDS: Array = ["+", "-", "*", "/"]
const BASE_ANSWER_SIZE: int = 4
const ANSWER_TIME: float = 4.0
const FLOAT_MAX_HEIGHT: int = -10
const FLOAT_MIN_HEIGHT: int = 0
const FLOAT_INCREMENT: int = 10
const DEAD_PLAYER_REVIVE_TRESHOLD: int = 4
const OPERATIONS_VALUE_LIST: Array = [
	# Min, max
	[ 10,  50 ], # SUM
	[ 10,  50 ], # SUB
	[  3,  15 ], # MUL
	[  3,  15 ], # DIV
]
const OPERATIONS_SOLVE_TIME_LIST: Array = [
	# Min, max
	[  2,   4 ], # SUM
	[  2,   4 ], # SUB
	[  3,   5 ], # MUL
	[  3,   5 ], # DIV
]

onready var powerupscene: PackedScene = preload("res://juegodetriangulos/scenes/level_assets/2/powerup.tscn")
onready var problem_label: Label = $problem
onready var remaining_time_sprite: Sprite = $remaining_time
onready var laugh_audio: AudioStreamPlayer2D = $laugh
onready var fail_audio: AudioStreamPlayer2D = $fail
onready var spawn_audio: AudioStreamPlayer2D = $spawn
onready var answer_timer: Timer = $answer_timer

var expression: Expression = Expression.new()
var problem: String
var result: int
var current_digits: int
var current_roo: int
var current_difficulty: int
var powerup_list: Array = []
var enabled_powerup_list: Array = []
var results_list: Array = []
var is_attacking: bool = false
var allowed_operations: Array = [ Operations.SUM ]
var waiting_to_change_phase: bool = false
var last_used_attack: int = -1
var current_answer_time: float = ANSWER_TIME
var float_direction: int = 1
var on_hit_offset: int = 5
var needed_streak: int = 1
var current_streak: int = 0
var allow_rerolls: bool = false
var hide_sign: bool = false
var respondant_id: int = -1
var dead_player_correct_answers: int = 0
var last_attack_id: int = -1


func _ready() -> void:
	yield(get_parent(), "loaded")
	can_get_hit = false

	var spawn_zones_list: Array = get_parent().get_valid_spawn_points()
	var new_powerup
	for i in range(BASE_ANSWER_SIZE):
		new_powerup = powerupscene.instance()
		get_parent().add_child(new_powerup)
		new_powerup.global_position = spawn_zones_list[i].global_position
		new_powerup.powerup_id = len(powerup_list)
		new_powerup.connect(
			"correct_powerup_grabbed", self, "_on_correct_powerup_grabbed"
		)
		new_powerup.connect(
			"incorrect_powerup_grabbed", self, "_on_incorrect_powerup_grabbed"
		)
		powerup_list.append(new_powerup)

	if not GameStateManager.multiplayer_enabled:
		respondant_id = Globals.PlayerIDs.PLAYER_ONE
	
	Utils.get_pause_menu().connect("game_paused", self, "_on_game_paused")
	connect("attack_finished", self, "_on_attack_finished")
	main_attack_timer.connect("timeout", self, "_on_main_attack_timer_timeout")
	spawn()

func _process(delta: float) -> void:
	if idle_animation.visible:
		idle_animation.offset.y += FLOAT_INCREMENT * float_direction * delta 
		idle_animation.offset.y = clamp(
			idle_animation.offset.y, FLOAT_MAX_HEIGHT, FLOAT_MIN_HEIGHT
		)
		if idle_animation.offset.y in [FLOAT_MIN_HEIGHT, FLOAT_MAX_HEIGHT]:
			float_direction *= -1
	remaining_time_sprite.scale.x = -0.1 * (answer_timer.get_time_left() / current_answer_time)

func spawn() -> void:
	spawn_animation.show()
	spawn_audio.play()
	.spawn()

func reset() -> void:
	.reset()

	idle_animation.hide()
	idle_animation.stop()
	idle_animation.set_frame(0)
	idle_animation.offset.y = 0
	on_hit_animation.stop()
	on_hit_animation.hide()
	on_hit_animation.set_frame(0)
	got_hit_animation.stop()
	got_hit_animation.hide()
	got_hit_animation.set_frame(0)

	for powerup in powerup_list:
		powerup.set_enabled(false)
		powerup.hide()

	if GameStateManager.multiplayer_enabled:
		respondant_id = -1
	
	hide_current_problem()
	problem_label.hide()
	remaining_time_sprite.hide()

	answer_timer.stop()
	get_parent().arena_light.show()

	enabled_powerup_list = []
	results_list = []
	is_attacking = false
	waiting_to_change_phase = false
	last_used_attack = -1
	float_direction = 1
	on_hit_offset = 5
	current_streak = 0
	allow_rerolls = false
	hide_sign = false

	spawn()

func change_boss_phase(new_boss_phase: int) -> void:
	if new_boss_phase % 5 == 1:
		PlayerManager.heal_player()
	.change_boss_phase(new_boss_phase)

func begin_next_attack() -> void:
	if is_waiting_to_begin_next_attack:
		test_problems()

func create_problem(min_value: int, max_value: int, chosen_operation: int, hide_operand: bool = false) -> void:
	var left_operand: int
	var right_operand: int

	if GameStateManager.multiplayer_enabled:
		respondant_id = PlayerManager.get_random_player_id([respondant_id])

	results_list = []

	if chosen_operation == Operations.DIV:
		right_operand = randi() % max_value + min_value
		left_operand = right_operand * (randi() % max_value + min_value)
	elif chosen_operation == Operations.SUB:
		right_operand = randi() % max_value + min_value
		left_operand = right_operand + randi() % max_value + min_value
	else:
		left_operand = randi() % max_value + min_value
		right_operand = randi() % max_value + min_value

	var full_operation: String = "%s %s %s" % [
		left_operand, OPERATIONS_OPERANDS[chosen_operation], right_operand
	]
	expression.parse(full_operation)

	result = expression.execute()
	results_list.append(result)

	var fake_result: int 
	var get_same_ending: bool
	for _i in range(BASE_ANSWER_SIZE - 1):
		get_same_ending = false if (chosen_operation == Operations.DIV) else (randi()%3 == 0)
		fake_result = get_fake_result(get_same_ending, chosen_operation, right_operand, left_operand)
		while fake_result in results_list:
			fake_result = get_fake_result(get_same_ending, chosen_operation, right_operand, left_operand)
		results_list.append(fake_result)

	results_list.shuffle()
	enabled_powerup_list = powerup_list.duplicate()

	problem = "%s%s%s" % [
		left_operand, " ? " if hide_operand else OPERATIONS_TEXT[chosen_operation], right_operand
	]

	for i in range(len(results_list)):
		powerup_list[i].set_powerup_value(results_list[i], result, respondant_id)

	problem_label.text = problem
	problem_label.show()
	remaining_time_sprite.show()

func get_fake_result(
	get_same_ending: bool, chosen_operation: int,
	right_operand: int = 0, left_operand: int = 0
) -> int:
	if get_same_ending:
		return result + (10 * [1, -1][randi()%2] * randi()%3 + 1)
	else:
		if chosen_operation == Operations.MUL:
			return (
				left_operand +  [-2, -1, 1, 2, 3][randi()%5]
			) * (
				right_operand + [-2, -1, 1, 2, 3][randi()%5]
			)
		elif chosen_operation == Operations.DIV:
			return result + randi()%5 - 2
		return result + randi()%21 - 10

func test_problems() -> void:
	allow_rerolls = true 
	can_get_hit = false
	var operation: int = allowed_operations[randi()%len(allowed_operations)]

	hide_current_problem()
	get_parent().turn_book_page()
	yield(get_parent(), "page_turned") 

	answer_timer.set_wait_time(current_answer_time)

	create_problem(
		OPERATIONS_VALUE_LIST[operation][0],
		OPERATIONS_VALUE_LIST[operation][1],
		operation,
		hide_sign
	)

	show_current_problem()
	answer_timer.start()

func hide_current_problem(except: int = -1) -> void:
	problem_label.hide()
	for powerup in powerup_list:
		if powerup.powerup_id != except:
			powerup.hide()

func show_current_problem() -> void:
	problem_label.show()
	for powerup in powerup_list:
		powerup.respawn()

func reroll_current_problem() -> void:
	var operation: int = allowed_operations[randi()%len(allowed_operations)]
	create_problem(
		OPERATIONS_VALUE_LIST[operation][0],
		OPERATIONS_VALUE_LIST[operation][1],
		operation,
		hide_sign
	)

func punish_incorrect_answer(was_timeout: bool = false) -> void:
	current_streak = 0
	if not is_attacking:
		is_attacking = true
		hide_current_problem()

		if was_timeout:
			break_random_powerup()

		current_attack = randi()%len(attack_list)
		while current_attack == last_used_attack:
			current_attack = randi()%len(attack_list)
		last_used_attack = current_attack

		attack()

		if chosen_attack_params.get("ATTACK_DURATION", 0) > 0:
			main_attack_timer_start(chosen_attack_params.ATTACK_DURATION)

func break_random_powerup() -> void:
	if len(enabled_powerup_list) > 1:
		var random_powerup: int = randi()%len(enabled_powerup_list)
		var is_random_powerup_invalid: bool = true
		var chosen_powerup: BasePowerup

		while is_random_powerup_invalid:
			chosen_powerup = enabled_powerup_list[random_powerup]
			if chosen_powerup.value == result:
				random_powerup = randi()%len(enabled_powerup_list)
			else:
				is_random_powerup_invalid = false

		chosen_powerup.break_powerup()
		chosen_powerup.set_enabled(false)
		enabled_powerup_list.remove(random_powerup)

func _on_attack_finished() -> void:
	if not waiting_to_change_phase:
		show_current_problem()
		answer_timer.start()

	get_parent().arena_light.show()
	is_attacking = false

func _on_spawn_animation_animation_finished() -> void:
	if spawn_animation.get_animation() == "glasses":
		spawn_animation.set_animation("body")
		spawn_animation.play()
	elif spawn_animation.get_animation() == "body":
		spawn_animation.set_animation("glasses")
		spawn_animation.stop()
		spawn_animation.hide()
		idle_animation.show()
		idle_animation.play()
		SimpleBulletManager.update_screen_center_position()
		PlayerManager.get_player_node().connect("player_hit", self, "_on_player_hit")
		test_problems()

func _on_player_hit() -> void:
	if not got_hit_animation.is_playing():
		idle_animation.hide()
		spawn_animation.hide()
		on_hit_animation.offset = idle_animation.offset
		on_hit_animation.show()
		on_hit_animation.play()
		laugh_audio.play()

func _on_on_hit_animation_animation_finished() -> void:
	on_hit_animation.stop()
	on_hit_animation.hide()
	on_hit_animation.set_frame(0)
	idle_animation.offset = on_hit_animation.offset
	idle_animation.show()
	idle_animation.play()

func _on_on_hit_animation_frame_changed():
	on_hit_animation.offset.y += on_hit_offset
	if on_hit_animation.get_frame() / 3:
		on_hit_offset *= -1

func _on_answer_timer_timeout() -> void:
	answer_timer.stop()
	fail_audio.play()
	get_parent().arena_light.hide()
	punish_incorrect_answer(true)

func _on_correct_powerup_grabbed(correct_powerup_id: int) -> void:
	if not PlayerManager.is_player_alive(respondant_id):
		dead_player_correct_answers += 1
		if dead_player_correct_answers >= DEAD_PLAYER_REVIVE_TRESHOLD:
			PlayerManager.revive_player(respondant_id)
			dead_player_correct_answers = 0

	current_streak += 1
	if current_streak >= needed_streak:
		can_get_hit = true
		current_streak = 0
		answer_timer.stop()
		waiting_to_change_phase = true
		for powerup in enabled_powerup_list:
			if powerup.powerup_id != correct_powerup_id:
				powerup.break_powerup()
	else:
		for powerup in enabled_powerup_list:
			if powerup.powerup_id != correct_powerup_id:
				powerup.break_powerup()
		yield(powerup_list[correct_powerup_id], "finished_shooting")
		if is_attacking:
			yield(self, "attack_finished")
		var operation: int = allowed_operations[randi()%len(allowed_operations)]
		create_problem(
			OPERATIONS_VALUE_LIST[operation][0],
			OPERATIONS_VALUE_LIST[operation][1],
			operation,
			hide_sign
		)

func _on_incorrect_powerup_grabbed(incorrect_powerup_id: int) -> void:
	answer_timer.stop()
	fail_audio.play()
	hide_current_problem(incorrect_powerup_id)
	yield(powerup_list[incorrect_powerup_id].break_animation, "animation_finished")
	get_parent().arena_light.hide()
	var aux: Array = enabled_powerup_list.duplicate()
	for i in range(len(enabled_powerup_list)):
		if enabled_powerup_list[i].powerup_id == incorrect_powerup_id:
			aux.remove(i)
	enabled_powerup_list = aux
	punish_incorrect_answer()

func _on_game_paused(paused: bool) -> void:
	if not waiting_to_change_phase and not is_attacking:
		if paused:
			hide_current_problem()
		elif allow_rerolls:
			reroll_current_problem()
			show_current_problem()

func _on_main_attack_timer_timeout() -> void:
	continue_attacking = false

	if is_attacking and last_attack_id == current_attack:
		if chosen_attack_params.get("AFTER_MAIN_ATTACK", false):
			call(chosen_attack_params.AFTER_MAIN_ATTACK, chosen_attack_params)

		else:
			SimpleBulletManager.despawn_active_bullets_by_type_list(chosen_attack_params.get(
				"BULLET_TYPES", [chosen_attack_params.get("BULLET_TYPE", "")]
			))
			yield(SimpleBulletManager, "bullets_despawned_by_type_list")

			if is_attacking and last_attack_id == current_attack:
				emit_signal("attack_finished")
