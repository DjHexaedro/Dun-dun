# Helper class with camera-related functions.
# Can be accessed from anywhere within the project
extends Node


var camera: Node

func _ready() -> void:
	camera = Utils.get_main_node().get_node("screen_shake")

func get_camera_screen_center() -> Vector2:
	return camera.get_camera_screen_center()

func set_camera_target(target: NodePath, smoothing: bool) -> void:
	camera.smoothing_enabled = smoothing
	camera.target = target

func set_camera_zoom(zoom: Vector2) -> void:
	camera.zoom = zoom

func clear_camera_target() -> void:
	camera.target = null 

func reset_camera() -> void:
	set_camera_zoom(Vector2.ONE)
	clear_camera_target()

func shake_screen(target: Node = null, trauma_amount: float = 0.675, decay_amount: float = 0.2) -> void:
	if target != null:
		camera.target = target.get_path()
	camera.trauma = trauma_amount
	camera.decay = decay_amount
