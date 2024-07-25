# Helper class that creates and manages the state of all the simple bullets
# avaliable to the current boss when playing.
# Can be accessed from anywhere within the project
extends Node2D 

signal all_delayed_bullets_fired
signal all_bullets_despawned
signal bullets_despawned_by_type
signal bullets_despawned_by_type_list

const PLAYER_DISTANCE_TO_HIT: int = 5000
const BULLET_DIR_PATH: String = "res://juegodetriangulos/scenes/bullet/simple"
const BULLET_GRAPHICS_DICT: Dictionary = {
	"circular": "death_ball",
	"circular_zero": "zero",
	"delayed": "fireball",
	"delayed_circular": "death_ball",
	"soft_homing": "death_ball",
	"straight": "fireball",
	"straight_zero": "zero",
	"pawn": "pawn",
	"rook": "rook",
	"bishop": "bishop",
	"queen": "queen",
}
const SPAWN_BLINK_TIMES: int = 4
const PATTERN_FUNCTION_BASE_NAME: String = "%s_bullet_pattern"
const BULLET_STOPPED_INITIAL_WAIT_TIME: float = 0.5
const BULLET_STOPPED_BASE_WAIT_TIME: float = 0.05
const BULLET_STOPPED_BASE_WAIT_TIME_MODIFIER: float = 0.02
const DESPAWN_BLINK_TIMES: int = 14
const BULLET_DESPAWN_TIMER_TIMES: Array = [0.03, 0.12]

var idle_bullets: Dictionary = {}
var active_bullets: Dictionary = {}
var bullet_params: Dictionary = {}
var player_list: Array
var current_bullet: AnimatedSprite
var current_bullet_params: Dictionary
var delayed_bullet_stopped_list: Array = []
var bullet_despawn_timer: Timer = Timer.new()
var screen_center_position: Vector2 = Vector2(0, 0)
var oob_top: int
var oob_bottom: int
var oob_left: int
var oob_right: int
var last_instance_id
var check_collision: bool = true

func _ready() -> void:
	SimpleBulletMovementManager.connect("delayed_bullet_stopped", self, "_on_delayed_bullet_stopped")
	SimpleBulletMovementManager.connect("arena_center_reached", self, "_on_arena_center_reached")
	bullet_despawn_timer.set_one_shot(true)
	add_child(bullet_despawn_timer)

func _process(delta: float) -> void:
	if check_collision and len(active_bullets) and PlayerManager.player_exists():
		player_list = PlayerManager.get_player_list()

		for bullet_type in active_bullets:
			for bullet_id in active_bullets[bullet_type]:
				current_bullet = instance_from_id(bullet_id)
				current_bullet_params = bullet_params.get(bullet_id, {})
				if current_bullet_params:
					var player_hit_id: int = _bullet_hit_player(current_bullet)
					if current_bullet.visible and player_hit_id != -1:
						PlayerManager.damage_player(current_bullet, player_hit_id)
						if current_bullet_params.get("remove_bullet_on_hit", true):
							remove_active_bullet(bullet_type, bullet_id)
					else:
						SimpleBulletMovementManager.call(
							PATTERN_FUNCTION_BASE_NAME % bullet_type.to_lower(),
							current_bullet, bullet_params[bullet_id], delta * 2
						)
						if (
							clamp(
								current_bullet.get_global_position().y,
								oob_top, oob_bottom
							) in [oob_top, oob_bottom] or
							clamp(
								current_bullet.get_global_position().x,
								oob_left, oob_right
							) in [oob_left, oob_right]
						):
							remove_active_bullet(bullet_type, bullet_id)
	check_collision = not check_collision

func initializate_bullets(bullet_types_dict: Dictionary) -> void:
	var new_bullet: AnimatedSprite 
	var bullet_scene: PackedScene
	for bullet_type in bullet_types_dict:
		if not idle_bullets.get(bullet_type, false):
			idle_bullets[bullet_type] = []
		var n_of_bullets = clamp(
			bullet_types_dict[bullet_type] - len(idle_bullets[bullet_type]), 0, 10000
		)
		bullet_scene = load(
			"%s/%s.tscn" % [BULLET_DIR_PATH, BULLET_GRAPHICS_DICT.get(
				bullet_type.to_lower(), "death_ball"
			)]
		)
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

func despawn_active_bullets_by_type(bullet_type: String, blink_times: int = DESPAWN_BLINK_TIMES) -> void:
	var bullet_visible: bool = false 
	if active_bullets.get(bullet_type, false):
		for i in range(blink_times):
			var active_bullets_aux: Array = active_bullets[bullet_type].duplicate()
			for bullet_id in active_bullets_aux:
				instance_from_id(bullet_id).visible = bullet_visible 
				if (i + 1) >= blink_times:
					remove_active_bullet(bullet_type, bullet_id)
			bullet_visible = not bullet_visible
			bullet_despawn_timer.start(BULLET_DESPAWN_TIMER_TIMES[i % 2])
			yield(bullet_despawn_timer, "timeout")
	else:
		# Small hack so the signal isn't emitted right away and yields for
		# it work properly 
		bullet_despawn_timer.start(BULLET_DESPAWN_TIMER_TIMES[0])
		yield(bullet_despawn_timer, "timeout")
	emit_signal("bullets_despawned_by_type")

