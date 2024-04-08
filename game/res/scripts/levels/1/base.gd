# Base class for the second boss of the game, Parkov. Contains the methods
# that are used in most of the difficulties
extends BaseEnemy

signal clear_used_board_space_spawners

onready var idle_animation: AnimatedSprite = $idle_animation
onready var laugh_animation: AnimatedSprite = $laugh_animation
onready var spawn_animation: AnimatedSprite = $spawn_animation
onready var invert_shader: ShaderMaterial = preload("res://juegodetriangulos/res/shaders/invert.tres")

const PAWN_BASE_SPEED: int = 100
const ROOK_BASE_SPEED: int = 250
const BISHOP_BASE_SPEED: int = 150
const QUEEN_BASE_SPEED: int = 250

var board_space_list: Array
var board_space_spawners: Dictionary
var used_board_space_spawners: Dictionary = {}
var previous_used_board_space_spawners: Dictionary = {}
var spawned_pieces_list: Array = []
var first_attack: bool = true
var start_attacking: bool = true

func _ready():
	can_move = false
	can_attack = true 
	get_parent().connect("board_created", self, "_on_board_created")
	get_parent().connect("board_modified", self, "_on_board_modified")
	get_parent().connect("spawners_modified", self, "_on_spawners_modified")
	connect(
		"clear_used_board_space_spawners", self,
		"_on_clear_used_board_space_spawners"
	)

func change_boss_phase(new_boss_phase: int) -> void:
	if new_boss_phase % 2 == 1 or Utils.is_difficulty_hardest():
		PlayerManager.heal_player()
	_update_board(new_boss_phase)
	.change_boss_phase(new_boss_phase)

func select_spawn_space_in_row(row: int, is_random: bool = false) -> Vector2:
	if not board_space_spawners.get(row, []):
		return select_spawn_space(true)

	var current_min_value: int = 999
	var spawn_space: Vector2 = Vector2(row, 0) 
	var chosen_player_id: int = randi() % PlayerManager.get_number_of_players()
	var player: Node = PlayerManager.get_player_node(chosen_player_id)

	if is_random:
		var n_of_columns: int = len(board_space_spawners[row])
		var chosen_column: int = board_space_spawners[row][randi()%n_of_columns]
		spawn_space = Vector2(chosen_column, row)

	else:
		for column in board_space_spawners[row]:
			var new_value: int = (
				abs(player.current_position.y - row) +
				abs(player.current_position.x - column)
			)
			if current_min_value != new_value:
				current_min_value = min(current_min_value, new_value)
				if current_min_value == new_value:
					spawn_space.x = column 
			else:
				var possible_spawn: Vector2 = Vector2(row, column)
				spawn_space = [possible_spawn, spawn_space][randi()%2]

	set_spawn_space_as_used(spawn_space)
	return spawn_space

func select_spawn_space_in_column(
	column: int, is_random: bool = false
) -> Vector2:
	var current_min_value: int = 999
	var spawn_space: Vector2 = Vector2(column, 0) 
	var chosen_player_id: int = randi() % PlayerManager.get_number_of_players()
	var player: Node = PlayerManager.get_player_node(chosen_player_id)

	if is_random:
		var n_of_rows: int = len(board_space_spawners)
		var chosen_row: int = randi()%n_of_rows
		var n_of_tries: int = 0
		while (
			not len(board_space_spawners[chosen_row]) <= column and
			n_of_tries < 100
		):
			chosen_row = randi()%n_of_rows
			n_of_tries += 1
		if n_of_tries >= 100:
			return select_spawn_space(true)
		spawn_space = Vector2(column, chosen_row)

	else:
		for row in board_space_spawners:
			if column <= len(board_space_spawners[row]):
				var new_value: int = (
					abs(player.current_position.y - row) +
					abs(player.current_position.x - column)
				)
				if current_min_value != new_value:
					current_min_value = min(current_min_value, new_value)
					if current_min_value == new_value:
						spawn_space.x = column 
				else:
					var possible_spawn: Vector2 = Vector2(row, column)
					spawn_space = [possible_spawn, spawn_space][randi()%2]
		if current_min_value == 999:
			return select_spawn_space(true)

	set_spawn_space_as_used(spawn_space)
	return spawn_space

func select_spawn_space(is_random: bool = false) -> Vector2:
	var current_min_value: int = 999
	var spawn_space: Vector2 = Vector2.ZERO
	var chosen_player_id: int = randi() % PlayerManager.get_number_of_players()
	var player: Node = PlayerManager.get_player_node(chosen_player_id)
	if is_random:
		var allowed_rows: Dictionary = {}
		for row in board_space_spawners.keys():
			if board_space_spawners[row]:
				allowed_rows[row] = board_space_spawners[row]

		var row_list: Array = allowed_rows.keys()
		var chosen_row: int = row_list[randi()%len(row_list)]
		var column_list: Array = board_space_spawners[chosen_row]
		var chosen_column: int = column_list[randi()%len(column_list)]
		spawn_space = Vector2(chosen_column, chosen_row)
	else:
		for row in board_space_spawners.keys():
			for column in board_space_spawners[row]:
				var new_value: int = (
					abs(player.current_position.y - row) +
					abs(player.current_position.x - column)
				)
				if current_min_value != new_value:
					current_min_value = min(current_min_value, new_value)
					if current_min_value == new_value:
						spawn_space = Vector2(column, row)
				else:
					var possible_spawn: Vector2 = Vector2(column, row)
					spawn_space = [possible_spawn, spawn_space][randi()%2]
	set_spawn_space_as_used(spawn_space)
	return spawn_space

