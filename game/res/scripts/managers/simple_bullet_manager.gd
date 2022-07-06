# Helper class that creates and manages the state of all the simple bullets
# avaliable to the current boss when playing.
# Can be accessed from anywhere within the project
extends Node2D 

signal all_delayed_bullets_fired
signal all_bullets_despawned
signal bullets_despawned_by_type

const OOB_TOP: int = -100
const OOB_BOTTOM: int = 1200
const OOB_LEFT: int = -100
const OOB_RIGHT: int = 2000
const PLAYER_DISTANCE_TO_HIT: int = 5000
const BULLET_DIR_PATH: String = "res://juegodetriangulos/scenes/bullet/simple"
const BULLET_GRAPHICS_DICT: Dictionary = {
	"circular": "death_ball",
	"delayed": "fireball",
	"delayed_circular": "death_ball",
	"soft_homing": "death_ball",
	"straight": "fireball",
	"health": "health_refill",
}
const SPAWN_BLINK_TIMES: int = 4
const PATTERN_FUNCTION_BASE_NAME: String = "%s_bullet_pattern"
const BULLET_STOPPED_INITIAL_WAIT_TIME: float = 0.5
const BULLET_STOPPED_BASE_WAIT_TIME: float = 0.05
const BULLET_STOPPED_BASE_WAIT_TIME_MODIFIER: float = 0.02
const HEALTH_REFILL_TIMER_BASE_TIME: float = 30.0
const HEALTH_REFILL_TIMER_ON_HEALTH_PICKUP_TIME: float = 45.0
const HEALTH_REFILL_TIMER_INCREMENT: float = 10.0
const HEALTH_REFILL_TIMER_MAX_TIME: float = 90.0
const DESPAWN_BLINK_TIMES: int = 14

var idle_bullets: Dictionary = {}
var active_bullets: Dictionary = {}
var bullet_params: Dictionary = {}
var player_position: Vector2
var current_bullet: AnimatedSprite
var delayed_bullet_stopped_list: Array = []
var health_refill_spawned_audio: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
var health_refill_enabled: bool = true
var health_refill_timer: Timer = Timer.new()
var health_refill_times_missed: int = -1
var bullet_despawn_timer: Timer = Timer.new()
var health_refill_audio_list: Array = [
	load("res://juegodetriangulos/res/music/shoot_health_sfx0.wav"),
	load("res://juegodetriangulos/res/music/shoot_health_sfx1.wav"),
]

func _ready() -> void:
	SimpleBulletMovementManager.connect("delayed_bullet_stopped", self, "_on_delayed_bullet_stopped")
	SimpleBulletMovementManager.connect("arena_center_reached", self, "_on_arena_center_reached")
	bullet_despawn_timer.set_one_shot(true)
	add_child(bullet_despawn_timer)
	health_refill_timer.set_one_shot(true)
	health_refill_timer.connect("timeout", self, "_on_health_refill_timer_timeout")
	add_child(health_refill_timer)
	health_refill_spawned_audio.set_bus("Effects")
	add_child(health_refill_spawned_audio)

func _process(delta: float) -> void:
	if PlayerManager.player_exists():
		for bullet_type in active_bullets:
			for bullet_id in active_bullets[bullet_type]:
				player_position = PlayerManager.get_player_position()
				current_bullet = instance_from_id(bullet_id)
				var heals_player: bool = bullet_params[bullet_id].get("heals_player", false)
				if current_bullet.visible and player_position.distance_squared_to(current_bullet.get_global_position()) <= (PLAYER_DISTANCE_TO_HIT * current_bullet.scale.length_squared() * (2 if heals_player else 1)):
					if heals_player:
						PlayerManager.heal_player()
						health_refill_times_missed = -1
					else:
						PlayerManager.damage_player(current_bullet)
					remove_active_bullet(bullet_type, bullet_id, heals_player)
				else:
					SimpleBulletMovementManager.call(PATTERN_FUNCTION_BASE_NAME % bullet_type.to_lower(), current_bullet, bullet_params[bullet_id], delta)
					if (
						clamp(current_bullet.get_global_position().y, OOB_TOP, OOB_BOTTOM) in [OOB_TOP, OOB_BOTTOM]
						or
						clamp(current_bullet.get_global_position().x, OOB_LEFT, OOB_RIGHT) in [OOB_LEFT, OOB_RIGHT]
					):
						remove_active_bullet(bullet_type, bullet_id, heals_player)

