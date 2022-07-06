# Script used by the game to show the last score gotten by the player
extends CanvasLayer


func _ready():
	$movement_tween.interpolate_property($score_label, "rect_position", $score_label.rect_position, $score_label.rect_position + Vector2(0, -20), 2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$movement_tween.start()

func _on_movement_tween_tween_all_completed():
	queue_free()
