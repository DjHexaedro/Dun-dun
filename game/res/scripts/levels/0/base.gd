# Base class for the first boss in the game, Ongard. Contains all the methods
# that are used by most of the different difficulties
extends BaseEnemy

signal finished_moving
signal pulsating_fireball_next_stage
signal enable_all_spawnpoints
signal roar_finished

const ATTACK_FRAME: int = 3
const CFC_FINAL_N_OF_BULLETS: int = 26
const SPAWN_ANIMATION_SCALE: int = 2
const EYE_MOVEMENT_CHECK_ON_FRAME: int = 30

# onready var idle_animations_list: Node2D = $idle_animations_list
onready var bored_roar_audio: AudioStreamPlayer = $bored_roar
onready var roar_audio: AudioStreamPlayer = $roar

var stop_frame: int = -1
var enable_roar: bool = true
var current_attack_stage: int = 0
var angle_to_screen_center: float
var move_positions: Array = []
var teleport_stage_1: bool = false
var teleport_stage_2: bool = false
var eye_movement_frame_count: int = 0

func _ready() -> void:
	move_positions = [
		Vector2(positions_list.local.CENTER_X, positions_list.local.TOP_Y),
		Vector2(positions_list.local.CENTER_X, positions_list.local.BOTTOM_Y),
		Vector2(positions_list.local.LEFT_X, positions_list.local.CENTER_Y),
		Vector2(positions_list.local.RIGHT_X, positions_list.local.CENTER_Y),
	]
	connect("finished_moving", self, "begin_next_attack")
	connect("enable_all_spawnpoints", ArenaManager, "enable_all_spawnpoints")

func _process(_delta: float) -> void:
	if eye_movement_frame_count >= EYE_MOVEMENT_CHECK_ON_FRAME:
		var player_position: Vector2 = PlayerManager.get_player_position()
		idle_animation.set_frame((player_position.x / 100) + 4)
		eye_movement_frame_count = 0
	else:
		eye_movement_frame_count += 1

func reset(reset_animations: bool = true) -> void:
	.reset()
	position = move_positions[0]
	teleport_stage_1 = false
	teleport_stage_2 = false
	if reset_animations:
		idle_animation.stop()
		idle_animation.set_frame(3)
		spawn_animation.stop()
		spawn_animation.set_speed_scale(1)
		spawn_animation.set_frame(0)
		on_hit_animation.stop()
		on_hit_animation.hide()
		on_hit_animation.set_frame(0)
		got_hit_animation.stop()
		got_hit_animation.hide()
		got_hit_animation.set_frame(0)
		special_animation.stop()
		special_animation.hide()
		special_animation.set_frame(0)
		_setup_enemy()
	else:
		begin_attacking_sequence()

func change_boss_phase(new_boss_phase: int) -> void:
	.change_boss_phase(new_boss_phase)
	PlayerManager.heal_player()
	ArenaManager.unmute_phase_bgm(new_boss_phase)

func start_next_attack_delay() -> void:
	if chosen_attack_params.has("MOVE_TO"):
		move(chosen_attack_params.MOVE_TO)
	else:
		time_between_attacks_timer.start()
	is_waiting_to_begin_next_attack = true

func get_hit(dmg_source) -> void:
	.get_hit(dmg_source)
	# This mess could probably be done better with signals
	if chosen_attack == 'fireball_circle':
		if not secondary_attack_enabled and current_damage_taken > chosen_attack_params.NEXT_STAGE:
			var current_difficulty: int = GameStateManager.get_difficulty_level()
			if current_difficulty == Globals.DifficultyLevels.HARD:
				secondary_attack_enabled = true 
			if current_difficulty == Globals.DifficultyLevels.NORMAL:
				emit_signal("pulsating_fireball_next_stage")
				if chosen_attack_params.NEXT_STAGE == 500:
					secondary_attack_enabled = true
				else:
					chosen_attack_params.NEXT_STAGE = 500

	elif chosen_attack == 'constant_fire_circle':
		if not secondary_attack_enabled and current_damage_taken > chosen_attack_params.ENABLE_SECONDARY_ATTACK:
			secondary_attack_enabled = true
			attack_params.constant_fire_circle.n_of_bullets = CFC_FINAL_N_OF_BULLETS

	else:
		if not secondary_attack_enabled and current_damage_taken > chosen_attack_params.ENABLE_SECONDARY_ATTACK:
			secondary_attack_enabled = true
			if chosen_attack_params.get("SECONDARY_ATTACK", false):
				secondary_attack_thread.start(
					self, chosen_attack_params.SECONDARY_ATTACK,
					chosen_attack_params.get("SECONDARY_ATTACK_PARAMS", {})
				)

func move(new_position = false, animation_speed = 1) -> void:
	.move(new_position)
	if got_hit_animation.is_playing():
		got_hit_animation.stop()
		got_hit_animation.set_frame(0)
		got_hit_animation.hide()
	idle_animation.hide()
	teleport_stage_1 = true
	teleport_stage_2 = false
	spawn_animation.visible = true
	spawn_animation.set_frame(9)
	spawn_animation.set_speed_scale(animation_speed * 2)
	spawn_animation.play("", true)
	angle_to_screen_center = (positions_list.local.SCREEN_CENTER - position).angle()

func roar(bored: bool = false) -> void:
	CameraManager.shake_screen()
	var chosen_roar = bored_roar_audio if bored else roar_audio
	chosen_roar.play()
	yield(chosen_roar, "finished")
	emit_signal("roar_finished")

func begin_attacking_sequence() -> void:
	if not Utils.is_difficulty_hardest():
		PowerupManager.enable_powerups()
	ArenaManager.update_current_bgm(true)
	attack()

func begin_next_attack() -> void:
	if is_waiting_to_begin_next_attack:
		emit_signal("enable_all_spawnpoints")
		.begin_next_attack()

func _setup_enemy() -> void:
	spawn_animation.show()
	idle_animation.hide()
	# for animation in idle_animations_list.get_children():
	# 	animation.hide()
	enable_roar = not Settings.get_game_statistic("fighting_boss", false)
	if not enable_roar:
		spawn_animation.set_speed_scale(SPAWN_ANIMATION_SCALE)
		spawn()

func _on_attack_delay_timeout() -> void:
	can_attack = true

func _on_movement_delay_timeout() -> void:
	can_move = true
	is_moving = false

func _on_spawn_animation_animation_finished() -> void:
	if teleport_stage_1:
		teleport_stage_1 = false
		teleport_stage_2 = true
		position = move_to_position
		spawn_animation.set_frame(0)
		spawn_animation.play()
	elif teleport_stage_2:
		teleport_stage_1 = false
		teleport_stage_2 = false
		spawn_animation.hide()
		idle_animation.show()
		move_to_position = Vector2.ZERO
		is_moving = false
		emit_signal("finished_moving")
	else:
		spawn_animation.hide()
		idle_animation.show()
		angle_to_screen_center = (positions_list.local.SCREEN_CENTER - position).angle()
		if enable_roar:
			roar()
			yield(self, "roar_finished")
			continue_attacking = false
		SimpleBulletManager.update_screen_center_position()
		begin_attacking_sequence()

