# Bullet that disappears dividing itself into more dividing bullets
extends BaseBullet

onready var explosion_timer: Timer = $explosion_timer

const PLAYER_DISTANCE_TO_HIT: int = 750

var n_of_bullets_in_explosion: int
var minimum_size: Vector2
var screen_center_position: Vector2
var time_until_explosion: float
var player_position_list: Array

func shoot(params_dict: Dictionary) -> void:
	set_properties(params_dict)
	if look_at:
		look_at(global_position + velocity)
	explosion_timer.set_wait_time(time_until_explosion)
	explosion_timer.start()

func _process(delta: float) -> void:
	if velocity:
		player_position_list = []
		for player in PlayerManager.get_hittable_players():
			player_position_list.append(player.position)
		var player_hit_id: int = _bullet_hit_player()
		if player_hit_id != -1:
			PlayerManager.damage_player(self, player_hit_id)
			ComplexBulletManager.remove_active_bullet(
				Globals.ComplexBulletTypes.DIVIDING, get_instance_id()
			)
		global_position += velocity * delta

func _bullet_hit_player() -> int:
	for player_id in range(len(player_position_list)):
		if player_position_list[player_id].distance_squared_to(
			global_position
		) <= PLAYER_DISTANCE_TO_HIT * minimum_size.length_squared():
			return player_id
	return -1

func explode() -> void:
	var angle_to_screen_center: float = (screen_center_position - global_position).angle() - PI / 4
	if scale > minimum_size:
		var bullet_properties: Dictionary = {
			"global_position": global_position,
			"n_of_bullets_in_explosion": n_of_bullets_in_explosion,
			"scale": scale / 2,
			"minimum_size": minimum_size,
			"base_speed": base_speed * 2,
			"speed": base_speed * 2,
			"look_at": look_at,
			"time_until_explosion": time_until_explosion + 0.25,
			"screen_center_position": screen_center_position
		}
		BulletPatternManager.bullet_hell_semicircle(
			Globals.ComplexBulletTypes.DIVIDING,
			n_of_bullets_in_explosion,
			angle_to_screen_center,
			[bullet_properties],
			true
		)

	ComplexBulletManager.remove_active_bullet(
		Globals.ComplexBulletTypes.DIVIDING, get_instance_id()
	)

func _on_explosion_timer_timeout() -> void:
	explode()
