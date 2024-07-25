# Functions used by the victory message screen
extends CanvasLayer

signal victory_screen_hidden
signal score_calculated

onready var bgm: AudioStreamPlayer = $bgm
onready var background: ColorRect = $background
onready var total_score: Label = $total_score
onready var victory_message: Label = $victory_message
onready var fade_in_tween: Tween = $fade_in_tween

var allow_input: bool
var current_level_index: int
var player_score: int = -1
var calculate_score_thread: Thread = Thread.new()

func _ready() -> void:
	allow_input = false
	pause_mode = Node.PAUSE_MODE_PROCESS
	fade_in_tween.interpolate_property(
		victory_message, "modulate",
		Color(1, 1, 1, 0), Color(1, 1, 1, 1),
		3, Tween.TRANS_LINEAR, Tween.EASE_IN
	)
	fade_in_tween.interpolate_property(
		background, "color",
		Color(0, 0, 0, 0), Color(0, 0, 0, 0.75),
		3, Tween.TRANS_LINEAR, Tween.EASE_IN
	)
	calculate_score_thread.start(self, "_calculate_final_score")
	bgm.play()

func _input(event: InputEvent) -> void:
	if allow_input:
		if event is InputEventKey and event.pressed:
			get_tree().paused = false 
			hide_victory_screen()

func _calculate_final_score() -> void:
	var match_history: Array = GameStateManager.get_match_history()
	var calculated_score: int = 0

	for entry in match_history:
		match entry.event:
			Globals.MatchEvents.PLAYER_HEAL_AS_SCORE:
				calculated_score += 15000

			Globals.MatchEvents.CRYSTAL_GRABBED:
				calculated_score += pow(5 * entry.additional_info, 2) * GameStateManager.get_score_multiplier()
	
	player_score = calculated_score
	emit_signal("score_calculated")


func show_victory_screen(level_index: int) -> void:
	victory_message.show()
	background.rect_size = Globals.SCREEN_SIZE
	background.show()
	get_tree().paused = true 
	current_level_index = level_index
	fade_in_tween.start()

func hide_victory_screen() -> void:
	victory_message.hide()
	background.hide()
	emit_signal("victory_screen_hidden")
	queue_free()

func _on_fade_in_tween_all_completed() -> void:
	if player_score == -1:
		yield(self, "score_calculated")

	allow_input = true
	total_score.text = "Your score: %s" % player_score
	var max_score = Settings.get_game_statistic("level_scores", 0, "level%s_top" % current_level_index)
	if player_score >= max_score:
		total_score.text = "Your score: %s\n(New best!)" % player_score 
	else:
		total_score.text = "Your score: %s\n(All time best: %s)" % [player_score, max_score]
	total_score.show()
