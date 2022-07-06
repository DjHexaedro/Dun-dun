# Functions used by the pause menu
extends CanvasLayer


const BLINK_DELAY = 0.5

onready var close_pause_menu_button: Button = $close_pause_menu
onready var exit_button: Button = $exit
onready var options_button: Button = $options
onready var retry_button: Button = $retry
onready var background_rect: ColorRect = $background
onready var title_texture: TextureRect = $title
onready var blink_timer: Timer = $blink_timer
onready var unblink_timer: Timer = $unblink_timer

var menu_options: Array = []
var blink: bool = false
var current_blink_timer: int = 0
var current_option: int = 0
var in_pause_menu: bool = false
var main_menu: Node
var enabled: bool = true
var options_window: Node

func _ready() -> void:
	menu_options = [close_pause_menu_button, options_button, exit_button]
	pause_mode = Node.PAUSE_MODE_PROCESS
	main_menu = get_tree().get_root().get_node("Main").get_node("main_menu")
	if Utils.device_is_phone():
		options_window = get_tree().get_root().get_node("Main").get_node("options_menu_android")
	else:
		options_window = get_tree().get_root().get_node("Main").get_node("options_menu")

func _input(event: InputEvent) -> void:
	if enabled:
		if event.is_action_pressed("show_pause_menu") or event.is_action_pressed("show_pause_menu_controller"):
			if main_menu.ingame:
				if in_pause_menu:
					current_option = 0
					execute_menu_option()
				else:
					manage_pausing(true)
		if in_pause_menu:
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

func _on_continue_pressed() -> void:
	manage_pausing(false)

func _on_continue_mouse_entered() -> void:
	current_option = 0

func _on_options_pressed() -> void:
	options_window.show_options_menu()

func _on_options_mouse_entered() -> void:
	current_option = 1

func _on_exit_pressed() -> void:
	var level_node = get_tree().get_root().get_node("map").current_level_node
	if level_node:
		level_node.end_level()
		get_tree().get_root().get_node("map").queue_free()
		get_tree().paused = false 
		manage_pausing(false)
		main_menu.show_main_screen()
		enabled = false

func _on_exit_mouse_entered() -> void:
	current_option = 2

func show_all_options() -> void:
	var i = 0
	while i < menu_options.size():
		menu_options[i].add_color_override("font_color", Color(1, 1, 1, 1))
		menu_options[i].add_color_override("font_color_hover", Color(1, 1, 1, 1))
		i += 1

func show_pause_menu() -> void:
	current_option = 0
	title_texture.show()
	unblink_timer.start()
	background_rect.rect_size = Globals.SCREEN_SIZE
	background_rect.show()
	exit_button.show()
	retry_button.show()
	close_pause_menu_button.show()
	options_button.show()
	Utils.show_mouse_if_necessary()
	in_pause_menu = true

func hide_pause_menu() -> void:
	title_texture.hide()
	background_rect.hide()
	exit_button.hide()
	retry_button.hide()
	close_pause_menu_button.hide()
	options_button.hide()
	Utils.hide_mouse_if_necessary()
	in_pause_menu = false

func execute_menu_option() -> void:
	if current_option == 0:
		_on_continue_pressed()
	if current_option == 1:
		_on_options_pressed()
	if current_option == 2:
		_on_exit_pressed()

func reset_timers() -> void:
	unblink_timer.stop()
	blink_timer.stop()
	unblink_timer.start()

func manage_pausing(paused: bool) -> void:
	PlayerManager.set_player_velocity(Vector2.ZERO)
	var player_node = get_tree().get_root().get_node(Globals.NodeNames.PLAYER)
	var crosshair = false
	if not player_node:
		player_node = get_tree().get_root().get_node("map")
	else:
		crosshair = get_tree().get_root().get_node("crosshair")
	if player_node:
		player_node.set_process_input(not paused)
		if crosshair:
			crosshair.visible = not paused
		get_tree().paused = paused
	if paused:
		show_pause_menu()
	else:
		hide_pause_menu()

func _on_blink_timer_timeout() -> void:
	menu_options[current_option].add_color_override("font_color", Color(1, 1, 1, 0))
	menu_options[current_option].add_color_override("font_color_hover", Color(1, 1, 1, 0))
	unblink_timer.start()

func _on_unblink_timer_timeout() -> void:
	menu_options[current_option].add_color_override("font_color", Color(1, 1, 1, 1))
	menu_options[current_option].add_color_override("font_color_hover", Color(1, 1, 1, 1))
	blink_timer.start()

func _on_close_pause_menu_pressed() -> void:
	current_option = 0
	execute_menu_option()

func _on_retry_pressed() -> void:
	Utils.get_map_current_level_node().restart_level()
	_on_close_pause_menu_pressed()