func initializate_bullets(bullet_types_dict: Dictionary) -> void:
	var new_bullet: AnimatedSprite 
	var bullet_scene: PackedScene
	for bullet_type in bullet_types_dict:
		if not idle_bullets.get(bullet_type, false):
			idle_bullets[bullet_type] = []
		var n_of_bullets = clamp(bullet_types_dict[bullet_type] - len(idle_bullets[bullet_type]), 0, 10000)
		bullet_scene = load("%s/%s.tscn" % [BULLET_DIR_PATH, BULLET_GRAPHICS_DICT.get(bullet_type.to_lower(), "death_ball")])
		for _i in range(n_of_bullets):
			new_bullet = create_bullet(bullet_scene)
			idle_bullets[bullet_type].append(new_bullet.get_instance_id())

func clear_all_bullets() -> void:
	for bullet_type in idle_bullets:
		for bullet_id in idle_bullets[bullet_type]:
			instance_from_id(bullet_id).queue_free()
		if active_bullets.get(bullet_type, false):
			for bullet_id in active_bullets[bullet_type]:
				instance_from_id(bullet_id).queue_free()
	active_bullets = {}
	idle_bullets = {}

func clear_active_bullets() -> void:
	for bullet_type in active_bullets:
		for bullet_id in active_bullets[bullet_type]:
			instance_from_id(bullet_id).queue_free()
	active_bullets = {}

func clear_idle_bullets() -> void:
	for bullet_type in idle_bullets:
		for bullet_id in idle_bullets[bullet_type]:
			instance_from_id(bullet_id).queue_free()
	idle_bullets = {}

func despawn_active_bullets() -> void:
	for bullet_type in active_bullets:
		despawn_active_bullets_by_type(bullet_type)
	for _i in range(len(active_bullets)):
		yield(self, "bullets_despawned_by_type")
	emit_signal("all_bullets_despawned")

func despawn_active_bullets_by_type(bullet_type: String) -> void:
	var bullet_visible: bool = false 
	var bullet_despawn_timer_times: Array = [0.03, 0.12]
	for i in range(DESPAWN_BLINK_TIMES):
		for bullet_id in active_bullets[bullet_type]:
			if not bullet_params[bullet_id].get("heals_player", false):
				instance_from_id(bullet_id).visible = bullet_visible 
				if (i + 1) == DESPAWN_BLINK_TIMES:
					remove_active_bullet(bullet_type, bullet_id)
		bullet_visible = not bullet_visible
		bullet_despawn_timer.start(bullet_despawn_timer_times[i % 2])
		yield(bullet_despawn_timer, "timeout")
	emit_signal("bullets_despawned_by_type")


func get_avaliable_bullet(bullet_type: String, params_dict: Dictionary, can_be_health: bool = false) -> AnimatedSprite:
	if can_be_health and _bullet_is_health():
		bullet_type = Globals.SimpleBulletTypes.HEALTH
		params_dict["scale_increment"] = Vector2(-0.25, -0.25)
		health_refill_enabled = false
		health_refill_spawned_audio.stream = health_refill_audio_list[randi()%2]
		health_refill_spawned_audio.global_position = params_dict.global_position
		health_refill_spawned_audio.play()
	var avaliable_bullet_id = idle_bullets[bullet_type].pop_back()
	if not avaliable_bullet_id:
		return null 
	if not active_bullets.get(bullet_type, false):
		active_bullets[bullet_type] = []
	var new_bullet: AnimatedSprite = instance_from_id(avaliable_bullet_id)
	bullet_params[avaliable_bullet_id] = params_dict.duplicate()
	if bullet_type == Globals.SimpleBulletTypes.HEALTH:
		bullet_params[avaliable_bullet_id]["heals_player"] = true
	set_bullet_params(new_bullet, params_dict)
	if BULLET_GRAPHICS_DICT[bullet_type] == "fireball":
		set_bullet_frame(new_bullet, params_dict.velocity)
	return new_bullet

