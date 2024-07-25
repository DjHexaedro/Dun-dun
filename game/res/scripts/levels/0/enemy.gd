extends "res://juegodetriangulos/res/scripts/levels/0/extreme_attacks.gd"

const BULLET_STOPPED_INITIAL_WAIT_TIME: float = 0.5
const BULLET_STOPPED_BASE_WAIT_TIME: float = 0.05
const BULLET_STOPPED_BASE_WAIT_TIME_MODIFIER: float = 0.02
const MAXIMUM_LIFE_LOST_INCREMENT: int = 200

var maximum_life_lost: int = 200

func _ready() -> void:
	secondary_attack_timer = Timer.new()
	secondary_attack_timer.set_one_shot(true)
	self.add_child(secondary_attack_timer)

func reset(reset_animations: bool = true) -> void:
	.reset(reset_animations)
	maximum_life_lost = 200

func set_normal_mode() -> void:
	attack_list = [
		'flamethrower',
		'bullet_hell_semicircle',
		'three_lane_fireball',
		'fireball_circle',
		'constant_fire_circle'
	]
	SimpleBulletManager.initializate_bullets({
		Globals.SimpleBulletTypes.STRAIGHT: 200,
		Globals.SimpleBulletTypes.CIRCULAR: 100,
		Globals.SimpleBulletTypes.SOFT_HOMING: 10,
		Globals.SimpleBulletTypes.DELAYED: 50,
	})
	ComplexBulletManager.initializate_bullets({
		Globals.ComplexBulletTypes.PULSATING: 1,
	})
	MinionManager.initializate_minions({
		Globals.MinionTypes.WIDE: 2,
	})

func set_hard_mode() -> void:
	attack_list = [
		'hard_flamethrower',
		'hard_bullet_hell_semicircle',
		'hard_three_lane_fireball',
		'hard_fireball_circle',
		'hard_constant_fire_circle'
	]
	SimpleBulletManager.initializate_bullets({
		Globals.SimpleBulletTypes.STRAIGHT: 200,
		Globals.SimpleBulletTypes.CIRCULAR: 200,
		Globals.SimpleBulletTypes.SOFT_HOMING: 10,
		Globals.SimpleBulletTypes.DELAYED_CIRCULAR: 150,
	})
	ComplexBulletManager.initializate_bullets({
		Globals.ComplexBulletTypes.RANDOM_PULSATING: 4,
	})
	MinionManager.initializate_minions({
		Globals.MinionTypes.WIDE: 2,
		Globals.MinionTypes.AUTOMATIC: 2,
	})

func set_hardest_mode() -> void:
	attack_list = [
		'hardest_fire_wall',
		'hardest_pulsating_fireball',
		'hardest_fireball_circle',
		'hardest_last_attack'
	]
	SimpleBulletManager.initializate_bullets({
		Globals.SimpleBulletTypes.STRAIGHT: 1500,
		Globals.SimpleBulletTypes.CIRCULAR: 1500,
		Globals.SimpleBulletTypes.SOFT_HOMING: 10,
	})
	ComplexBulletManager.initializate_bullets({
		Globals.ComplexBulletTypes.AIMED_PULSATING: 2,
		Globals.ComplexBulletTypes.PULSATING: 50,
	})

func check_hard_constant_fire_circle_next_stage() -> bool:
	if current_damage_taken >= maximum_life_lost:
		create_hard_constant_fire_circle(chosen_attack_params)
		maximum_life_lost += MAXIMUM_LIFE_LOST_INCREMENT
		return true
	return false
