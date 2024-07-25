# Functions used by the main menu screen.
extends CanvasLayer


signal start_game

const MENU_OPTIONS_FUNCTIONS: Array = [
	"_on_normal_pressed",
	"_on_hard_pressed",
	"_on_hardest_pressed",
	"_on_extra_challenges_pressed",
]

onready var statsscreenscene: PackedScene =\
		preload("res://juegodetriangulos/scenes/menu/stats_screen.tscn")

onready var animated_bg_sprite: AnimatedSprite = $menu_container/animated_bg
onready var game_start_music: AudioStreamPlayer = $game_start
onready var main_menu_music: AudioStreamPlayer = $main_menu_music
onready var exit_button: Button = $menu_container/exit
onready var options_button: Button = $menu_container/options
onready var stats_button: Button = $menu_container/stats
onready var selected_option_marker_sprite: Sprite =\
		$menu_container/selected_option_marker
onready var main_menu_container: VBoxContainer = $menu_container/main_menu
onready var menu_container: Control = $menu_container
onready var avaliable_bosses_container: Control =\
		$menu_container/boss_list
onready var demo_videoplayer: VideoPlayer = $demo
onready var demo_playing_label: Label = $demo_playing
onready var play_demo_timer: Timer = $play_demo_timer


var menu_options: Array = []
var boss_list: Array = []
var current_option: int = 0
var current_boss: int = 0
var on_main_menu: bool = false
var on_options_menu: bool = false
var on_extra_challenges_menu: bool = false
var options_window: Node
var joystick_ui_timer: Timer = Timer.new()
var can_move_joystick_ui: bool = true
var is_playing_demo: bool = false
var demo_video: VideoStreamTheora = VideoStreamTheora.new()
var base_menu_options: Array = []
var menu_options_boss_2: Array = []


func _ready() -> void:
	menu_options = main_menu_container.get_children()
	base_menu_options = menu_options.duplicate()

	menu_options_boss_2 = menu_options.duplicate()
	menu_options_boss_2.remove(2)

	boss_list = avaliable_bosses_container.get_children()

	options_window = Utils.get_options_menu()
	joystick_ui_timer.set_wait_time(0.1)
	joystick_ui_timer.connect("timeout", self, "_on_joystick_ui_timer_timeout")
	add_child(joystick_ui_timer)

	options_window.connect("options_menu_exit", self, "_on_options_menu_exit")
	get_parent().get_node("extra_challenges_menu").connect(
		"extra_challenges_menu_exit", self, "_on_extra_challenges_menu_exit"
	)

	play_demo_timer.start()

func _input(event: InputEvent) -> void:
	play_demo_timer.stop()

	if (
		on_main_menu and
		not is_playing_demo and
		not GameStateManager.get_on_options_menu() and
		not on_extra_challenges_menu
	):
		play_demo_timer.set_wait_time(120)

		if event.is_action_pressed("ui_cancel"):
			_on_exit_pressed()

		if event.is_action_pressed("open_options_menu"):
			_on_options_pressed()

		if (
			event.is_action_pressed("ui_up") or
			event.is_action_pressed("ui_down")
		):
			_update_current_option(
				-1 if event.is_action_pressed("ui_up") else 1
			)
		
		if (
			event.is_action_pressed("ui_up_joystick") or
			event.is_action_pressed("ui_down_joystick")
		) and can_move_joystick_ui:
			_update_current_option(
				-1 if event.is_action_pressed("ui_up_joystick") else 1
			)
			can_move_joystick_ui = false
			joystick_ui_timer.start()

		if (
			event.is_action_pressed("ui_left") or
			event.is_action_pressed("ui_right")
		):
			_update_current_boss(
				-1 if event.is_action_pressed("ui_left") else 1
			)
		
		if (
			event.is_action_pressed("ui_left_joystick") or
			event.is_action_pressed("ui_right_joystick")
		) and can_move_joystick_ui:
			_update_current_boss(
				-1 if event.is_action_pressed("ui_left_joystick") else 1
			)
			can_move_joystick_ui = false
			joystick_ui_timer.start()

		if event.is_action_pressed("ui_accept"):
			execute_menu_option()
	
	if is_playing_demo and (event is InputEventKey or event is InputEventJoypadButton):
		stop_demo()

	if on_main_menu and not is_playing_demo:
		play_demo_timer.start()

func _update_current_option(option_increase: int) -> void:
	current_option += option_increase
	if current_option < 0:
		current_option = len(menu_options) - 1
	if current_option > len(menu_options) - 1:
		current_option = 0
	set_selected_option_marker_position()

