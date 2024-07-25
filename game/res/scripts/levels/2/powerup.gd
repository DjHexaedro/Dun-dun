extends BasePowerup

signal correct_powerup_grabbed(value)
signal incorrect_powerup_grabbed(value)
signal finished_shooting()

onready var value_label: Label = $value

const FLOAT_MAX_HEIGHT: int = -10
const FLOAT_MIN_HEIGHT: int = 0
const FLOAT_INCREMENT: int = 10

var value: int = -1
var correct_value: int = -2
var float_direction: int = 1
var powerup_id: int = -1

func set_enabled(new_enabled: bool) -> void:
	enabled = new_enabled
	cracking_animation.visible = new_enabled 
	cracking_animation.set_frame(0)
	cracking_animation.offset.y = FLOAT_MIN_HEIGHT
	break_animation.set_frame(0)
	break_animation.visible = not new_enabled 
	is_shooting = false
	float_direction = 1

func _ready() -> void:
	n_of_bullets = 5
	allowed_player_id = 0

func _process(delta: float) -> void:
	if value != -1 and enabled and visible:
		if not is_shooting:
			if global_position.distance_squared_to(
				PlayerManager.get_player_position(allowed_player_id)
			) < player_pickup_distance:
				_on_powerup_grabbed()
			cracking_animation.offset.y += FLOAT_INCREMENT * float_direction * delta 
			cracking_animation.offset.y = clamp(
				cracking_animation.offset.y, FLOAT_MAX_HEIGHT, FLOAT_MIN_HEIGHT
			)
			if cracking_animation.offset.y in [FLOAT_MIN_HEIGHT, FLOAT_MAX_HEIGHT]:
				float_direction *= -1

func reset_powerup() -> void:
	pass

func respawn() -> void:
	show()
	cracking_animation.visible = false
	if enabled:
		enabled = false
		spawn_animation.visible = true
		spawn_animation.set_frame(0)
		spawn_animation.play()

func break_powerup(forced: bool = false) -> void:
	set_enabled(false)
	cracking_animation.hide()
	break_animation.show()
	break_animation.play()
	break_sound_audio.play()
	if not forced:
		PowerupManager.reset_perfect_powerups_combo()

func shoot() -> void:
	is_shooting = true
	var params_dict: Dictionary = {
		"base_speed": bullet_speed,
		"scale": Vector2(1, 1),
		"damage": BASE_DAMAGE,
		"direction": (EnemyManager.get_enemy_position() - position).normalized(),
		"uses_shader": false,
	}
	var bullet_positions: Array = [
		global_position,
		global_position + Vector2(-24, 9),
		global_position + Vector2(20, 10),
		global_position + Vector2(-11, -5),
		global_position + Vector2(-3, -8),
	]
	for c in range(n_of_bullets, 0, -1):
		params_dict["bullet_variant"] = c - 1
		params_dict["global_position"] = bullet_positions[c - 1]
		shoot_audio.pitch_scale = 1.0 + 0.15 * (n_of_bullets - c)
		shoot_audio.play()
		ComplexBulletManager.shoot_bullet(
			Globals.ComplexBulletTypes.POWERUP, params_dict
		)
		if c > 1:
			cracking_animation.set_frame(c - 2)
			delay_between_bullets_timer.start()
			yield(delay_between_bullets_timer, "timeout")
		else:
			cracking_animation.hide()
	visible = false
	emit_signal("finished_shooting")

func set_powerup_value(
	new_value: int, new_correct_value: int,
	player_id: int = Globals.PlayerIDs.PLAYER_ONE
) -> void:
	visible = true
	value_label.text = str(new_value)
	allowed_player_id = player_id

	if allowed_player_id != Globals.PlayerIDs.PLAYER_ONE:
		material = invert_shader
	else:
		material = null

	break_animation.visible = false 
	spawn_animation.visible = true 
	spawn_animation.set_frame(0)
	spawn_animation.play()
	yield(spawn_animation, "animation_finished")
	value = new_value
	correct_value = new_correct_value

func _on_powerup_grabbed() -> void:
	cracking_animation.set_frame(1)
	if enabled:
		if value != correct_value:
			break_powerup()
			emit_signal("incorrect_powerup_grabbed", powerup_id)
		else:
			emit_signal("correct_powerup_grabbed", powerup_id)
			shoot()
			GameStateManager.update_match_history(
				Globals.MatchEvents.CRYSTAL_GRABBED,
				n_of_bullets
			)
			Settings.increase_game_statistic("crystals_collected", 1)
		
func _on_spawn_animation_finished() -> void:
	spawn_animation.visible = false
	cracking_animation.visible = true
	set_enabled(true)

func _on_break_animation_finished() -> void:
	pass
