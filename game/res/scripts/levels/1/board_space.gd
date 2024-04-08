extends Node2D

signal spawned
signal despawned
signal enabled


onready var idle_animation: AnimatedSprite = $idle
onready var spawn_animation: AnimatedSprite = $spawn
onready var despawn_animation: AnimatedSprite = $despawn
onready var waves: AnimatedSprite = $idle/waves
onready var light: Light2D = $light

const BLINK_TIME: float = 1.9
const UNBLINK_TIME: float = 0.1
const TIME_WAITED_INCREMENT: float = 10.0
const PIECE_SPAWNER_COLOR: Color = Color(1, 1, 1, 1)
const REGULAR_SPACE_COLOR: Color = Color(0.4, 0.4, 0.4, 1)

var can_spawn_pieces: bool = false setget set_can_spawn_pieces, get_can_spawn_pieces
var being_used: bool = false
var can_spawn_powerups: bool = false
var enabled: bool = true setget set_enabled, get_enabled
var about_to_disappear: bool = false
var time_waited: float = 0
var was_despawned: bool = false

func _process(delta: float) -> void:
	if about_to_disappear:
		if (visible and time_waited > BLINK_TIME) or (not visible and time_waited > UNBLINK_TIME):
			visible = not visible
			time_waited = 0
		else:
			time_waited += TIME_WAITED_INCREMENT * delta

func play_animation() -> void:
	idle_animation.play()

func flip_animations(flip_h: bool, flip_v: bool) -> void:
	idle_animation.flip_h = flip_h
	idle_animation.flip_v = flip_v
	spawn_animation.flip_h = flip_h
	spawn_animation.flip_v = flip_v
	despawn_animation.flip_h = flip_h
	despawn_animation.flip_v = flip_v

func set_position_from_two_values(
	new_h_position: float, new_v_position: float
) -> void:
	global_position = Vector2(new_h_position, new_v_position)

func set_can_spawn_pieces(is_piece_spawner: bool) -> void:
	can_spawn_pieces = is_piece_spawner 

	idle_animation.self_modulate =\
			PIECE_SPAWNER_COLOR if is_piece_spawner else REGULAR_SPACE_COLOR

	despawn_animation.hide()
	spawn_animation.hide()
	idle_animation.show()
	idle_animation.play()
	visible = true

	manage_light(is_piece_spawner)

func get_can_spawn_pieces() -> bool:
	return can_spawn_pieces

func set_enabled(is_enabled: bool) -> void:
	about_to_disappear = false

	if not is_enabled:
		can_spawn_pieces = false
		can_spawn_powerups = false
		idle_animation.hide()
		spawn_animation.hide()
		despawn_animation.show()
		despawn_animation.play()
		yield(self, "despawned")
	elif was_despawned:
		manage_light(true)
		visible = true
		idle_animation.hide()
		despawn_animation.hide()
		spawn_animation.show()
		spawn_animation.play()
		yield(self, "spawned")
		was_despawned = false
	
	emit_signal("enabled")

func get_enabled() -> bool:
	return enabled

func show_waves() -> void:
	if not waves.is_playing():
		waves.show()
		waves.play()

func manage_light(on: bool) -> void:
	light.visible = on

func _on_waves_animation_finished():
	waves.stop()
	waves.set_frame(0)
	waves.hide()

func _on_spawn_animation_finished():
	spawn_animation.stop()
	spawn_animation.hide()
	spawn_animation.set_frame(0)
	idle_animation.show()
	enabled = true
	manage_light(false)
	emit_signal("spawned")

func _on_despawn_animation_finished():
	despawn_animation.stop()
	despawn_animation.set_frame(0)
	enabled = false
	visible = false
	was_despawned = true
	emit_signal("despawned")
