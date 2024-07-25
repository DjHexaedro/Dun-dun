# Base class for all the little helpers each boss will have. As of right now
# they can't be interacted with, so there's no functional difference between
# a "minion" and a "bullet that shoots more bullets"
extends Node2D

class_name BaseMinion


const FADE_IN_TIME: float = 2.5
const ATTACKING_TIMER_DELAY: int = 1

onready var attack_animation: AnimatedSprite = $attack_animation
onready var spawn_animation: AnimatedSprite = $spawn_animation
onready var despawn_animation: AnimatedSprite = $despawn_animation
onready var attack_cooldown_timer: Timer = $attack_cooldown_timer
onready var begin_attacking_timer: Timer = $begin_attacking_timer

var bullet_speed: int
var bullet_size: Vector2
var max_bullet_speed: int
var min_bullet_speed: int
var damage_threshold: int
var can_attack: bool = false
var chosen_bullet_direction: String = "RIGHT"
var attack_speed: int
var spawned: bool = false

func spawn(params_dict: Dictionary) -> void:
	
	# Variables like bullet_speed and bullet_size are set using the set()
	# function, instead of the traditional variable = value. This is done
	# because some minions have properties that others don't, so this allows
	# for the existence of a single method instead of multiple methods
	# with different parameters.
	for key in params_dict:
		set(key, params_dict[key])

	for player in PlayerManager.get_player_list():
		player.connect("player_death", self, "player_died")
	attack_animation.speed_scale = attack_speed
	spawn_animation.visible = true 
	spawn_animation.set_frame(0)
	spawn_animation.play()

func despawn(reset: bool = false) -> void:
	begin_attacking_timer.stop()
	can_attack = false
	spawn_animation.visible = false
	spawn_animation.set_frame(0)
	attack_animation.visible = false
	attack_animation.set_frame(0)
	despawn_animation.visible = true 
	despawn_animation.set_frame(0)
	if reset:
		despawn_animation.visible = false
		global_position = Globals.OUT_OF_BOUNDS_POSITION
	else:
		despawn_animation.play()
	spawned = false 

func attack() -> void:
	pass

func get_bullet_direction(new_bullet_direction: String) -> Vector2:
	return Globals.Directions[new_bullet_direction]

# Default shoot function. Will probably be deleted as I believe it's no longer used
func shoot(bulletscene: PackedScene, _direction: Vector2 = Vector2.ZERO, _speed: int = 0) -> void:
	var bullet_direction = get_bullet_direction(chosen_bullet_direction)
	var params_dict = {
		"global_position": position,
		"base_speed": bullet_speed,
		"owner_data": self.owner_data,
		"scale": bullet_size,
		"direction": bullet_direction,
	}
	SimpleBulletManager.create_and_shoot_bullet(bulletscene, params_dict)

func begin_attacking() -> void:
	attack_cooldown_timer.start()

func _on_begin_attacking_timer_timeout() -> void:
	begin_attacking()

func _on_attack_animation_animation_finished() -> void:
	attack()
	attack_animation.visible = false 
	attack_animation.stop()
	spawn_animation.visible = true 

func _on_spawn_animation_animation_finished() -> void:
	spawn_animation.stop()
	can_attack = true
	spawned = true

func _on_despawn_animation_animation_finished() -> void:
	despawn_animation.stop()
	global_position = Globals.OUT_OF_BOUNDS_POSITION
