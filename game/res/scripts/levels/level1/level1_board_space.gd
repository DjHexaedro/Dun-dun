extends Node2D


var can_spawn_pieces = false

func set_position_from_two_values(new_h_position: float, new_v_position: float):
	global_position = Vector2(new_h_position, new_v_position)

func set_can_spawn_pieces(can_spawn_pieces: bool):
	self.can_spawn_pieces = can_spawn_pieces
	if can_spawn_pieces:
		get_node("graphics").modulate = Color("#000000")
	else:
		get_node("graphics").modulate = Color(Settings.colors[3])
