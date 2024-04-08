# Bullets the player shoots. They home in on the boss and never miss
extends BaseBullet

onready var invert_shader: ShaderMaterial = preload("res://juegodetriangulos/res/shaders/invert.tres")

# How close the bullet has to be to the boss before it registers the hit
const ENEMY_DISTANCE_TO_HIT: int = 100

var enemy_position: Vector2
var starting_position: Vector2
var starting_speed: int
var chase_enemy: bool

func _ready() -> void:
	look_at = false

func reset_bullet() -> void:
	enemy_position = EnemyManager.get_enemy_position()

func shoot(params_dict: Dictionary) -> void:
	.shoot(params_dict)
	chase_enemy = true
	reset_bullet()

func set_properties(params_dict: Dictionary) -> void:
	.set_properties(params_dict)
	set_bullet_variant(params_dict.bullet_variant, params_dict.uses_shader)

func set_bullet_variant(bullet_variant: int, uses_shader: bool) -> void:
	for i in range(5):
		get_node("graphics_v%s" % i).visible = true if i == bullet_variant else false
		material = invert_shader if uses_shader else null

func _process(delta: float) -> void:
	if chase_enemy and EnemyManager.enemy_exists():
		direction = (enemy_position - position).normalized()
		velocity = direction * base_speed
		position.x += velocity.x * delta
		position.y += velocity.y * delta
		if enemy_position.distance_squared_to(get_global_position()) <= ENEMY_DISTANCE_TO_HIT:
			EnemyManager.damage_enemy(self)
			chase_enemy = false 
			reset_bullet()
			ComplexBulletManager.remove_active_bullet(Globals.ComplexBulletTypes.POWERUP, get_instance_id())
	elif chase_enemy and not EnemyManager.enemy_exists():
		reset_bullet()
		chase_enemy = false 
		ComplexBulletManager.remove_active_bullet(Globals.ComplexBulletTypes.POWERUP, get_instance_id())

func unload() -> void:
	reset_bullet()
