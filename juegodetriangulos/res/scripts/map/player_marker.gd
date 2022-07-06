extends KinematicBody2D


var velocity = Vector2()
var idle_animation_vertical_speed = 15
var moving_speed = 450
var move_to_position = position
var is_moving = false

#func _ready():
#	$player_marker_section0.modulate = Color(Settings.colors[0])
#	$player_marker_section1.modulate = Color(Settings.colors[1])
#	$player_marker_section2.modulate = Color(Settings.colors[2])

func _physics_process(delta):
	if is_moving:
		velocity = position.direction_to(move_to_position) * moving_speed * delta
		if position.distance_to(move_to_position) > 5:
			velocity = move_and_collide(velocity)
		else:
			is_moving = false
			position = move_to_position
	else:
		var y_increment = idle_animation_vertical_speed * delta
		position.y += y_increment
		# I'm not really sure why this statement needs to be like this, as I would
		# expect the following one to work fine, but it doesn't:
		# if position.y <= move_to_position.y - 15 or position.y >= move_to_position.y
		# Even though it sometimes works correctly, sometimes it doesn't move
		# the marker up and down. I guess it has something to do with me
		# manually setting the position to level_position.y - 15, but whatever,
		# this version works perfectly.
		if position.y <= move_to_position.y - 16 or position.y >= move_to_position.y + 1:
			idle_animation_vertical_speed *= -1

func move(new_position):
	position.y = move_to_position.y
	move_to_position = Vector2(new_position.x, new_position.y - 15)
	is_moving = true

func set_position_without_moving(new_position):
	position = new_position
	move_to_position = position
