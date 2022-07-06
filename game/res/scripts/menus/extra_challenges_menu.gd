# Functions used by the extra challenges screen
extends CanvasLayer

onready var missed_grabs_do_damage_checkbox: CheckBox = $container/missed_grabs_do_damage
onready var moving_does_damage_checkbox: CheckBox = $container/moving_does_damage
onready var standing_still_does_damage_checkbox: CheckBox = $container/standing_still_does_damage
onready var edge_touching_does_damage_checkbox: CheckBox = $container/edge_touching_does_damage
onready var one_hit_death_checkbox: CheckBox = $container/one_hit_death
onready var only_perfect_grabs_checkbox: CheckBox = $container/only_perfect_grabs
onready var container_node: Panel = $container

func _on_one_hit_death_pressed() -> void:
	GameStateManager.set_one_hit_death(one_hit_death_checkbox.pressed)

func _on_only_perfect_grabs_pressed() -> void:
	GameStateManager.set_only_perfect_grabs(only_perfect_grabs_checkbox.pressed)

func _on_missed_grabs_do_damage_pressed() -> void:
	GameStateManager.set_missed_grabs_do_damage(missed_grabs_do_damage_checkbox.pressed)

func _on_moving_deals_damage_pressed() -> void:
	GameStateManager.set_moving_does_damage(moving_does_damage_checkbox.pressed)

func _on_standing_still_deals_damage_pressed() -> void:
	GameStateManager.set_standing_still_does_damage(standing_still_does_damage_checkbox.pressed)

func _on_edge_touching_deals_damage_pressed() -> void:
	GameStateManager.set_edge_touching_does_damage(edge_touching_does_damage_checkbox.pressed)

func _on_save_button_pressed() -> void:
	container_node.hide()
