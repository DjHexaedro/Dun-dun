# Currently not implemented, as I couldn't get it to work
extends Button


var remapping = false

func _input(event):
	if remapping and event is InputEventJoypadButton:
		text = event.as_text()
		remapping = false

func _on_button_pressed():
	remapping = true
	text = "Press the new key..."
