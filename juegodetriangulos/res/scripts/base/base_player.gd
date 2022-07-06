# Base class for each different gameplay experience the player can play. It
# contains methods that should be used by most if not all of them.
extends KinematicBody2D

class_name BasePlayer

signal player_begin_death
signal player_death

export (int) var BASE_SPEED
export (int) var BASE_HEALTH
export (float) var HIT_DELAY

onready var got_healed_sound: AudioStreamPlayer = $got_healed_sound
onready var got_hit_sound: AudioStreamPlayer = $got_hit_sound
onready var wall_bump_sound: AudioStreamPlayer = $wall_bump_sound
onready var death_animation: AnimatedSprite = $animation_list/death_animation
onready var idle_animation: AnimatedSprite = $animation_list/idle_animation
onready var light_fade_animation: AnimatedSprite = $animation_list/light_fade_animation
onready var moving_animation: AnimatedSprite = $animation_list/moving_animation
onready var animation_list: Node2D = $animation_list
onready var blink_timer: Timer = $blink_timer
onready var can_get_hit_timer: Timer = $can_get_hit_timer
onready var wall_bump_sound_cooldown_timer: Timer = $wall_bump_sound_cooldown_timer
onready var unblink_timer: Timer = $unblink_timer

const TIME_TO_GET_HIT_IF_STANDING_STILL: float = 3.0
const TIME_TO_GET_HIT_IF_MOVING: float = 1.0

var current_health: int
var can_get_hit: int
var invencible: bool
var velocity: Vector2 = Vector2.ZERO
var old_position: Vector2
var current_score: int = 0
var play_wall_bump_sound: bool = true
var enable_input: bool = false
var get_hit_if_standing_still_timer: Timer
var get_hit_if_moving_timer: Timer
var got_healed_audio_list: Array = [
	load("res://juegodetriangulos/res/music/get_health_sfx0.wav"),
	load("res://juegodetriangulos/res/music/get_health_sfx1.wav"),
]

func _ready() -> void:
	old_position = position
	can_get_hit = true
	can_get_hit_timer.set_wait_time(HIT_DELAY)
	current_health = BASE_HEALTH
	wall_bump_sound.stream.loop = false
	idle_animation.visible = true 
	moving_animation.visible = false 
	death_animation.visible = false
	light_fade_animation.visible = false
	if GameStateManager.get_standing_still_does_damage():
		get_hit_if_standing_still_timer = Timer.new()
		get_hit_if_standing_still_timer.set_wait_time(TIME_TO_GET_HIT_IF_STANDING_STILL)
		get_hit_if_standing_still_timer.set_one_shot(false)
		add_child(get_hit_if_standing_still_timer)
		get_hit_if_standing_still_timer.connect("timeout", self, "get_hit", [self])
	if GameStateManager.get_moving_does_damage():
		get_hit_if_moving_timer = Timer.new()
		get_hit_if_moving_timer.set_wait_time(TIME_TO_GET_HIT_IF_MOVING)
		get_hit_if_moving_timer.set_one_shot(false)
		add_child(get_hit_if_moving_timer)
		get_hit_if_moving_timer.connect("timeout", self, "get_hit", [self])

func reset() -> void:
	old_position = position
	can_get_hit = true
	current_health = BASE_HEALTH
	idle_animation.visible = true 
	light_fade_animation.visible = false
	light_fade_animation.stop()
	light_fade_animation.set_frame(0)
	moving_animation.visible = false 
	death_animation.visible = false
	death_animation.stop()
	death_animation.set_frame(0)
	invencible = false
	enable_input = true
	current_score = 0

func get_hit(dmg_source: Object, dmg: int = 1):
	if not invencible:
		if (not "limit" in dmg_source.name or GameStateManager.get_edge_touching_does_damage()) and can_get_hit:
			current_health = 0 if GameStateManager.get_one_hit_death() else (current_health - dmg)
			if GameStateManager.get_debug():
				print('Player got hit by %s. Current health: %s' % [dmg_source.name, current_health])
			HudManager.update_player_health(current_health)
			got_hit_sound.play()
			if current_health <= 0:
				death()
			else:
				can_get_hit = false
				can_get_hit_timer.start()
				blink_timer.start()
		elif play_wall_bump_sound:
			wall_bump_sound.play()
			play_wall_bump_sound = false
			wall_bump_sound_cooldown_timer.start()

func get_healed(heal_amount: int = 1):
	current_health = clamp(current_health + heal_amount, 0, BASE_HEALTH)
	if GameStateManager.get_debug():
		print('Player got healed by %s point(s). Current health: %s' % [heal_amount, current_health])
	HudManager.update_player_health(current_health)
	got_healed_sound.stream = got_healed_audio_list[randi()%2]
	got_healed_sound.play()

func death():
	if GameStateManager.get_debug():
		print("Player death function not implemented")

func unload() -> void:
	queue_free()

# Old function used for a savestate like save/load system. Currently not
# functional, as it had a lot a problems, but maybe will be implemented in
# the future
func load(player_data: Dictionary) -> void:
	for attribute in player_data.keys():
		if attribute == "position":
			global_position = Vector2(player_data[attribute]["x"], player_data[attribute]["y"])
		else:
			set(attribute, player_data[attribute])

func _on_can_get_hit_timer_timeout() -> void:
	can_get_hit = true
	blink_timer.stop()
	unblink_timer.stop()
	animation_list.visible = true

func _on_blink_timer_timeout() -> void:
	animation_list.visible = false
	unblink_timer.start()

func _on_unblink_timer_timeout() -> void:
	animation_list.visible = true
	blink_timer.start()

func _on_update_old_position_timer_timeout() -> void:
	old_position = position

func _on_wall_bump_sound_cooldown_timer_timeout() -> void:
	play_wall_bump_sound = true
