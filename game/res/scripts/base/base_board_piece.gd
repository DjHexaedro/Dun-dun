extends KinematicBody2D

var current_vertical_position
var current_horizontal_position
var next_vertical_position
var next_horizontal_position
var speed
var board_space_list
var board_space_vertical_size
var board_space_horizontal_size
var board_space_spawners
var owner_data
var player_data
var level_data
var velocity
var is_player_above
var is_player_below
var is_player_right
var is_player_left
var vertical_movement = false


func _ready():
	player_data = PlayerManager.player
	level_data = get_tree().get_root().get_node("map").get_node("level_list").get_node("level1")
	board_space_list = level_data.board_space_list
	board_space_spawners = level_data.board_space_spawners
	board_space_vertical_size = level_data.board_vertical_size
	board_space_horizontal_size = level_data.board_horizontal_size
	owner_data = level_data.level_enemy
	$can_move_timer.start()

func _physics_process(delta):
	if next_vertical_position != current_vertical_position or next_horizontal_position != current_horizontal_position:
		velocity = position.direction_to(board_space_list[next_vertical_position][next_horizontal_position].global_position) * speed * delta
		if position.distance_to(board_space_list[next_vertical_position][next_horizontal_position].global_position) > 5:
			var collision = move_and_collide(velocity)
			if collision and collision.collider.get_name() == Globals.NodeNames.PLAYER:
				on_collision(collision.collider)
		else:
			on_destination_reached()

func on_destination_reached():
	current_vertical_position = next_vertical_position 
	current_horizontal_position = next_horizontal_position 
	$unload_timer.start()

func on_collision(collider):
	unload()
	collider.get_hit(self)

func set_initial_position(new_position):
	position = board_space_list[new_position['row']][new_position['column']].global_position
	current_vertical_position = new_position['row']
	current_horizontal_position = new_position['column']
	next_vertical_position = new_position['row']
	next_horizontal_position = new_position['column']

func set_direction():
	is_player_below = false
	is_player_above = false
	is_player_right = false
	is_player_left = false
	if player_data.current_vertical_position > current_vertical_position:
		is_player_below = true 
	elif player_data.current_vertical_position < current_vertical_position:
		is_player_above = true
	if player_data.current_horizontal_position > current_horizontal_position:
		is_player_right = true
	elif player_data.current_horizontal_position < current_horizontal_position:
		is_player_left = true 
	var vertical_distance = abs(player_data.current_vertical_position - current_vertical_position)
	var horizontal_distance = abs(player_data.current_horizontal_position - current_horizontal_position)
	if vertical_distance > horizontal_distance:
		vertical_movement = true
	elif vertical_distance < horizontal_distance:
		vertical_movement = false
	else:
		vertical_movement = [false, true][randi()%2]

func unload():
	if owner_data != null:
		var piece_index = owner_data.spawned_pieces_list.find(self)
		if piece_index != null:
			owner_data.spawned_pieces_list.remove(piece_index)
	queue_free()

func _on_unload_timer_timeout():
	unload()
