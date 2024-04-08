extends Node2D

class_name BaseMapArea

var areas_to_load: Array = []


func disable_map_area():
	var children_list: Array = get_children()
	for child in children_list:
		manage_map_nodes(child, true)

func enable_map_area():
	var children_list: Array = get_children()
	for child in children_list:
		manage_map_nodes(child, false)

func set_camera_focus(smoothing: bool) -> void:
	CameraManager.set_camera_target(get_path(), smoothing)

func manage_map_nodes(node: Node, disable: bool):
	var children_list: Array = node.get_children()
	if children_list:
		for child_node in children_list:
			manage_map_nodes(child_node, disable)
	else:
		if node.is_in_group("to_disable"):
			node.set_deferred("disabled", disable)
		if node.is_in_group("to_not_enable"):
			node.enabled = not disable

func get_enemy_positions_list() -> Dictionary:
	return {}

# The center of some arenas isn't their global position.
# They will override this function to return the correct value.
func get_center() -> Vector2:
	return global_position

func manage_powerup_spawn_points(_area_name: String, _spawn_point_name_list: Array, _enabled: bool) -> void:
	pass

func reset() -> void:
	pass
