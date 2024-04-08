# Base class for all the powerups in the game. "Powerups" are the way the player
# is able to damage the boss, not actual upgrades to the player character
extends Node2D

class_name BasePowerup

export (float) var BASE_DAMAGE

onready var invert_shader: ShaderMaterial = preload("res://juegodetriangulos/res/shaders/invert.tres")

const BASE_SCORE: int = 5 
const LIGHT_TEXTURE_STARTING_SCALE: float = 0.15
const LIGHT_TEXTURE_SCALE_INCREMENT: float = 0.15
const MAX_BULLETS: int = 5
const SPAWN_SPARKLE_FRAMES: Array = [8, 11]
const X_DEVIATION: int = 30
const Y_DEVIATION: int = 20
const TIME_BETWEEN_BULLETS: float = 0.1
const BASE_PLAYER_PICKUP_DISTANCE: float = 3000.0

onready var break_animation: AnimatedSprite = $break
onready var cracking_animation: AnimatedSprite = $cracking
onready var spawn_animation: AnimatedSprite = $spawn
onready var break_sound_audio: AudioStreamPlayer = $break_sound
onready var shoot_audio: AudioStreamPlayer = $shoot
onready var light: Light2D = $light
onready var decay_timer: Timer = $decay_timer
onready var last_breath_timer: Timer = $last_breath_timer

var bullet_speed: int = 1000
var bullet_list: Array = []
var current_damage: int
var current_shoot_bullets: int
var is_shooting: bool
var enabled: bool = true
var n_of_bullets: int = 1
var has_spawned: bool = false
var delay_between_bullets_timer: Timer = Timer.new()
var player_pickup_distance: float = BASE_PLAYER_PICKUP_DISTANCE
var allowed_player_id: int = -1
var changed_owners: bool = false


func _ready() -> void:
	# Spawn the powerup out of bounds before its actual position is set,
	# so it doesn't spawn in the top corner and then teleports after
	# a few milliseconds
	global_position = Globals.OUT_OF_BOUNDS_POSITION
	reset_powerup()
	delay_between_bullets_timer.set_one_shot(true)
	delay_between_bullets_timer.set_wait_time(TIME_BETWEEN_BULLETS)
	add_child(delay_between_bullets_timer)
	shoot_audio.stream.loop = false
	
func _process(_delta: float) -> void:
	if has_spawned and not is_shooting:
		if last_breath_timer.is_stopped():
			var clampped_time = clamp(
				decay_timer.time_left, 0.1, decay_timer.wait_time
			)
			n_of_bullets = 1 + int(round(decay_timer.wait_time - clampped_time))
		cracking_animation.set_frame(n_of_bullets - 1)
		if global_position.distance_squared_to(
			PlayerManager.get_player_position(allowed_player_id)
		) < player_pickup_distance:
			_on_powerup_grabbed()

func set_allowed_player_id(player_id: int) -> void:
	allowed_player_id = player_id
	if player_id != 0:
		material = invert_shader
		light.visible = true
	else:
		material = null

func set_position_from_spawn_point_data(
	spawn_position: Vector2, spawn_deviation: bool = true
) -> void:
	var new_x: int = spawn_position.x +\
		(randi() % X_DEVIATION - (X_DEVIATION / 2) if spawn_deviation else 0)
	var new_y: int = spawn_position.y +\
		(randi() % Y_DEVIATION - (Y_DEVIATION / 2) if spawn_deviation else 0)
	set_global_position(Vector2(new_x, new_y))
	spawn_animation.play()

