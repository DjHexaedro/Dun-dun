# Functions used by the main menu screen.
extends CanvasLayer


signal start_game

const BLINK_DELAY = 0.5
const MENU_OPTIONS_TEXT = ["Normal", "Hard", "Hardest"]

onready var statsscreenscene: PackedScene = preload("res://juegodetriangulos/scenes/menu/stats_screen.tscn")
onready var animated_bg_sprite: AnimatedSprite = $animated_bg
onready var game_start_music: AudioStreamPlayer = $game_start
onready var main_menu_music: AudioStreamPlayer = $main_menu_music
onready var begin_button: Button = $begin
onready var exit_button: Button = $exit
onready var extra_challenges_button: Button = $extra_challenges
onready var hard_button: Button = $main_menu/hard
onready var hardest_button: Button = $main_menu/hardest
onready var normal_button: Button = $main_menu/normal
onready var options_button: Button = $options
onready var stats_button: Button = $stats
onready var start_game_label: Label = $start_game
onready var blink_timer: Timer = $blink_timer
onready var unblink_timer: Timer = $unblink_timer
onready var main_menu_container: VBoxContainer = $main_menu

var menu_options: Array = []
var blink: bool = false
var current_blink_timer: float = 0
var current_option: int = 0
var on_main_menu: bool = false
var on_options_menu: bool = false
var ingame: bool = false
var on_main_screen: bool = true
var options_window: Node
var first_click: bool


func _ready() -> void:
	menu_options = [normal_button, hard_button, hardest_button]
	if Utils.device_is_phone():
		options_window = get_tree().get_root().get_node("Main").get_node("options_menu_android")
	else:
		options_window = get_tree().get_root().get_node("Main").get_node("options_menu")
		options_window.connect("options_menu_exit", self, "_on_options_menu_exit")
	show_title_screen()
	_on_begin_pressed()

func _input(event: InputEvent) -> void:
	if on_main_screen and (event.is_action_pressed("ui_accept") or event.is_action_pressed("mouse_click") or event is InputEventScreenTouch):
		show_main_menu()
	elif on_main_menu and not GameStateManager.get_on_options_menu():
		if event.is_action_pressed("ui_up"):
			current_option -= 1
			if current_option < 0:
				current_option = 2
			reset_timers()
		if event.is_action_pressed("ui_down"):
			current_option += 1
			if current_option > 2:
				current_option = 0
			reset_timers()
		show_all_options()
		if event.is_action_pressed("ui_accept"):
			execute_menu_option()

func _on_begin_pressed() -> void:
	begin_button.hide()

func start_game(difficulty_level: int) -> void:
	# This should probably be handled by the function that receives the
	# start_game signal
	game_start_music.play()
	main_menu_music.stop()
	ingame = true
	on_main_menu = false
	hide_main_screen()
	unblink_timer.stop()
	blink_timer.stop()
	options_window.hide_options_menu()
	GameStateManager.set_difficulty_level(difficulty_level)
	emit_signal("start_game")

func _on_start_game_mouse_entered() -> void:
	current_option = 0

func _on_options_pressed() -> void:
	if not on_main_screen:
		options_window.show_options_menu()
		on_options_menu = true

func _on_options_mouse_entered() -> void:
	current_option = 1

func _on_exit_pressed() -> void:
	if not on_main_screen and not on_options_menu:
		get_tree().quit()

func _on_exit_mouse_entered() -> void:
	current_option = 2

func show_all_options() -> void:
	var i = 0
	while i < menu_options.size():
		menu_options[i].set_text(MENU_OPTIONS_TEXT[i])
		i += 1

func show_title_screen() -> void:
	on_main_screen = true 
	on_main_menu = false
	on_options_menu = false
	ingame = false

func show_main_menu() -> void:
	current_option = 0
	on_main_menu = true 
	start_game_label.hide()
	main_menu_container.show()
	extra_challenges_button.show()
	options_button.show()
	stats_button.show()
	exit_button.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	unblink_timer.start()
	get_tree().get_root().get_node("Main").get_node("white_bg").visible = true
	yield(get_tree().create_timer(0.25), "timeout")
	on_main_screen = false 

func show_main_screen() -> void:
	on_main_screen = true
	on_main_menu = false 
	on_options_menu = false
	ingame = false
	animated_bg_sprite.show()
	start_game_label.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	unblink_timer.start()
	main_menu_music.play()
	get_tree().get_root().get_node("Main").get_node("white_bg").visible = true

func hide_main_screen() -> void:
	on_main_screen = false
	on_main_menu = false
	animated_bg_sprite.hide()
	start_game_label.hide()
	main_menu_container.hide()
	options_button.hide()
	stats_button.hide()
	exit_button.hide()
	extra_challenges_button.hide()

func execute_menu_option() -> void:
	if current_option == 0:
		_on_normal_pressed()
	if current_option == 1:
		_on_hard_pressed()
	if current_option == 2:
		_on_hardest_pressed()

func reset_timers() -> void:
	unblink_timer.stop()
	blink_timer.stop()
	unblink_timer.start()

func _on_blink_timer_timeout() -> void:
	if on_main_screen:
		start_game_label.visible = false
	elif on_main_menu:
		menu_options[current_option].set_text("")
	unblink_timer.start()

func _on_unblink_timer_timeout() -> void:
	if on_main_screen:
		start_game_label.visible = true 
	elif on_main_menu:
		menu_options[current_option].set_text(MENU_OPTIONS_TEXT[current_option])
	blink_timer.start()

func _on_normal_pressed() -> void:
	if not on_main_screen and not on_options_menu:
		start_game(Globals.DifficultyLevels.NORMAL)

func _on_normal_mouse_entered() -> void:
	current_option = 0

func _on_hard_pressed() -> void:
	if not on_main_screen and not on_options_menu:
		start_game(Globals.DifficultyLevels.HARD)

func _on_hard_mouse_entered() -> void:
	current_option = 1

func _on_hardest_pressed() -> void:
	if not on_main_screen and not on_options_menu:
		start_game(Globals.DifficultyLevels.HARDEST)

func _on_hardest_mouse_entered() -> void:
	current_option = 2

func _on_stats_pressed() -> void:
	if not on_main_screen and not on_options_menu:
		var stats_screen = statsscreenscene.instance()
		get_tree().get_root().add_child(stats_screen)

func _on_extra_challenges_pressed() -> void:
	if not on_main_screen and not on_options_menu:
		Utils.show_extra_challenges_screen()

func _on_options_menu_exit() -> void:
	on_options_menu = false
