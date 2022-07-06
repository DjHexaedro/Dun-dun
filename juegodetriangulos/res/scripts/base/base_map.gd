# Base class for the map that existed a long time ago. Will probably be deleted
# in a future update, as most of what's here is pretty old stuff.
extends Node2D

class_name BaseMap

const MARKER_IDLE_SPEED = 30
const MARKER_SPEED = 100

onready var player_marker: KinematicBody2D = $player_marker
onready var level_list: Node2D = $level_list

var level_count: int
var new_level_index: int
var current_level_index: int
var current_level: Node
var player_marker_velocity: Vector2 = Vector2()
var marker_idle_movement_multiplier: int = -1
var player_marker_move: bool = false

func _ready() -> void:
	color_player_marker()
	level_count = level_list.get_child_count()
	current_level_index = 0
	new_level_index = current_level_index
	current_level = level_list.get_node("level%s" % current_level_index)
	player_marker.position.x = current_level.position.x
	player_marker.position.y = current_level.position.y

func _input(event):
	if visible:
		if event.is_action_pressed("player_moveright"):
			new_level_index = clamp(current_level_index + 1, 0, level_count)
		if event.is_action_pressed("player_moveleft"):
			new_level_index = clamp(current_level_index - 1, 0, level_count)
		if new_level_index != current_level_index:
			current_level_index = new_level_index
			current_level = level_list.get_node("level%s" % current_level_index)
			player_marker_move = true

func _process(delta):
	if visible and not player_marker_move:
		if (player_marker.position.y >= (current_level.position.y + 30)) or (player_marker.position.y <= (current_level.position.y - 30)):
			marker_idle_movement_multiplier *= -1
		player_marker.position.y += MARKER_IDLE_SPEED * delta * marker_idle_movement_multiplier

func _physics_process(delta):
	if player_marker_move:
		player_marker_velocity = player_marker.position.direction_to(current_level.position) * MARKER_SPEED * delta
		if player_marker.position.distance_to(current_level.position) > 10:
			player_marker.position += player_marker_velocity
		else:
			player_marker.position = current_level.position
			player_marker_move = false

func show():
	visible = true
	player_marker.visible = true
	level_list.visible = true

func hide():
	visible = false 
	player_marker.visible = false
	level_list.visible = false

func color_player_marker():
	var parts_count = player_marker.get_child_count()
	var current_part = 0
	while current_part < parts_count:
		player_marker.get_node("player_marker_section%s" % current_part).modulate = Color(Settings.colors[current_part])
		current_part += 1
