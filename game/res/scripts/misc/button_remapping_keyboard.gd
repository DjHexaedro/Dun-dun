# Used in the PC options menu to remap keyboard bindings 
extends Button


var remapping = false

func _input(event):
	if remapping and event is InputEventKey:
		text = event.as_text()
		remapping = false

func _on_button_pressed():
	remapping = true
	text = "Press the new key..."
