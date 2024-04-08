# Base script for triggering boss fights. It also updates the
# player's current checkpoint
extends BaseSetCheckpoint 

class_name BaseStartFight

export (int) var ENEMY_ID
export (int) var ARENA_ID

var parent_node: Node2D
var start_fight: bool = true

func _ready():
	parent_node = get_parent()
	if Settings.get_game_statistic("current_boss", -1) == ENEMY_ID:
		EnemyManager.setup_enemy("level%s" % ENEMY_ID)
	if Settings.get_game_statistic("level%s_enemy_defeated" % ENEMY_ID, false):
		start_fight = false

func _on_body_entered(body: KinematicBody2D) -> void:
	._on_body_entered(body)
#	if start_fight and (body and body.name == Globals.NodeNames.PLAYER):
#		parent_node.start_boss_fight()
#		start_fight = false
#		if (
#			not Settings.get_game_statistic("level%s_enemy_defeated" % ENEMY_ID, false)
#			and not Settings.get_game_statistic("fighting_boss", false)
#		):
#			parent_node.start_boss_fight()
#			start_fight = false
