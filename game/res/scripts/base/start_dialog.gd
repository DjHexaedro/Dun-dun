# Base class to initiate dialogs with an NPC
extends Area2D

class_name BaseStartDialog 


var dialog_text_list: Array = []


func _on_body_entered(body):
	Utils.show_dialog_box(dialog_text_list)

func _on_body_exited(body):
	if not Utils.is_dialog_box_visible():
		_update_dialog_previous_finished()
	else:
		_update_dialog_previous_unfinished()
		Utils.hide_dialog_box()

func _update_dialog_previous_finished() -> void:
		pass

func _update_dialog_previous_unfinished() -> void:
		pass