func set_spawn_space_as_used(spawn_space: Vector2) -> void:
	var row: int = spawn_space.y
	var column: int = spawn_space.x
	if not used_board_space_spawners.get(row, false):
		used_board_space_spawners[row] = []
	used_board_space_spawners[row].append(column)
	board_space_spawners[row].erase(column)

func get_board_space(position: Vector2) -> Node2D:
	return board_space_list[position.y][position.x]

func get_random_board_space_position() -> Vector2:
	var valid: bool = false
	var row: int
	var column: int
	var player_list: Array = PlayerManager.get_player_list()
	while not valid:
		row = randi()%len(board_space_list)
		column = randi()%len(board_space_list[row])

		# If the board space is not being used, then we temporaly set it as
		# valid even though it could not be in the end
		if not used_board_space_spawners.get(row, {}).get(column, false):
			valid = true

			# Here we check it is an actual valid space that
			# isn't too close to any of the players
			for player in player_list:
				if (
					player.current_position.y - 1 <= row and
					player.current_position.x - 1 <= column 
				) and (
					player.current_position.y + 1 >= row and
					player.current_position.x + 1 >= column 
				):
					valid = false	
					break
	return Vector2(column, row)

func reset(_reset_animations: bool = true) -> void:
	.reset()
	used_board_space_spawners = {}
	previous_used_board_space_spawners = {}
	spawned_pieces_list = []
	first_attack = true
	start_attacking = true
	emit_signal("clear_used_board_space_spawners")
	get_parent().enable_all_board_spaces()
	get_parent().make_all_board_spaces_safe()
	get_parent().disable_powerup_spawning_spaces()
	_setup_enemy()
	_on_board_created()


func _setup_enemy() -> void:
	idle_animation.stop()
	idle_animation.hide()
	idle_animation.set_frame(0)
	laugh_animation.stop()
	laugh_animation.hide()
	laugh_animation.set_frame(0)
	spawn_animation.stop()
	spawn_animation.hide()
	spawn_animation.set_frame(0)

func unload() -> void:
	var spawned_pieces_list_copy = spawned_pieces_list.duplicate()
	for piece in spawned_pieces_list_copy:
		piece.unload()
	spawned_pieces_list = []
	.unload()

func _update_board(_boss_phase: int = 1) -> void:
	pass

func _on_board_created() -> void:
	board_space_list = get_parent().get_board_info()
	if not Utils.is_difficulty_hardest():
		PowerupManager.enable_powerups(false, Globals.LevelCodes.CHESSBOARD)
	yield(get_tree().create_timer(1), "timeout")
	spawn_animation.show()
	spawn_animation.play()

func _on_spawn_animation_animation_finished() -> void:
	idle_animation.hide()
	spawn_animation.hide()
	spawn_animation.stop()
	spawn_animation.set_frame(0)
	laugh_animation.show()
	laugh_animation.play()

func _on_laugh_animation_animation_finished() -> void:
	spawn_animation.hide()
	laugh_animation.stop()
	laugh_animation.hide()
	laugh_animation.set_frame(0)
	idle_animation.show()
	idle_animation.play()

	if start_attacking:
		PlayerManager.get_player_node().connect("player_hit", self, "_on_player_hit")
		get_parent().arena_light.visible = false
		ArenaManager.update_current_bgm(true)
		_update_board()
		attack()
		start_attacking = false

func _on_board_modified() -> void:
	board_space_list = get_parent().get_board_info()

func _on_spawners_modified() -> void:
	var current_row_index = 0
	var current_column_index = 0
	board_space_spawners = {}
	for row in board_space_list:
		for board_space in row:
			if board_space.can_spawn_pieces:
				if not board_space_spawners.get(current_row_index, false):
					board_space_spawners[current_row_index] = []
				board_space_spawners[current_row_index].append(current_column_index)
			current_column_index += 1
		current_row_index += 1
		current_column_index = 0
	used_board_space_spawners = {}

func _on_clear_used_board_space_spawners() -> void:
	for row in previous_used_board_space_spawners:
		for col in previous_used_board_space_spawners[row]:
			if row in board_space_spawners:
				board_space_spawners[row].append(col)
	previous_used_board_space_spawners = used_board_space_spawners.duplicate()
	used_board_space_spawners = {}

func _on_player_hit() -> void:
	idle_animation.hide()
	spawn_animation.hide()
	laugh_animation.show()
	laugh_animation.play()
