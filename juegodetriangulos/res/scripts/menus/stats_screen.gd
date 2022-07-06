# Functions used by the stats screen
extends CanvasLayer



func _ready():
	for child in get_tree().get_nodes_in_group(Globals.STATS_MENU_STATS_TO_LOAD_GROUP):
		child.set("text", str(Settings.get_game_statistic(child.get_name(), 0)))

func _on_exit_button_pressed():
	queue_free()
