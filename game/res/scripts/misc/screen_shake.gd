# Taken from: http://kidscancode.org/godot_recipes/2d/screen_shake/
# Script used to make the camera shake
extends Camera2D

onready var noise: OpenSimplexNoise = OpenSimplexNoise.new()
var noise_y: int = 0

export (NodePath) var target = null setget set_target
var trauma: float = 0.0 setget add_trauma
var trauma_power: int = 2
var decay: float = 0.2 setget set_decay

func _ready():
	randomize()
	noise.seed = randi()
	noise.period = 4
	noise.octaves = 2

func set_target(new_target):
	target = new_target

func set_decay(new_decay):
	decay = new_decay

func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)

func _process(delta):
	if target:
	  global_position = get_node(target).global_position
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()

func shake():
	var amount = pow(trauma, trauma_power)
	noise_y += 1
	rotation = 0.1 * amount * noise.get_noise_2d(noise.seed, noise_y)
	offset.x = 100 * amount * noise.get_noise_2d(noise.seed * 2, noise_y)
	offset.y = 75 * amount * noise.get_noise_2d(noise.seed * 3, noise_y)
