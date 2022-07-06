extends "res://juegodetriangulos/res/scripts/levels/level0/level0_enemy_hardest_attacks.gd"

const BULLET_STOPPED_INITIAL_WAIT_TIME: float = 0.5
const BULLET_STOPPED_BASE_WAIT_TIME: float = 0.05
const BULLET_STOPPED_BASE_WAIT_TIME_MODIFIER: float = 0.02
const MAXIMUM_LIFE_LOST_INCREMENT: int = 200

var maximum_life_lost: int = 200

func _ready() -> void:
	secondary_attack_timer = Timer.new()
	secondary_attack_timer.set_one_shot(true)
	self.add_child(secondary_attack_timer)
	var current_difficulty_level = GameStateManager.get_difficulty_level()
	if current_difficulty_level == Globals.DifficultyLevels.HARDEST:
		set_hardest_mode()
	elif current_difficulty_level == Globals.DifficultyLevels.HARD:
		set_hard_mode()
	else:
		set_normal_mode()

func set_normal_mode() -> void:
	normal_mode = true 
	hard_mode = false
	hardest_mode = false 
	attack_list = ['flamethrower', 'bullet_hell_semicircle', 'three_lane_fireball', 'fireball_circle', 'constant_fire_circle']
	SimpleBulletManager.initializate_bullets({
		Globals.SimpleBulletTypes.STRAIGHT: 200,
		Globals.SimpleBulletTypes.CIRCULAR: 100,
		Globals.SimpleBulletTypes.SOFT_HOMING: 10,
		Globals.SimpleBulletTypes.DELAYED: 50,
		Globals.SimpleBulletTypes.HEALTH: 1,
	})
	ComplexBulletManager.initializate_bullets({
		Globals.ComplexBulletTypes.PULSATING: 1,
	})
	MinionManager.initializate_minions({
		Globals.MinionTypes.WIDE: 2,
	})

func set_hard_mode() -> void:
	normal_mode = false 
	hard_mode = true
	hardest_mode = false 
	attack_list = ['hard_flamethrower', 'hard_bullet_hell_semicircle', 'hard_three_lane_fireball', 'hard_fireball_circle', 'hard_constant_fire_circle']
	SimpleBulletManager.initializate_bullets({
		Globals.SimpleBulletTypes.STRAIGHT: 200,
		Globals.SimpleBulletTypes.CIRCULAR: 200,
		Globals.SimpleBulletTypes.SOFT_HOMING: 10,
		Globals.SimpleBulletTypes.DELAYED_CIRCULAR: 150,
		Globals.SimpleBulletTypes.HEALTH: 1,
	})
	ComplexBulletManager.initializate_bullets({
		Globals.ComplexBulletTypes.RANDOM_PULSATING: 4,
	})
	MinionManager.initializate_minions({
		Globals.MinionTypes.WIDE: 2,
		Globals.MinionTypes.AUTOMATIC: 2,
	})

func set_hardest_mode() -> void:
	normal_mode = false 
	hard_mode = false 
	hardest_mode = true 
	attack_list = ['hardest_fire_wall', 'hardest_pulsating_fireball', 'hardest_fireball_circle', 'hardest_last_attack']
	SimpleBulletManager.initializate_bullets({
		Globals.SimpleBulletTypes.STRAIGHT: 1500,
		Globals.SimpleBulletTypes.CIRCULAR: 1500,
		Globals.SimpleBulletTypes.SOFT_HOMING: 10,
		Globals.SimpleBulletTypes.HEALTH: 1,
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
