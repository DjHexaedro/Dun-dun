# Bullet that shoots rings of other bullets (zero version).
extends BasePulsating

const VIBRATE_DURATION: int = 180
const PLAYER_DISTANCE_TO_HIT: int = 750

onready var sprite_label: Label = $label

var vibrate: bool = false
var vibrated_for: int = 0
var initial_position_offset: Vector2
var player_position_list: Array

func _ready() -> void:
	bullet_types_list = [
		Globals.SimpleBulletTypes.STRAIGHT_ZERO,
		Globals.SimpleBulletTypes.CIRCULAR_ZERO,
	]
	current_shooting_bullet_type = bullet_types_list[0]
	initial_position_offset = sprite_label.rect_position

func _process(delta: float) -> void:
	player_position_list = []
	for player in PlayerManager.get_hittable_players():
		player_position_list.append(player.position)
	var player_hit_id: int = _bullet_hit_player()
	if player_hit_id != -1:
		PlayerManager.damage_player(self, player_hit_id)
		remove_from_active_bullets()
	else:
		global_position += velocity * delta
		if vibrate:
			if vibrated_for < VIBRATE_DURATION:
				sprite_label.rect_position =\
						initial_position_offset + Vector2(randi()%20 - 10, randi()%20 - 10)
				vibrated_for += 1
			else:
				sprite_label.rect_position = initial_position_offset
				vibrate = false
				vibrated_for = 0
				explode()

func _bullet_hit_player() -> int:
	for player_id in range(len(player_position_list)):
		if player_position_list[player_id].distance_squared_to(
			global_position
		) <= PLAYER_DISTANCE_TO_HIT * scale.length_squared():
			return player_id
	return -1

func vibrate() -> void:
	vibrate = true
