extends Area2D

onready var score_panel: Panel = $score_panel
onready var score_panel_text: Label = $score_panel/text

const TIMES_PRESSED_TO_DISABLE: int = 3
const TIME_UNTIL_KEY_RESET: float = 1.0

var text_to_show: String = ""
var input_enabled: bool = false
var times_pressed: int = 0
var current_time_passed: float = 0

func _process(delta: float) -> void:
	if times_pressed > 0 and monitoring:
		if current_time_passed >= TIME_UNTIL_KEY_RESET:
			times_pressed = 0
			current_time_passed = 0
		else:
			current_time_passed += delta

func _input(event: InputEvent) -> void:
	if input_enabled:
		if event.is_action_pressed("player_walk") or event.is_action_pressed("ui_accept") or event is InputEventScreenTouch:
			times_pressed += 1
			if times_pressed >= TIMES_PRESSED_TO_DISABLE:
				disable()
				get_parent().start_boss_fight(true)

func enable(new_text: String) -> void:
	set_deferred("monitoring", true)
	score_panel_text.text = new_text

func disable() -> void:
	set_deferred("monitoring", false)
	score_panel.visible = false
	times_pressed = 0
	current_time_passed = 0

func _on_show_score_trigger_body_entered(body: PhysicsBody2D) -> void:
	if body.name == Globals.NodeNames.PLAYER:
		score_panel.visible = true
		input_enabled = true

func _on_show_score_trigger_body_exited(body: PhysicsBody2D) -> void:
	if body.name == Globals.NodeNames.PLAYER:
		score_panel.visible = false
		input_enabled = false
