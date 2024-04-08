# Minion that shoots multiple bullets at once, in an arrow-shaped pattern
extends BaseMinion


var max_attack_speed: int
var attack_speed_difference: int = 0
var attack_speed_modifier: float = 0
var bullet_scale: Vector2 = Globals.BulletSizes.TRIPLE

# $attack_end_old.set_speed_scale(attack_speed + attack_speed_modifier)
# This line of code also emits the "animation_finished" signal. This var is
# used to fix a bug that originates from that
var has_shoot: bool = false
var vibrate: bool = false
var bullets_per_shot: int = 4


func spawn(params_dict: Dictionary) -> void:
	.spawn(params_dict)
	attack_speed_difference = max_attack_speed - params_dict.min_attack_speed

func despawn() -> void:
	.despawn()
	attack_cooldown_timer.stop()

func _process(_delta) -> void:
	if can_attack:
		has_shoot = false
		can_attack = false
		begin_attacking()

# I don't think this function is being used anymore, but I realized this almost
# the day the game was supposed to go live and I don't want to risk fucking it
# up, so it gets to stay until the next update
func _begin_attacking() -> void:
	attack_animation.visible = true
	spawn_animation.visible = false 
	if bullets_per_shot != 6:
		attack_speed_modifier = attack_speed_difference * clamp(EnemyManager.get_enemy_current_damage_taken() / damage_threshold, 0, 1)
	attack_animation.set_speed_scale(attack_speed + attack_speed_modifier)
	attack_animation.set_frame(0)
	attack_animation.play()

func attack() -> void:
	vibrate = true
	has_shoot = true
	var direction: Vector2 = get_bullet_direction(chosen_bullet_direction)
	var x_increment: int = 50
	var y_increment: int = -20 * direction.y
	var y_position: int
	var actual_x_increment: int
	var bullet_params: Dictionary = {
		"scale": bullet_scale,
		"velocity": bullet_speed * direction,
		"global_position": global_position,
		"z_index": 99,
	}
	SimpleBulletManager.shoot_bullet(Globals.SimpleBulletTypes.STRAIGHT, bullet_params)
	for i in range(1, bullets_per_shot):
		bullet_params.z_index -= 1
		y_position = global_position.y + (y_increment * i)
		actual_x_increment = x_increment * i
		bullet_params["global_position"] = Vector2(global_position.x + actual_x_increment, y_position)
		SimpleBulletManager.shoot_bullet(Globals.SimpleBulletTypes.STRAIGHT, bullet_params)
		bullet_params["global_position"] = Vector2(global_position.x - actual_x_increment, y_position)
		SimpleBulletManager.shoot_bullet(Globals.SimpleBulletTypes.STRAIGHT, bullet_params)
	attack_cooldown_timer.start()

func _on_attack_animation_animation_finished() -> void:
	attack_animation.visible = false 
	spawn_animation.visible = true

func _on_attack_cooldown_timer_timeout() -> void:
	if has_shoot:
		can_attack = true
		var random = randi()%5
		if random == 0:
			attack_animation.visible = true 
			spawn_animation.visible = false 
			attack_animation.set_frame(0)
			attack_animation.play()
	else:
		attack()
