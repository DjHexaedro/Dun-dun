# Main script of the game. It's the one that starts everything up.
# Not to be confused with the main_menu script, which is used by the main menu.
extends Node

onready var logo_animations: AnimatedSprite = $logo_animations
onready var main_menu_canvas: CanvasLayer = $main_menu
onready var pause_menu_canvas: CanvasLayer = $pause_menu
onready var white_bg_sprite: Sprite = $white_bg
onready var mapscene: PackedScene = preload("res://juegodetriangulos/scenes/map/map.tscn")

func _ready() -> void:
	randomize()
	logo_animations.connect("splash_over", self, "_on_splash_over")
	main_menu_canvas.hide_main_screen()
	logo_animations.visible = true
	logo_animations.play()

func game_start() -> void:
	white_bg_sprite.visible = false
	var map: Node = mapscene.instance()
	get_tree().get_root().add_child(map)
	pause_menu_canvas.enabled = true

func _on_splash_over() -> void:
	main_menu_canvas.show_main_screen()
