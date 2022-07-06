# Base class for the first boss in the game, Ongard. Contains all the methods
# that are used by most of the different difficulties
extends BaseEnemy

signal finished_moving
signal pulsating_fireball_next_stage
signal roar_finished

const ATTACK_FRAME: int = 3
const CFC_FINAL_N_OF_BULLETS: int = 26
const SPAWN_ANIMATION_SCALE: int = 2

onready var despawn_animation: AnimatedSprite = $despawn_animation
onready var blink_idle_animation: AnimatedSprite = $blink_idle_animation
onready var eyes_right_idle_animation: AnimatedSprite = $eyes_right_idle_animation
onready var eyes_left_idle_animation: AnimatedSprite = $eyes_left_idle_animation
onready var spawn_animation: AnimatedSprite = $spawn_animation
onready var teleport_animation: AnimatedSprite = $teleport_animation
onready var bored_roar_audio: AudioStreamPlayer = $bored_roar
onready var roar_audio: AudioStreamPlayer = $roar
onready var main_attack_timer: Timer = $main_attack_timer
onready var secondary_attack_timer: Timer = $secondary_attack_timer

var pixel_offset_attacking: int = 5
var stop_frame: int = -1
var enable_roar: bool = true
var current_attack_stage: int = 0
var angle_to_screen_center: float
var chosen_idle_animation: AnimatedSprite = null
var move_positions: Array = [ # Not a constant because it doesn't work with Globals
	Vector2(Globals.Positions.CENTER_X, Globals.Positions.TOP_Y),
	Vector2(Globals.Positions.CENTER_X, Globals.Positions.BOTTOM_Y),
	Vector2(Globals.Positions.LEFT_X, Globals.Positions.CENTER_Y),
	Vector2(Globals.Positions.RIGHT_X, Globals.Positions.CENTER_Y),
]


func _process(delta: float) -> void:
	if randi() % 500 == 0 and chosen_idle_animation == null and not is_moving and continue_attacking:
		blink_idle_animation.visible = false
		chosen_idle_animation = [blink_idle_animation, eyes_left_idle_animation, eyes_right_idle_animation][randi()%3]
		chosen_idle_animation.visible = true
		chosen_idle_animation.play()


func reset() -> void:
	.reset()
	despawn_animation.stop()
	despawn_animation.set_frame(0)
	blink_idle_animation.stop()
	blink_idle_animation.set_frame(0)
	spawn_animation.stop()
	spawn_animation.set_frame(0)
	teleport_animation.stop()
	teleport_animation.set_frame(0)
	_setup_enemy()

func spawn() -> void:
	spawn_animation.play()

func enemy_died() -> void:
	var current_difficulty_level: int = GameStateManager.get_difficulty_level()
	if current_difficulty_level == Globals.DifficultyLevels.HARDEST:
		Settings.increase_game_statistic("ongard_hardest_times_won", 1)
		roar(true)
		yield(self, "roar_finished")
		blink_idle_animation.visible = false
		despawn_animation.visible = true
		despawn_animation.play()
		yield(despawn_animation, "animation_finished")
	elif current_difficulty_level == Globals.DifficultyLevels.HARD:
		Settings.increase_game_statistic("ongard_hard_times_won", 1)
	else:
		Settings.increase_game_statistic("ongard_normal_times_won", 1)
	.enemy_died()

func get_hit(dmg_source) -> void:
	.get_hit(dmg_source)
	# This mess could probably be done better with signals
	if chosen_attack == 'fireball_circle':
		if not secondary_attack_enabled and current_damage_taken > chosen_attack_params.NEXT_STAGE:
			if hard_mode:
				secondary_attack_enabled = true 
			if normal_mode:
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
	blink_idle_animation.visible = false
	eyes_right_idle_animation.visible = false
	eyes_left_idle_animation.visible = false
	if chosen_idle_animation != null:
		chosen_idle_animation.visible = false
		chosen_idle_animation.stop()
		chosen_idle_animation.set_frame(0)
	teleport_animation.visible = true
	teleport_animation.set_animation("teleport_fade_out")
	teleport_animation.set_frame(0)
	teleport_animation.play()
	teleport_animation.set_speed_scale(animation_speed)
	angle_to_screen_center = (Globals.Positions.SCREEN_CENTER - position).angle()

func roar(bored: bool = false) -> void:
	CameraManager.shake_screen()
	if bored:
		bored_roar_audio.play()
		yield(bored_roar_audio, "finished")
	else:
		roar_audio.play()
		yield(roar_audio, "finished")
	emit_signal("roar_finished")

func begin_attacking_sequence() -> void:
	if GameStateManager.get_difficulty_level() != Globals.DifficultyLevels.HARDEST:
		GameStateManager.enable_powerups()
	ArenaManager.start_music()
	HudManager.enable_hud()
	update_hud_health()
	attack()

func main_attack_timer_start(wait_time: float) -> void:
	main_attack_timer.set_wait_time(wait_time)
	main_attack_timer.start()

func secondary_attack_timer_start(wait_time: float) -> void:
	secondary_attack_timer.set_wait_time(wait_time)
	secondary_attack_timer.start()

func _setup_enemy() -> void:
	spawn_animation.visible = true
	blink_idle_animation.visible = false
	teleport_animation.visible = false
	position = Vector2(Globals.Positions.CENTER_X, Globals.Positions.TOP_Y)
	enable_roar = not Settings.get_game_statistic("fighting_boss", false)
	if not enable_roar:
		spawn_animation.set_speed_scale(SPAWN_ANIMATION_SCALE)
		spawn()

func _on_attack_delay_timeout() -> void:
	can_attack = true

func _on_movement_delay_timeout() -> void:
	can_move = true

func _on_teleport_animation_animation_finished() -> void:
	if teleport_animation.get_animation() == "teleport_fade_out" and position != move_to_position:
		position = move_to_position
		teleport_animation.set_animation("teleport_fade_in")
		teleport_animation.set_frame(0)
		teleport_animation.play()
	else:
		teleport_animation.visible = false
		blink_idle_animation.visible = true 
		move_to_position = Vector2.ZERO
		is_moving = false
		emit_signal("finished_moving")

func _on_idle_animation_frame_changed() -> void:
	if stop_frame != -1:
		blink_idle_animation.stop()
		call(chosen_attack, null)
	if blink_idle_animation.get_frame() == ATTACK_FRAME:
		call(chosen_attack, null)

func _on_spawn_animation_animation_finished() -> void:
	spawn_animation.stop()
	spawn_animation.visible = false 
	blink_idle_animation.visible = true 
	angle_to_screen_center = (Globals.Positions.SCREEN_CENTER - position).angle()
	if enable_roar:
		roar()
		yield(self, "roar_finished")
		continue_attacking = false
	begin_attacking_sequence()

func _on_idle_animation_animation_finished() -> void:
	chosen_idle_animation.visible = false
	chosen_idle_animation.stop()
	chosen_idle_animation.set_frame(0)
	blink_idle_animation.visible = true 
	chosen_idle_animation = null
