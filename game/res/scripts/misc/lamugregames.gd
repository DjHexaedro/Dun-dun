# Functions used by the start-up logo. It isn't actually necessary as the game
# right now loads instantly, but I think it looks good. 
extends AnimatedSprite


signal splash_over


func _ready():
	yield(get_tree().create_timer(1, false), "timeout")
	$mugre.visible = true
	$mugre/bgm.play()

func _on_mugre_bgm_finished():
	$games.visible = true
	$games/bgm.play()

func _on_games_bgm_finished():
	$presents.visible = true
	$presents/bgm.play()

func _on_presents_bgm_finished():
	yield(get_tree().create_timer(1, false), "timeout")
	visible = false 
	yield(get_tree().create_timer(1, false), "timeout")
	emit_signal("splash_over")