func shoot() -> void:
	decay_timer.stop()
	is_shooting = true
	var params_dict: Dictionary = {
		"base_speed": bullet_speed,
		"scale": Vector2(1, 1),
		"damage": BASE_DAMAGE,
		"direction": (EnemyManager.get_enemy_position() - position).normalized(),
		"uses_shader": allowed_player_id != 0,
	}
	var bullet_positions: Array = [
		global_position,
		global_position + Vector2(-24, 9),
		global_position + Vector2(20, 10),
		global_position + Vector2(-11, -5),
		global_position + Vector2(-3, -8),
	]
	for c in range(n_of_bullets, 0, -1):
		params_dict["bullet_variant"] = c - 1
		params_dict["global_position"] = bullet_positions[c - 1]
		shoot_audio.pitch_scale = 1.0 + 0.15 * (n_of_bullets - c)
		shoot_audio.play()
		ComplexBulletManager.shoot_bullet(
			Globals.ComplexBulletTypes.POWERUP, params_dict
		)
		if c > 1:
			cracking_animation.set_frame(c - 2)
		else:
			cracking_animation.hide()
		delay_between_bullets_timer.start()
		yield(delay_between_bullets_timer, "timeout")
	visible = false
	PowerupManager.remove_active_powerup(get_instance_id())

func add_score() -> void:
	PowerupManager.add_score(n_of_bullets)

func unload() -> void:
	bullet_list = []
	queue_free()

func reset_powerup() -> void:
	enabled = true 
	visible = true
	is_shooting = false
	has_spawned = false
	changed_owners = false
	n_of_bullets = 1
	light.visible = false
	light.texture_scale = LIGHT_TEXTURE_STARTING_SCALE
	spawn_animation.visible = true
	spawn_animation.set_frame(0)
	spawn_animation.stop()
	break_animation.visible = false
	break_animation.set_frame(0)
	break_animation.stop()
	cracking_animation.visible = false
	cracking_animation.set_frame(0)
	cracking_animation.stop()
	decay_timer.stop()
	last_breath_timer.stop()

func break_powerup(forced: bool = false) -> void:
	decay_timer.stop()
	last_breath_timer.stop()
	spawn_animation.hide()
	spawn_animation.stop()
	cracking_animation.hide()
	cracking_animation.stop()
	break_animation.show()
	break_animation.play()
	break_sound_audio.play()
	if not forced:
		PowerupManager.reset_perfect_powerups_combo()

func _on_decay_timer_timeout() -> void:
	n_of_bullets = MAX_BULLETS
	last_breath_timer.start()

func _on_break_animation_finished() -> void:
	PowerupManager.remove_active_powerup(get_instance_id())

func _on_last_breath_timer_timeout() -> void:
	if not is_shooting:
		enabled = false
		break_powerup()
		GameStateManager.update_match_history(Globals.MatchEvents.CRYSTAL_MISSED)
		Settings.increase_game_statistic("crystals_missed", 1)
		if GameStateManager.missed_grabs_do_damage:
			PlayerManager.damage_player(self)

func _on_powerup_grabbed() -> void:
	if PlayerManager.is_player_alive(allowed_player_id):
		if not is_shooting and enabled and has_spawned:
			if GameStateManager.get_only_perfect_grabs() and n_of_bullets != 5:
				decay_timer.stop()
				break_powerup()
			else:
				add_score()
				shoot()
			
			GameStateManager.update_match_history(
				Globals.MatchEvents.CRYSTAL_GRABBED, n_of_bullets
			)
			Settings.increase_game_statistic("crystals_collected", 1)
			if n_of_bullets == 5:
				Settings.increase_game_statistic("perfect_grabs", 1)
			if n_of_bullets == 1:
				Settings.increase_game_statistic("bad_grabs", 1)
	else:
		PowerupManager.increase_dead_player_collected_crystals(allowed_player_id)
		set_allowed_player_id(1 if allowed_player_id == 0 else 0)
		changed_owners = true
		
func _on_spawn_animation_finished() -> void:
	has_spawned = true
	spawn_animation.visible = false
	spawn_animation.stop()
	cracking_animation.visible = true 
	decay_timer.start()
	light.visible = true 

func _on_spawn_frame_changed() -> void:
	if spawn_animation.get_frame() in SPAWN_SPARKLE_FRAMES:
		if allowed_player_id == 0:
			light.visible = true
		light.texture_scale += LIGHT_TEXTURE_SCALE_INCREMENT
	elif spawn_animation.is_playing():
		if allowed_player_id == 0:
			light.visible = false
