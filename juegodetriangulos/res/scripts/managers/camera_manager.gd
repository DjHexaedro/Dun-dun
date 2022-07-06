# Helper class with camera-related functions.
# Can be accessed from anywhere within the project
extends Node


var camera: Node

func _ready() -> void:
	camera = get_tree().get_root().get_node("Main").get_node("screen_shake")

func set_camera_target(target: NodePath) -> void:
	camera.target = target

func clear_camera_target() -> void:
	camera.target = null 

func shake_screen(target: Node = null, trauma_amount: float = 0.675, decay_amount: float = 0.2) -> void:
	if target != null:
		camera.target = target.get_path()
	camera.trauma = trauma_amount
	camera.decay = decay_amount
