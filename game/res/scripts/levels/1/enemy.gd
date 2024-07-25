extends "res://juegodetriangulos/res/scripts/levels/1/extreme_attacks.gd"
	
func set_normal_mode() -> void:
	attack_list = [
		'caro_kann_offense',
		'gellers_rook_and_pawn',
		'shirovs_bishops',
		'queens_gambit',
		'queens_defense',
		'queens_full_defense',
		'queens_rooks',
		'enrage_queen',
		'queens_ire',
		'queens_fury',
	]
	SimpleBulletManager.initializate_bullets({
		"pawn": 50,
		"rook": 50,
		"bishop": 50,
		"queen": 2,
	})
	
func set_hard_mode() -> void:
	attack_list = [
		'caro_kann_greater_offense',
		'shirovs_bishop_abuse',
		'gellers_improved_rooks',
		'parkovs_piece_hell',
		'gellers_rook_dance',
		'caro_kann_hidden_offense',
		'gellers_hidden_rooks',
		'queens_stealthy_gambit',
		'hide_queens',
		'absolute_darkness',
	]
	SimpleBulletManager.initializate_bullets({
		"pawn": 50,
		"rook": 50,
		"bishop": 50,
		"queen": 5,
	})
	
func set_hardest_mode() -> void:
	attack_list = [
		'pawn_field',
		'danger_line',
		'towers_of_doom',
		'big_plus',
	]
	SimpleBulletManager.initializate_bullets({
		"pawn": 20,
		"rook": 30,
		"bishop": 5,
		"queen": 2,
	})
