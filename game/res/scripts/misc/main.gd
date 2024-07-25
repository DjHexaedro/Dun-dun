# Main script of the game. It's the one that starts everything up.
# Not to be confused with the menus/main.gd script, which is used by the main menu.
extends Node

onready var mainmenuscene: PackedScene =\
		preload("res://juegodetriangulos/scenes/menu/main_menu.tscn")
onready var androidmainmenuscene: PackedScene =\
		preload("res://juegodetriangulos/scenes/menu/main_menu_android.tscn")

onready var logo_animations: AnimatedSprite = $logo_animations
onready var pause_menu_canvas: CanvasLayer = $pause_menu
onready var white_bg_sprite: Sprite = $white_bg

var main_menu_canvas: CanvasLayer

func _ready() -> void:
	randomize()

	main_menu_canvas = (
		androidmainmenuscene.instance()
		if Utils.device_is_phone()
		else mainmenuscene.instance()
	)
	add_child(main_menu_canvas)
	main_menu_canvas.connect("start_game", self, "game_start")
	main_menu_canvas.connect("start_game", GameStateManager, "initialize_game_objects")

	logo_animations.connect("splash_over", main_menu_canvas, "show_main_menu")
	logo_animations.visible = true
	logo_animations.play()

func game_start() -> void:
	white_bg_sprite.visible = false
	pause_menu_canvas.main_menu = main_menu_canvas
	pause_menu_canvas.enabled = true
