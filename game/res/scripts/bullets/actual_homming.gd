# Bullet that actually follows the player around for a short duration
extends BaseBullet

const PLAYER_DISTANCE_TO_HIT: int = 750
const VIBRATE_DURATION: int = 180

onready var sprite_label: Label = $label
onready var follow_timer: Timer = $follow_timer
onready var spawn_timer: Timer = $spawn_timer
onready var explosion_timer: Timer = $explosion_timer

var follow_time: float
var spawn_time: float
var n_of_bullets_in_explosion: int
var spawned_bullet_params: Dictionary
var spawned_bullet_list: Array = []
var follow_player: bool = false
var burst_delay: float = 0.5
var max_bursts: int
var explosion_bullets_speed: int
var player_position_list: Array
var vibrate: bool = false
var vibrated_for: int = 0
var initial_position_offset: Vector2
var followed_player_id: int = -1

func _ready() -> void:
	initial_position_offset = sprite_label.rect_position

func _process(delta: float) -> void:
	if follow_player:
		look_at(global_position + velocity)
		direction = (PlayerManager.get_player_old_position(followed_player_id) - global_position).normalized()
		global_position += base_speed * direction * delta
		player_position_list = []
		for player in PlayerManager.get_hittable_players():
			player_position_list.append(player.position)
		var player_hit_id: int = _bullet_hit_player()
		if player_hit_id != -1:
			PlayerManager.damage_player(self, player_hit_id)
		global_position += velocity * delta
	elif vibrate:
		if vibrated_for < VIBRATE_DURATION:
			sprite_label.rect_position =\
					initial_position_offset + Vector2(randi()%10 - 5, randi()%10 - 5)
			vibrated_for += 1
		else:
			vibrate = false
			sprite_label.rect_position = initial_position_offset
			vibrated_for = 0
			explode()

func _bullet_hit_player() -> int:
	for player_id in range(len(player_position_list)):
		if player_position_list[player_id].distance_squared_to(
			global_position
		) <= PLAYER_DISTANCE_TO_HIT * scale.length_squared():
			return player_id
	return -1

func shoot(params_dict: Dictionary) -> void:
	set_properties(params_dict)
	follow_player = true
	spawned_bullet_list = []
	spawn_timer.set_wait_time(spawn_time)
	spawn_timer.set_one_shot(false)
	follow_timer.set_wait_time(follow_time)
	follow_timer.start()
	spawn_timer.start()

func vibrate() -> void:
	vibrate = true

func explode() -> void:
	var current_burst: int = 0
	var params_dict: Dictionary = {
		"global_position": global_position,
		"scale": Globals.BulletSizes.STANDARD,
		"speed": explosion_bullets_speed,
	}

	while current_burst < max_bursts:
		BulletPatternManager.bullet_hell_circle(
			Globals.SimpleBulletTypes.STRAIGHT_ZERO,
			n_of_bullets_in_explosion,
			[params_dict]
		)
		current_burst += 1
		if burst_delay:
			yield(get_tree().create_timer(burst_delay), "timeout")

	remove_from_active_bullets()

func _on_follow_timer_timeout():
	spawn_timer.stop()
	follow_player = false
	vibrate()
	for spawned_bullet in spawned_bullet_list:
		yield(get_tree().create_timer(burst_delay), "timeout")
		spawned_bullet.vibrate()

func _on_spawn_timer_timeout():
	spawned_bullet_params.global_position = global_position
	spawned_bullet_list.push_front(ComplexBulletManager.shoot_bullet(
		spawned_bullet_params.bullet_type, spawned_bullet_params
	))
