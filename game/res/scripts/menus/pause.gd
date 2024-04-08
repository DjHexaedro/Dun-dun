# Functions used by the pause menu
extends CanvasLayer


onready var continue_button: Button = $continue
onready var exit_button: Button = $exit
onready var options_button: Button = $options
onready var retry_button: Button = $retry
onready var background_rect: ColorRect = $background
onready var title_texture: TextureRect = $title

var menu_options: Array = []
var in_pause_menu: bool = false
var main_menu: Node
var enabled: bool = false
var options_window: Node
var on_options_menu: bool = false 

func _ready() -> void:
	menu_options = [continue_button, options_button, exit_button]
	pause_mode = Node.PAUSE_MODE_PROCESS
	options_window = Utils.get_options_menu()
	options_window.connect("options_menu_exit", self, "_on_options_menu_exit")

func _input(event: InputEvent) -> void:
	if enabled:
		if event.is_action_pressed("show_pause_menu") or event.is_action_pressed("show_pause_menu_controller"):
			if main_menu.ingame:
				if in_pause_menu:
					_on_continue_pressed()
				else:
					manage_pausing(true)
		if in_pause_menu:
			if event.is_action_pressed("open_options_menu"):
				_on_options_pressed()
			if event.is_action_pressed("pause_menu_retry"):
				_on_retry_pressed()
			if event.is_action_pressed("pause_menu_quit_game"):
				_on_exit_pressed()

func _on_continue_pressed() -> void:
	manage_pausing(false)

func _on_options_pressed() -> void:
	on_options_menu = true
	options_window.show_options_menu()

func _on_exit_pressed() -> void:
	manage_pausing(false)
	GameStateManager.exit_to_map()
	enabled = false

func show_pause_menu() -> void:
	background_rect.rect_size = Globals.SCREEN_SIZE
	show()
	Utils.show_mouse_if_necessary()
	in_pause_menu = true

func hide_pause_menu() -> void:
	hide()
	Utils.hide_mouse_if_necessary()
	in_pause_menu = false

func manage_pausing(paused: bool) -> void:
	for player_id in range(PlayerManager.get_number_of_players()):
		PlayerManager.set_player_velocity(Vector2.ZERO, player_id)
		PlayerManager.get_player_node(player_id).set_process_input(not paused)
	get_tree().paused = paused
	if paused:
		show_pause_menu()
	else:
		hide_pause_menu()

func _on_retry_pressed() -> void:
	if not on_options_menu:
		GameStateManager.restart_level()
		_on_continue_pressed()

func _on_options_menu_exit() -> void:
	on_options_menu = false
