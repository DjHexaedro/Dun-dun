# Used in the PC options menu to remap keyboard bindings 
extends Button

var remapping: bool = false

func _input(event: InputEvent) -> void:
	if remapping and event is InputEventKey:
		text = event.as_text()
		remapping = false

func _on_button_pressed() -> void:
	remapping = true
	text = "Press the new key..."
