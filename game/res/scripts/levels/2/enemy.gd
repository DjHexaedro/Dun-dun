extends "res://juegodetriangulos/res/scripts/levels/2/hard_attacks.gd"
	
func set_normal_mode() -> void:
	attack_list = [
		"zero_storm",
		"binary_tree_of_perdition",
		"linear_algebra",
		"zero_escape",
		"zero_room",
	]
	SimpleBulletManager.initializate_bullets({
		Globals.SimpleBulletTypes.STRAIGHT_ZERO: 1000,
		Globals.SimpleBulletTypes.CIRCULAR_ZERO: 1000,
	})
	ComplexBulletManager.initializate_bullets({
		Globals.ComplexBulletTypes.POWERUP: 5,
		Globals.ComplexBulletTypes.DIVIDING: 140,
		Globals.ComplexBulletTypes.ACTUAL_HOMMING: 3,
		Globals.ComplexBulletTypes.PULSATING_ZERO: 10,
	})
	
func set_hard_mode() -> void:
	attack_list = [
		"zero_storm",
		"binary_tree_of_perdition",
		"linear_algebra",
		"zero_escape",
		"zero_room",
	]
	SimpleBulletManager.initializate_bullets({
		Globals.SimpleBulletTypes.STRAIGHT_ZERO: 1000,
		Globals.SimpleBulletTypes.CIRCULAR_ZERO: 1000,
	})
	ComplexBulletManager.initializate_bullets({
		Globals.ComplexBulletTypes.POWERUP: 5,
		Globals.ComplexBulletTypes.DIVIDING: 360,
		Globals.ComplexBulletTypes.ACTUAL_HOMMING: 3,
		Globals.ComplexBulletTypes.PULSATING_ZERO: 10,
	})
	
func set_hardest_mode() -> void:
	pass
