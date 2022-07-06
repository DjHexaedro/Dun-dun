# Manages the buttons that appear onscreen when using the Android HUD
extends Control


var pause_menu: Node


func _ready() -> void:
	pause_menu = get_tree().get_root().get_node("Main").get_node("pause_menu")

func _on_pause_menu_pressed() -> void:
	if pause_menu.enabled:
		pause_menu.manage_pausing(true)
