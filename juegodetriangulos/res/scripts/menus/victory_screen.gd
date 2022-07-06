# Functions used by the victory message screen
extends CanvasLayer

signal victory_screen_hidden

onready var bgm: AudioStreamPlayer = $bgm
onready var background: ColorRect = $background
onready var total_score: Label = $total_score
onready var victory_message: Label = $victory_message
onready var fade_in_tween: Tween = $fade_in_tween

var allow_input: bool

func _ready() -> void:
	allow_input = false
	pause_mode = Node.PAUSE_MODE_PROCESS
	fade_in_tween.interpolate_property(victory_message, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 3, Tween.TRANS_LINEAR, Tween.EASE_IN)
	fade_in_tween.interpolate_property(background, "color", Color(0, 0, 0, 0), Color(0, 0, 0, 0.75), 3, Tween.TRANS_LINEAR, Tween.EASE_IN)
	bgm.play()

func _input(event: InputEvent) -> void:
	if allow_input:
		if event is InputEventKey and event.pressed:
			get_tree().paused = false 
			hide_victory_screen()

func show_victory_screen() -> void:
	victory_message.show()
	background.rect_size = Globals.SCREEN_SIZE
	background.show()
	get_tree().paused = true 
	fade_in_tween.start()

func hide_victory_screen() -> void:
	victory_message.hide()
	background.hide()
	emit_signal("victory_screen_hidden")
	queue_free()

func _on_fade_in_tween_all_completed() -> void:
	allow_input = true
	var player_score = PlayerManager.get_player_score()
	var max_score = Utils.get_level_max_score()
	if player_score >= max_score:
		total_score.text = "Your score: %s\n(New best!)" % player_score 
	else:
		total_score.text = "Your score: %s\n(All time best: %s)" % [player_score, max_score]
	total_score.show()
