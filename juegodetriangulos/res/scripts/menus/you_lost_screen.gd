# Functions used by the game over screen
extends CanvasLayer

signal exit_to_map
signal try_again 

const MENU_OPTIONS_TEXT: Array = ["Try again", "Exit level"]

onready var bgm: AudioStreamPlayer = $bgm
onready var exit_level: Button = $you_lost_menu/exit_level
onready var try_again: Button = $you_lost_menu/try_again
onready var background: ColorRect = $background
onready var total_score: Label = $total_score
onready var you_lost_message: Label = $you_lost_message
onready var blink_timer: Timer = $blink_timer
onready var unblink_timer: Timer = $unblink_timer
onready var fade_in_tween: Tween = $fade_in_tween
onready var you_lost_menu: VBoxContainer = $you_lost_menu

var menu_options: Array = []
var allow_input: bool
var current_option: int = 0


func _ready() -> void:
	Utils.set_level_max_score(PlayerManager.get_player_score())
	allow_input = false
	pause_mode = Node.PAUSE_MODE_PROCESS
	menu_options = [try_again, exit_level]
	fade_in_tween.interpolate_property(you_lost_message, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 3, Tween.TRANS_LINEAR, Tween.EASE_IN)
	fade_in_tween.interpolate_property(background, "color", Color(0, 0, 0, 0), Color(0, 0, 0, 0.75), 3, Tween.TRANS_LINEAR, Tween.EASE_IN)
	bgm.play()

func _input(event: InputEvent) -> void:
	if allow_input:
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			current_option = 1 if current_option == 0 else 0
			reset_timers()
		show_all_options()
		if event.is_action_pressed("ui_accept"):
			execute_menu_option()

func show_all_options() -> void:
	var i = 0
	while i < menu_options.size():
		menu_options[i].set_text(MENU_OPTIONS_TEXT[i])
		i += 1

func reset_timers() -> void:
	unblink_timer.stop()
	blink_timer.stop()
	unblink_timer.start()

func execute_menu_option() -> void:
	if current_option == 0:
		_on_try_again_pressed()
	elif current_option == 1:
		_on_exit_level_pressed()

func show_you_lost_screen() -> void:
	you_lost_message.show()
	background.rect_size = Globals.SCREEN_SIZE
	background.show()
	Utils.show_mouse_if_necessary()
	fade_in_tween.start()

func hide_you_lost_screen() -> void:
	you_lost_message.hide()
	background.hide()
	you_lost_menu.hide()
	total_score.hide()
	Utils.hide_mouse_if_necessary()
	get_tree().paused = false
	queue_free()

func pause_game() -> void:
	get_tree().paused = true 

func _on_try_again_pressed() -> void:
	hide_you_lost_screen()
	emit_signal("try_again")

func _on_exit_level_pressed() -> void:
	hide_you_lost_screen()
	emit_signal("exit_to_map")

func _on_fade_in_tween_all_completed() -> void:
	allow_input = true
	you_lost_menu.show()
	var player_score = PlayerManager.get_player_score()
	var max_score = Utils.get_level_max_score()
	if player_score >= max_score:
		total_score.text = "Your score: %s\n(New best!)" % player_score 
	else:
		total_score.text = "Your score: %s\n(All time best: %s)" % [player_score, max_score]
	total_score.show()

func _on_blink_timer_timeout() -> void:
	menu_options[current_option].set_text("")
	unblink_timer.start()

func _on_unblink_timer_timeout() -> void:
	menu_options[current_option].set_text(MENU_OPTIONS_TEXT[current_option])
	blink_timer.start()

func _on_try_again_mouse_entered() -> void:
	current_option = 0

func _on_exit_level_mouse_entered() -> void:
	current_option = 1
