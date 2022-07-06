# Base class for the area that contains the positions from which a powerup can
# spawn. Even though I named it "base", it will probably be the only type
# of this object I'll make
extends Area2D

class_name BasePowerupSpawningArea


var enabled: bool = true

func _check_if_player_entered(body: KinematicBody2D, disable: bool) -> void:
	if body and body.name == Globals.NodeNames.PLAYER:
		enabled = not disable

func _on_body_entered(body: KinematicBody2D) -> void:
	_check_if_player_entered(body, true)

func _on_body_exited(body: KinematicBody2D) -> void:
	_check_if_player_entered(body, false)
