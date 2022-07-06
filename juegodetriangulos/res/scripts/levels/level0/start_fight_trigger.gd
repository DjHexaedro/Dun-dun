# Trigger to start the fight with Ongard. Will probably be updated to work
# with all the other bosses as well
extends Area2D


func _ready() -> void:
	if (
		Settings.get_game_statistic("fighting_boss", false) and
		Settings.get_game_statistic("current_boss", -1) == 0
	):
		monitoring = false
		CameraManager.set_camera_target(ArenaManager.arena.get_path())
		EnemyManager.enemy._setup_enemy()

func _on_body_entered(body: KinematicBody2D) -> void:
	ArenaManager.close_arena()
	yield(ArenaManager, "doors_closed")
	CameraManager.set_camera_target(ArenaManager.arena.get_path())
	EnemyManager.enemy._setup_enemy()
	set_deferred("monitoring", false)
	Settings.save_game_statistic("fighting_boss", true)
	Settings.save_game_statistic("current_boss", 0)
	if PlayerManager.get_player_lamp_on():
		PlayerManager.player_emit_lamp_on_signal()
