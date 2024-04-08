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

onready var despawn_animation: AnimatedSprite = $despawn_animation
onready var idle_animations_list: Node2D = $idle_animations_list
onready var default_idle_animation: AnimatedSprite = $default_idle_animation
onready var spawn_animation: AnimatedSprite = $spawn_animation
onready var teleport_animation: AnimatedSprite = $teleport_animation
onready var bored_roar_audio: AudioStreamPlayer = $bored_roar
onready var roar_audio: AudioStreamPlayer = $roar

var pixel_offset_attacking: int = 5
var stop_frame: int = -1
var enable_roar: bool = true
var current_attack_stage: int = 0
var angle_to_screen_center: float
var chosen_idle_animation: AnimatedSprite = null
var move_positions: Array = []

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
	if randi() % 500 == 0 and chosen_idle_animation == null and not is_moving and continue_attacking:
		default_idle_animation.visible = false
		chosen_idle_animation = idle_animations_list.get_children()[randi()%3]
		chosen_idle_animation.visible = true
		chosen_idle_animation.play()

func reset(reset_animations: bool = true) -> void:
	.reset()
	position = move_positions[0]
	if reset_animations:
		despawn_animation.stop()
		despawn_animation.set_frame(0)
		for animation in idle_animations_list.get_children():
			animation.stop()
			animation.set_frame(0)
		default_idle_animation.stop()
		default_idle_animation.set_frame(0)
		spawn_animation.stop()
		spawn_animation.set_frame(0)
		teleport_animation.stop()
		teleport_animation.set_frame(0)
		_setup_enemy()
	else:
		begin_attacking_sequence()

func spawn() -> void:
	spawn_animation.play()

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
				secondary_attack_thread.start(self, chosen_attack_params.SECONDARY_ATTACK, chosen_attack_params.get("SECONDARY_ATTACK_PARAMS", {}))

func move(new_position = false, animation_speed = 1) -> void:
	.move(new_position)
	default_idle_animation.hide()
	for animation in idle_animations_list.get_children():
		animation.hide()
		animation.stop()
		animation.set_frame(0)
	teleport_animation.visible = true
	teleport_animation.set_animation("teleport_fade_out")
	teleport_animation.set_frame(0)
	teleport_animation.play()
	teleport_animation.set_speed_scale(animation_speed)
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
	despawn_animation.hide()
	default_idle_animation.hide()
	for animation in idle_animations_list.get_children():
		animation.hide()
	teleport_animation.visible = false
	enable_roar = not Settings.get_game_statistic("fighting_boss", false)
	if not enable_roar:
		spawn_animation.set_speed_scale(SPAWN_ANIMATION_SCALE)
		spawn()

func _on_attack_delay_timeout() -> void:
	can_attack = true

func _on_movement_delay_timeout() -> void:
	can_move = true
	is_moving = false

func _on_teleport_animation_animation_finished() -> void:
	if teleport_animation.get_animation() == "teleport_fade_out" and position != move_to_position:
		position = move_to_position
		teleport_animation.set_animation("teleport_fade_in")
		teleport_animation.set_frame(0)
		teleport_animation.play()
	else:
		teleport_animation.hide()
		default_idle_animation.show()
		move_to_position = Vector2.ZERO
		is_moving = false
		emit_signal("finished_moving")

func _on_spawn_animation_animation_finished() -> void:
	spawn_animation.hide()
	default_idle_animation.show()
	angle_to_screen_center = (positions_list.local.SCREEN_CENTER - position).angle()
	if enable_roar:
		roar()
		yield(self, "roar_finished")
		continue_attacking = false
	SimpleBulletManager.update_screen_center_position()
	begin_attacking_sequence()

func _on_idle_animation_animation_finished() -> void:
	chosen_idle_animation.hide()
	chosen_idle_animation.stop()
	chosen_idle_animation.set_frame(0)
	chosen_idle_animation = null
	default_idle_animation.show()
