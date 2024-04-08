extends Node2D

onready var can_move_timer: Timer = $can_move_timer

var current_vertical_position: int
var current_horizontal_position: int
var next_vertical_position: int
var next_horizontal_position: int
var speed: int
var owner_data
var player_data
var velocity
var is_player_above
var is_player_below
var is_player_right
var is_player_left
var vertical_movement = false
var can_move: bool = false
var board_info: Dictionary = {}


func _ready():
	player_data = PlayerManager.get_player_node()
	board_info = ArenaManager.get_current_location().get_board_info()
	can_move_timer.start()
	
func _process(delta: float) -> void:
	if can_move:
		global_position += velocity * delta
		if global_position.distance_to(board_info.SPACE_LIST[next_vertical_position][next_horizontal_position].global_position) < 5:
			global_position = board_info.SPACE_LIST[next_vertical_position][next_horizontal_position].global_position
			on_destination_reached()

func on_destination_reached():
	current_vertical_position = next_vertical_position 
	current_horizontal_position = next_horizontal_position 
	$unload_timer.start()

func on_collision(collider):
	unload()
	collider.get_hit(self)

func set_initial_position(new_position):
	position = board_info.SPACE_LIST[new_position['row']][new_position['column']].global_position
	current_vertical_position = new_position['row']
	current_horizontal_position = new_position['column']
	next_vertical_position = new_position['row']
	next_horizontal_position = new_position['column']

#func set_direction():
#	is_player_below = false
#	is_player_above = false
#	is_player_right = false
#	is_player_left = false
#	if player_data.current_vertical_position > current_vertical_position:
#		is_player_below = true 
#	elif player_data.current_vertical_position < current_vertical_position:
#		is_player_above = true
#	if player_data.current_horizontal_position > current_horizontal_position:
#		is_player_right = true
#	elif player_data.current_horizontal_position < current_horizontal_position:
#		is_player_left = true 
#	var vertical_distance = abs(player_data.current_vertical_position - current_vertical_position)
#	var horizontal_distance = abs(player_data.current_horizontal_position - current_horizontal_position)
#	if vertical_distance > horizontal_distance:
#		vertical_movement = true
#	elif vertical_distance < horizontal_distance:
#		vertical_movement = false
#	else:
#		vertical_movement = [false, true][randi()%2]

func unload():
	if owner_data != null:
		var piece_index = owner_data.spawned_pieces_list.find(self)
		if piece_index != null:
			owner_data.spawned_pieces_list.remove(piece_index)
	queue_free()

func _on_unload_timer_timeout():
	unload()
