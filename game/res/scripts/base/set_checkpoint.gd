# Base script for setting the player's current checkpoint
extends Area2D 

class_name BaseSetCheckpoint

export (String) var CHECKPOINT_NAME 


func _on_body_entered(body: KinematicBody2D) -> void:
	if body and body.name == Globals.NodeNames.PLAYER:
		Settings.save_game_statistic("current_player_checkpoint", CHECKPOINT_NAME)
		ArenaManager.update_current_location(CHECKPOINT_NAME)
