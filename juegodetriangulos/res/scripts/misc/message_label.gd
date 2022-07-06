# Script used to show a message occupying the whole screen.
# Currently this is only done for the initial "turn your lamp on" message
extends CanvasLayer



func _ready():
	if Utils.device_is_phone():
		$message_label.text = "Touch the screen to turn your lamp on"


func _input(event):
	if $message_label.visible and (event.is_action_pressed("ui_accept") or event is InputEventScreenTouch):
		queue_free()
	if event.is_action_pressed("ui_cancel"):
		$message_label.visible = not $message_label.visible