func remove_all_active_bullets() -> void:
	var active_bullets_aux: Dictionary = active_bullets.duplicate(true)
	for bullet_type in active_bullets_aux:
		for bullet_id in active_bullets_aux[bullet_type]:
			remove_active_bullet(bullet_type, bullet_id, bullet_params[bullet_id].get("heals_player", false))

func remove_active_bullet(bullet_type: String, bullet_id: int, heals_player: bool = false) -> void:
	var bullet: AnimatedSprite = instance_from_id(bullet_id)
	bullet.set_global_position(Globals.Positions.OUT_OF_BOUNDS)
	bullet.set_rotation_degrees(0)
	bullet.set_visible(false)
	bullet_params.erase(bullet_id)
	active_bullets[bullet_type].erase(bullet_id)
	if heals_player:
		instance_from_id(bullet_id).graphics.scale = Vector2(1, 1)
		idle_bullets[Globals.SimpleBulletTypes.HEALTH].append(bullet_id)
		if health_refill_times_missed == -1:
			health_refill_timer.start(HEALTH_REFILL_TIMER_ON_HEALTH_PICKUP_TIME)
		else:
			health_refill_timer.start(clamp(
				HEALTH_REFILL_TIMER_BASE_TIME + (HEALTH_REFILL_TIMER_INCREMENT * health_refill_times_missed),
				HEALTH_REFILL_TIMER_BASE_TIME,
				HEALTH_REFILL_TIMER_MAX_TIME
			))
		health_refill_times_missed += 1
	else:
		idle_bullets[bullet_type].append(bullet_id)

func create_bullet(bulletscene: PackedScene) -> AnimatedSprite:
	var bullet = bulletscene.instance()
	if bullet:
		get_tree().get_root().add_child(bullet)
		bullet.set_position(Globals.Positions.OUT_OF_BOUNDS)
	return bullet

func set_bullet_frame(bullet: AnimatedSprite, velocity: Vector2) -> void:
	var initial_rotation_degrees: float = bullet.rotation_degrees
	bullet.look_at(bullet.global_position + velocity)
	var frame: int = int(bullet.rotation_degrees / 5)
	var frame_index: int
	bullet.flip_v = false 
	bullet.flip_h = false
	if frame > 0:
		frame_index = frame - 1
		if frame > 18:
			bullet.flip_h = true
			frame_index = clamp(17 - (frame - 18), 0, 17)
	elif frame < 0:
		bullet.flip_v = true
		frame *= -1
		frame_index = frame - 1
		if frame > 18:
			bullet.flip_h = true
			frame_index = clamp(17 - (frame - 18), 0, 17)
	else:
		frame_index = 0
	bullet.set_frame(frame_index)
	bullet.rotation_degrees = initial_rotation_degrees

func set_bullet_params(bullet: AnimatedSprite, params_dict: Dictionary) -> void:
	for key in params_dict:
		bullet.set(key, params_dict[key])
	bullet.visible = true

func change_bullet_param(bullet_id: int, param_name: String, new_param_value) -> void:
	bullet_params[bullet_id][param_name] = new_param_value

func change_bullet_type_param(bullet_type: String, param_name: String, new_param_value) -> void:
	for bullet_id in active_bullets[bullet_type]:
		change_bullet_param(bullet_id, param_name, new_param_value)

