# Bullets the player shoots. They home in on the boss and never miss
extends BaseBullet

# How close the bullet has to be to the boss before it registers the hit
const ENEMY_DISTANCE_TO_HIT: int = 100
const TWEEN_DURATION: float = 0.6
const X_DEVIATION: int = 500
const Y_DEVIATION: int = 500

onready var starting_position_tween: Tween = $starting_position_tween

var enemy_position: Vector2
var chase_enemy: bool = false
var starting_position: Vector2
var starting_speed: int
var x_deviation: int
var y_deviation: int


func reset_bullet() -> void:
	chase_enemy = false
	enemy_position = EnemyManager.get_enemy_position()
	x_deviation = (randi()%X_DEVIATION) - X_DEVIATION/2
	y_deviation = (randi()%Y_DEVIATION) - Y_DEVIATION/2
	starting_position = Vector2(position.x + x_deviation, position.y + y_deviation)

func shoot(params_dict: Dictionary) -> void:
	.shoot(params_dict)
	reset_bullet()
	starting_position_tween.interpolate_property(self, "position", position, starting_position, TWEEN_DURATION, Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
	starting_position_tween.start()

func set_properties(params_dict: Dictionary) -> void:
	.set_properties(params_dict)
	set_bullet_variant(params_dict.bullet_variant)

func set_bullet_variant(bullet_variant: int) -> void:
	for i in range(5):
		get_node("graphics_v%s" % i).visible = true if i == bullet_variant else false

func _process(delta: float) -> void:
	if chase_enemy and EnemyManager.enemy_exists():
		direction = (enemy_position - position).normalized()
		velocity = direction * base_speed
		look_at(enemy_position)
		position.x += velocity.x * delta
		position.y += velocity.y * delta
		if enemy_position.distance_squared_to(get_global_position()) <= ENEMY_DISTANCE_TO_HIT:
			EnemyManager.damage_enemy(self)
			reset_bullet()
			ComplexBulletManager.remove_active_bullet(Globals.ComplexBulletTypes.POWERUP, get_instance_id())
	elif chase_enemy and not EnemyManager.enemy_exists():
		reset_bullet()
		ComplexBulletManager.remove_active_bullet(Globals.ComplexBulletTypes.POWERUP, get_instance_id())

func _on_starting_position_tween_all_completed() -> void:
	chase_enemy = true

func unload() -> void:
	reset_bullet()