func _update_current_boss(boss_increase: int) -> void:
	current_boss += boss_increase
	if current_boss < 0:
		current_boss = len(boss_list) - 1
	elif current_boss > len(boss_list) - 1:
		current_boss = 0
	_on_boss_updated(current_boss)

func start_game(difficulty_level: int) -> void:
	# This should probably be handled by the function that receives the
	# start_game signal
	game_start_music.play()
	main_menu_music.stop()
	on_main_menu = false
	hide_main_screen()
	options_window.hide_options_menu()
	GameStateManager.set_difficulty_level(difficulty_level)
	emit_signal("start_game")

func play_demo() -> void:
	is_playing_demo = true
	demo_video.set_file(
		"res://juegodetriangulos/res/demos/demo_%s%s.ogv" %
		[0, randi()%2]
	)
	play_demo_timer.stop()
	main_menu_music.stop()
	demo_playing_label.show()
	demo_videoplayer.stream = demo_video
	demo_videoplayer.show()
	demo_videoplayer.play()

func stop_demo() -> void:
	is_playing_demo = false
	play_demo_timer.set_wait_time(30)
	play_demo_timer.start()
	demo_playing_label.hide()
	demo_videoplayer.stop()
	demo_videoplayer.hide()
	main_menu_music.play()

func _on_options_pressed() -> void:
	if on_main_menu:
		options_window.show_options_menu()
		on_options_menu = true

func _on_exit_pressed() -> void:
	if not on_options_menu:
		get_tree().quit()

func set_selected_option_marker_position() -> void:
	selected_option_marker_sprite.global_position = Vector2(
		menu_options[current_option].rect_global_position.x -
			(menu_options[current_option].rect_size.x / 2),
		menu_options[current_option].rect_global_position.y +
			(menu_options[current_option].rect_size.y / 2)
	)

func show_main_menu() -> void:
	current_option = 0
	GameStateManager.set_score_multiplier(1)
	menu_container.show()
	main_menu_music.play()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_parent().get_node("white_bg").visible = true
	set_selected_option_marker_position()
	_on_boss_updated(current_boss)
	yield(get_tree().create_timer(0.1), "timeout")
	on_main_menu = true 

func hide_main_screen() -> void:
	on_main_menu = false
	menu_container.hide()

func execute_menu_option() -> void:
	call(MENU_OPTIONS_FUNCTIONS[current_option])

func _on_normal_pressed() -> void:
	if not on_options_menu:
		start_game(Globals.DifficultyLevels.NORMAL)

func _on_normal_mouse_entered() -> void:
	current_option = 0

func _on_hard_pressed() -> void:
	if not on_options_menu:
		start_game(Globals.DifficultyLevels.HARD)

func _on_hard_mouse_entered() -> void:
	current_option = len(menu_options) - 2

func _on_hardest_pressed() -> void:
	if not on_options_menu:
		start_game(Globals.DifficultyLevels.HARDEST)

func _on_hardest_mouse_entered() -> void:
	current_option = len(menu_options) - 1

func _on_stats_pressed() -> void:
	if not on_options_menu:
		var stats_screen = statsscreenscene.instance()
		get_tree().get_root().add_child(stats_screen)

func _on_extra_challenges_pressed() -> void:
	if not on_options_menu:
		Utils.show_extra_challenges_screen()
		on_extra_challenges_menu = true

func _on_options_menu_exit() -> void:
	on_options_menu = false

func _on_extra_challenges_menu_exit() -> void:
	on_extra_challenges_menu = false

func _on_boss_updated(chosen_boss: int) -> void:
	for boss_id in range(len(boss_list)):
		boss_list[boss_id].visible = boss_id == chosen_boss
	
	if chosen_boss == 2:
		main_menu_container.get_node("hardest").hide()
		menu_options = menu_options_boss_2
	else:
		menu_options = base_menu_options
		main_menu_container.get_node("hardest").show()

	yield(get_tree().create_timer(0.1), "timeout")
	current_option = 0
	set_selected_option_marker_position()

	current_boss = chosen_boss
	GameStateManager.set_current_enemy("%s" % chosen_boss)
	Utils.update_extra_challenges_options(chosen_boss)

func _on_joystick_ui_timer_timeout() -> void:
	can_move_joystick_ui = true

func _on_boss_list_previous_pressed() -> void:
	_update_current_boss(-1)

func _on_boss_list_next_pressed() -> void:
	_update_current_boss(1)

func _on_play_demo_timer_timeout():
	play_demo()

func _on_demo_finished():
	stop_demo()