func change_circular_bullet_rotation_direction() -> void:
	for bullet_id in active_bullets[Globals.SimpleBulletTypes.CIRCULAR]:
		change_bullet_param(bullet_id, "rotation_direction", bullet_params[bullet_id]["rotation_direction"] * -1)

func shoot_bullet(bullet_type: String, params_dict: Dictionary, can_be_health: bool = true) -> void:
	var new_bullet: AnimatedSprite = get_avaliable_bullet(bullet_type, params_dict, can_be_health)
	if new_bullet:
		# If the player gets hit before the first bullet is fired,
		# active_bullets[bullet_type] will not exist. This fixes that
		if not active_bullets.get(bullet_type, false):
			active_bullets[bullet_type] = []
		active_bullets[bullet_type].append(new_bullet.get_instance_id())

func shoot_bullet_by_id(bullet_id: int, bullet_type: String) -> void:
	# If the player gets hit before the first bullet is fired,
	# active_bullets[bullet_type] will not exist. This fixes that
	if not active_bullets.get(bullet_type, false):
		active_bullets[bullet_type] = []
	active_bullets[bullet_type].append(bullet_id)

func spawn_bullet(bullet_type: String, params_dict: Dictionary, can_be_health: bool = true) -> void:
	var new_bullet: AnimatedSprite = get_avaliable_bullet(bullet_type, params_dict, can_be_health)
	if new_bullet:
		for _i in range(SPAWN_BLINK_TIMES):
			yield(get_tree().create_timer(0.12), "timeout")
			new_bullet.visible = false
			yield(get_tree().create_timer(0.03), "timeout")
			new_bullet.visible = true
		# If the player gets hit before the first bullet is fired,
		# active_bullets[bullet_type] will not exist. This fixes that
		if not active_bullets.get(bullet_type, false):
			active_bullets[bullet_type] = []
		active_bullets[bullet_type].append(new_bullet.get_instance_id())

func _bullet_is_health() -> bool:
	return (
		health_refill_enabled and
		len(idle_bullets[Globals.SimpleBulletTypes.HEALTH]) and
		PlayerManager.get_player_health() < PlayerManager.get_player_max_health() and
		randi() % 100 >= 60
	)

func _reenable_health_refill() -> void:
	health_refill_enabled = true
	health_refill_timer.stop()

func _on_health_refill_timer_timeout() -> void:
	health_refill_enabled = true

func _on_delayed_bullet_stopped(bullet_id: int) -> void:
	delayed_bullet_stopped_list.append(bullet_id)
	bullet_params[bullet_id]["can_emit_signal"] = false
	if len(delayed_bullet_stopped_list) >= len(active_bullets[Globals.SimpleBulletTypes.DELAYED]):
		var time_until_next_attack = Timer.new() 
		time_until_next_attack.set_wait_time(BULLET_STOPPED_INITIAL_WAIT_TIME)
		time_until_next_attack.set_one_shot(true)
		self.add_child(time_until_next_attack)
		time_until_next_attack.start()
		yield(time_until_next_attack, "timeout")
		var wait_time_until_next_attack = BULLET_STOPPED_BASE_WAIT_TIME - (BULLET_STOPPED_BASE_WAIT_TIME_MODIFIER * clamp(EnemyManager.get_enemy_current_damage_taken() / 500, 0, 1))
		time_until_next_attack.set_wait_time(wait_time_until_next_attack)
		delayed_bullet_stopped_list.shuffle()
		for current_bullet_id in delayed_bullet_stopped_list:
			bullet_params[current_bullet_id].velocity *= 1.25
			bullet_params[current_bullet_id]["continue_moving"] = true
			time_until_next_attack.start()
			yield(time_until_next_attack, "timeout")
		delayed_bullet_stopped_list = []
		emit_signal("all_delayed_bullets_fired")

func _on_arena_center_reached() -> void:
	if EnemyManager.get_enemy().check_hard_constant_fire_circle_next_stage():
		change_bullet_type_param(Globals.SimpleBulletTypes.DELAYED_CIRCULAR, "can_emit_signal", false)