func despawn_active_bullets_by_type_list(bullet_type_list: Array, blink_times: int = DESPAWN_BLINK_TIMES) -> void:
	var bullet_visible: bool = false 
	for i in range(blink_times):
		for bullet_type in bullet_type_list:
			if active_bullets.get(bullet_type, false):
				var active_bullets_aux: Array = active_bullets[bullet_type].duplicate()
				for bullet_id in active_bullets_aux:
					instance_from_id(bullet_id).visible = bullet_visible 
					if (i + 1) >= blink_times:
						remove_active_bullet(bullet_type, bullet_id)
				bullet_visible = not bullet_visible
		bullet_despawn_timer.start(BULLET_DESPAWN_TIMER_TIMES[i % 2])
		yield(bullet_despawn_timer, "timeout")
	emit_signal("bullets_despawned_by_type_list")

func get_avaliable_bullet(bullet_type: String, params_dict: Dictionary) -> AnimatedSprite:
	var avaliable_bullet_id = idle_bullets[bullet_type].pop_front()
	if not avaliable_bullet_id:
		return null 
	if not active_bullets.get(bullet_type, false):
		active_bullets[bullet_type] = []
	bullet_params[avaliable_bullet_id] = params_dict.duplicate()
	var new_bullet: AnimatedSprite = instance_from_id(avaliable_bullet_id)
	set_bullet_params(new_bullet, params_dict)
	if BULLET_GRAPHICS_DICT[bullet_type] == "fireball":
		set_bullet_frame(new_bullet, params_dict.velocity)
	return new_bullet

func add_bullet_to_active_bullets(bullet_type: String, bullet_id: int) -> void:
	# If the player gets hit before the first bullet is fired,
	# active_bullets[bullet_type] will not exist. This fixes that
	if not active_bullets.get(bullet_type, false):
		active_bullets[bullet_type] = []
	if not bullet_id in active_bullets[bullet_type]:
		active_bullets[bullet_type].append(bullet_id)

func remove_all_active_bullets() -> void:
	var active_bullets_aux: Dictionary = active_bullets.duplicate(true)
	for bullet_type in active_bullets_aux:
		for bullet_id in active_bullets_aux[bullet_type]:
			remove_active_bullet(bullet_type, bullet_id)

func remove_active_bullet(bullet_type: String, bullet_id: int) -> void:
	var bullet: AnimatedSprite = instance_from_id(bullet_id)
	bullet.set_global_position(Globals.OUT_OF_BOUNDS_POSITION)
	bullet.set_rotation_degrees(0)
	bullet.set_visible(false)
	active_bullets[bullet_type].erase(bullet_id)
	idle_bullets[bullet_type].append(bullet_id)

func create_bullet(bulletscene: PackedScene) -> AnimatedSprite:
	var bullet = bulletscene.instance()
	if bullet:
		get_tree().get_root().add_child(bullet)
		bullet.set_position(Globals.OUT_OF_BOUNDS_POSITION)
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

func get_active_bullets_ids_by_type(bullet_type: String) -> Array:
	return active_bullets[bullet_type]

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

func shoot_bullet(bullet_type: String, params_dict: Dictionary) -> void:
	var new_bullet: AnimatedSprite = get_avaliable_bullet(bullet_type, params_dict)
	if new_bullet:
		new_bullet.visible = true

		add_bullet_to_active_bullets(bullet_type, new_bullet.get_instance_id())

func shoot_bullet_by_id(bullet_id: int, bullet_type: String) -> void:
	add_bullet_to_active_bullets(bullet_type, bullet_id)

func spawn_bullet(bullet_type: String, params_dict: Dictionary) -> void:
	var new_bullet: AnimatedSprite = get_avaliable_bullet(bullet_type, params_dict)
	if new_bullet:
		for _i in range(SPAWN_BLINK_TIMES):
			yield(get_tree().create_timer(BULLET_DESPAWN_TIMER_TIMES[1]), "timeout")
			new_bullet.visible = false
			yield(get_tree().create_timer(BULLET_DESPAWN_TIMER_TIMES[0]), "timeout")
			new_bullet.visible = true
		add_bullet_to_active_bullets(bullet_type, new_bullet.get_instance_id())

func update_screen_center_position() -> void:
	screen_center_position = CameraManager.get_camera_screen_center()
	oob_top = screen_center_position.y - 600
	oob_bottom = screen_center_position.y + 600
	oob_left = screen_center_position.x - 900
	oob_right = screen_center_position.x + 900

func update_bullet_params_dict(bullet_id: int, new_bullet_params: Dictionary) -> void:
	bullet_params[bullet_id].merge(new_bullet_params, true)

func _bullet_hit_player(bullet: AnimatedSprite) -> int:
	for player in player_list:
		if player.can_be_hit() and player.position.distance_squared_to(
			bullet.get_global_position()
		) <= PLAYER_DISTANCE_TO_HIT * bullet.scale.length_squared():
			return player.player_id
	return -1

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
