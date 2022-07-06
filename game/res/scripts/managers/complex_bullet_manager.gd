# Helper class that creates and manages the state of all the complex bullets
# avaliable to the current boss when playing.
# Can be accessed from anywhere within the project
extends Node2D 


signal all_bullets_despawned
signal bullets_despawned_by_type

const BULLET_DIR_PATH: String = "res://juegodetriangulos/scenes/bullet/complex"
const DESPAWN_BLINK_TIMES: int = 14

var idle_bullets: Dictionary = {}
var active_bullets: Dictionary = {}
var bullet_despawn_timer: Timer = Timer.new()

func _ready() -> void:
	bullet_despawn_timer.set_one_shot(true)
	add_child(bullet_despawn_timer)

func initializate_bullets(bullet_types_dict: Dictionary) -> void:
	var new_bullet: AnimatedSprite
	var bullet_scene: PackedScene
	for bullet_type in bullet_types_dict:
		if not idle_bullets.get(bullet_type, false):
			idle_bullets[bullet_type] = []
		var n_of_bullets = clamp(bullet_types_dict[bullet_type] - len(idle_bullets[bullet_type]), 0, 20)
		bullet_scene = load("%s/%s.tscn" % [BULLET_DIR_PATH, bullet_type.to_lower()])
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
			instance_from_id(bullet_id).visible = bullet_visible 
			if (i + 1) == DESPAWN_BLINK_TIMES:
				remove_active_bullet(bullet_type, bullet_id)
		bullet_visible = not bullet_visible
		bullet_despawn_timer.start(bullet_despawn_timer_times[i % 2])
		yield(bullet_despawn_timer, "timeout")
	emit_signal("bullets_despawned_by_type")

func get_avaliable_bullet(bullet_type: String):
	var avaliable_bullet_id = idle_bullets[bullet_type].pop_back()
	if not active_bullets.get(bullet_type, false):
		active_bullets[bullet_type] = []
	active_bullets[bullet_type].append(avaliable_bullet_id)
	return instance_from_id(avaliable_bullet_id)

func remove_all_active_bullets() -> void:
	var active_bullets_aux: Dictionary = active_bullets.duplicate(true)
	for bullet_type in active_bullets_aux:
		for bullet_id in active_bullets_aux[bullet_type]:
			remove_active_bullet(bullet_type, bullet_id)

func remove_active_bullet(bullet_type: String, bullet_id: int) -> void:
	var bullet = instance_from_id(bullet_id)
	bullet.set_global_position(Globals.Positions.OUT_OF_BOUNDS)
	bullet.unload()
	active_bullets[bullet_type].erase(bullet_id)
	idle_bullets[bullet_type].append(bullet_id)

func create_bullet(bulletscene: PackedScene) -> AnimatedSprite:
	var bullet = bulletscene.instance()
	get_tree().get_root().add_child(bullet)
	bullet.set_position(Globals.Positions.OUT_OF_BOUNDS)
	return bullet

func shoot_bullet(bullet_type: String, params_dict: Dictionary) -> AnimatedSprite:
	var new_bullet = get_avaliable_bullet(bullet_type)
	new_bullet.shoot(params_dict)
	return new_bullet

func spawn_bullet(bullet_type: String, params_dict: Dictionary) -> void:
	var new_bullet = get_avaliable_bullet(bullet_type)
	new_bullet.spawn(params_dict)
