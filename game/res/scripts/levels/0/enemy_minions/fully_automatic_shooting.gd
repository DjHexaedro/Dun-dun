# Minion that shoots bullets one by one constantly
extends BaseMinion


const ATTACK_SPEED = 1
const ATTACK_DELAY = 1.25
const BASE_SPEED = 250
const Y_DEVIATION = 0.5

var bullet_scale: Vector2 = Globals.BulletSizes.STANDARD
var follow_player: bool = true
var currently_following_player: bool = false
var player_locked_on: bool = false
var current_speed: int
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var allow_movement: bool
var has_shoot: bool = false

func _ready() -> void:
	rng.randomize()

func spawn(params_dict: Dictionary) -> void:
	.spawn(params_dict)
	attack_speed = ATTACK_SPEED
	current_speed = BASE_SPEED

func despawn() -> void:
	.despawn()
	attack_cooldown_timer.stop()

func _process(_delta: float) -> void:
	if spawned:
		if PlayerManager.player_exists() and allow_movement:
			position.y = PlayerManager.get_player_position().y
		if can_attack:
			has_shoot = false
			can_attack = false
			bullet_speed = clamp(max_bullet_speed * (EnemyManager.get_enemy_current_damage_taken() / damage_threshold), min_bullet_speed, max_bullet_speed)
			attack()

func attack() -> void:
	var params_dict = {
		"global_position": global_position,
		"scale": bullet_scale,
		"velocity": get_bullet_direction(chosen_bullet_direction) * bullet_speed,
	}
	SimpleBulletManager.shoot_bullet(Globals.SimpleBulletTypes.STRAIGHT, params_dict)
	attack_cooldown_timer.start()

func get_bullet_direction(chosen_bullet_direction: String) -> Vector2:
	var base_direction = Globals.Directions[chosen_bullet_direction]
	return Vector2(base_direction.x, rng.randf_range(-Y_DEVIATION, Y_DEVIATION))

func _on_begin_moving_tween_tween_all_completed() -> void:
	currently_following_player = true
	can_attack = true

func _on_begin_attacking_timer_timeout() -> void:
	currently_following_player = false
	player_locked_on = false
	._on_begin_attacking_timer_timeout()

func _on_attack_end_animation_finished() -> void:
	currently_following_player = true

func _on_spawn_animation_animation_finished() -> void:
	._on_spawn_animation_animation_finished()
	currently_following_player = true

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
