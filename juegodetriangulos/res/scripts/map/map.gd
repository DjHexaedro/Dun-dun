extends Node2D

var level_list = []
var level_count
var current_level_node
var selected_level = 0
var previous_level = selected_level

func _ready():
	level_count = $level_list.get_child_count()
	var saved_game_data = Settings.get_saved_game_data()
	var last_level = 0
	var inside_level = false
	if saved_game_data:
		last_level = saved_game_data.get("selected_level", 0)
		inside_level = saved_game_data.get("inside_level", false)
		var level_list = saved_game_data.get("level_list", {})
		for level_path in level_list.keys():
			get_node(level_path).set_level_state(level_list[level_path])
	if last_level:
		selected_level = last_level
	var selected_level_node = $level_list.get_child(selected_level)
	var selected_level_position = selected_level_node.position
	$player_marker.set_position_without_moving(Vector2(selected_level_position.x, selected_level_position.y - 15))
	show()
	# if inside_level:
	hide_map_and_start_level()

func _input(event):
	if visible:
		if event.is_action_pressed("ui_accept"):
			hide_map_and_start_level()
		if not $player_marker.is_moving:
			if event.is_action_pressed("player_moveright") or event.is_action_pressed("ui_right"):
				selected_level += 1
			if event.is_action_pressed("player_moveleft") or event.is_action_pressed("ui_left"):
				selected_level -= 1
			selected_level = clamp(selected_level, 0, level_count - 1)
			if selected_level != previous_level:
				move_player_marker(selected_level)

func hide_map_and_start_level():
	hide()
	$level_list.get_child(selected_level).start_level()

func set_current_level_node(level_node):
	current_level_node = level_node

func show():
	visible = true 
	$player_marker.visible = true
	$level_list.visible = true

func hide():
	visible = false
	$player_marker.visible = false
	$level_list.visible = false

func move_player_marker(level):
	$player_marker.move($level_list.get_child(level).position)
	previous_level = level
