extends CanvasLayer


onready var text_label: RichTextLabel = $bg/text
onready var reminder_text_label: Label = $bg/skip_text_reminder

var TIME_UNTIL_NEXT_CHARACTER: float = 0.04
var current_time_passed: float = 0
var dialog_text_list: Array = []
var current_dialog_index: int = -1


func _ready() -> void:
	if Utils.device_is_phone():
		reminder_text_label.text = "Tap the screen to skip"
	_reset_text_label()

func _process(delta: float) -> void:
	if visible:
		if current_time_passed >= TIME_UNTIL_NEXT_CHARACTER:
			text_label.visible_characters += 1
			current_time_passed = 0
		else:
			current_time_passed += delta

func _input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("player_walk") or event.is_action_pressed("ui_accept") or event is InputEventScreenTouch:
			skip_text()

func hide_dialog_box() -> void:
	_reset_text_label()
	visible = false
	dialog_text_list = [] 
	current_time_passed = 0
	current_dialog_index = -1

func show_dialog_box(dialog_list: Array) -> void:
	visible = true
	dialog_text_list = dialog_list
	current_time_passed = 0
	current_dialog_index = -1
	show_next_dialog()

func skip_text() -> void:
	if text_label.visible_characters >= len(text_label.text):
		show_next_dialog()
	else:
		text_label.visible_characters = len(text_label.text)

func show_next_dialog() -> void:
	_reset_text_label()
	current_dialog_index += 1
	if current_dialog_index < len(dialog_text_list):
		text_label.text = dialog_text_list[current_dialog_index]
	else:
		hide_dialog_box()

func _reset_text_label() -> void:
	text_label.visible_characters = 0
	text_label.text = ""
