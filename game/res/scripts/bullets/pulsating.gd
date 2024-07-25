# Bullet that shoots rings of other bullets.
extends BasePulsating

func _ready() -> void:
	bullet_types_list = [
		Globals.SimpleBulletTypes.STRAIGHT, Globals.SimpleBulletTypes.CIRCULAR
	]
	current_shooting_bullet_type = bullet_types_list[0]
