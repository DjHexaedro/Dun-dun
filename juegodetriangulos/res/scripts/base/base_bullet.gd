# Base class for all proyectiles in the game
extends Node2D

class_name BaseBullet

var velocity: Vector2 = Vector2.ZERO
var base_speed: int
var direction: Vector2
var look_at: bool = true
var damage: int
var script_path: String
var bullet_type: String


func _ready() -> void:
	position = Globals.Positions.OUT_OF_BOUNDS
	script_path = get_script().get_path()
	bullet_type = script_path.left(script_path.find_last(".gd")).right(script_path.find_last("/") + 1)

# Variables like velocity and direction are set using the set() function,
# instead of the traditional variable = value. This is done because some bullets
# have properties that others don't, so this allows for the existence of a single
# method instead of multiple methods with different parameters.
func set_properties(params_dict: Dictionary) -> void:
	for key in params_dict:
		set(key, params_dict[key])

func shoot(params_dict: Dictionary) -> void:
	set_properties(params_dict)
	velocity = direction * base_speed
	if look_at:
		look_at(global_position + velocity)

# Unloading a bullet just resets it to a default state. It doesn't 
# free it from memory
func unload() -> void:
	velocity = Vector2.ZERO

func remove_from_active_bullets() -> void:
	ComplexBulletManager.remove_active_bullet(bullet_type, get_instance_id())

