extends Node2D

# Can be different from global_position
var player_revive_position: Vector2 = Vector2.ZERO

func set_player_revive_position(new_player_revive_position: Vector2) -> void:
	player_revive_position = new_player_revive_position

func get_player_revive_position() -> Vector2:
	return player_revive_position

func set_player_corpse_graphics(player_id: int, flip_h: bool) -> void:
	for i in range(get_child_count()):
		get_node("corpse%s" % i).visible = i == player_id
		get_node("corpse%s" % i).flip_h = flip_h
