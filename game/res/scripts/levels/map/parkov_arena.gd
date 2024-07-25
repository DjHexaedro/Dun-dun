# Script containing the code related to the arena for the Parkov boss fight
extends BaseMapArea

signal level1_fight_started
signal board_created
signal board_modified
signal spawners_modified
signal board_space_enabled

onready var boardspacescene = preload(
	"res://juegodetriangulos/scenes/level_assets/1/board_space.tscn"
)

onready var bgm_intro: AudioStreamPlayer = $bgm_intro
onready var bgm_loop: AudioStreamPlayer = $bgm_loop
onready var enemy: Node2D = $enemy
onready var background_sprite: AnimatedSprite = $sprite
onready var board_center: Position2D = $board_center
onready var arena_light: Light2D = $arena_light

const SCORE_PANEL_TEXT: String =\
		"Your last achieved score is\n%s\nYour top score is\n%s"
const ENEMY_ID: int = 0
const BASE_BOARD_HORIZONTAL_SIZE: int = 8
const BASE_BOARD_VERTICAL_SIZE: int = 8
const DEVIATION_FROM_CENTER: int = 32
const BOARD_SPACE_MARGIN: int = 64
const TIME_BEFORE_BOARD_SPACE_DISAPPEARS: float = 2.1

var open_doors_texture: Texture = preload(
	"res://juegodetriangulos/res/sprites/levels/0/arena/arena_bg_open_doors.png"
)
var enemy_already_defeated: bool = false
var board_space_list: Array = []
var current_board_horizontal_size: int = BASE_BOARD_HORIZONTAL_SIZE
var current_board_vertical_size: int = BASE_BOARD_VERTICAL_SIZE

func _ready():
	if Utils.device_is_phone():
		enemy.position = get_node("enemy_mobile_position").position
	create_board()
	background_sprite.play()
	connect("board_modified", self, "_on_board_modified")
	GameStateManager.connect("level_end", self, "_on_level_reload")
	GameStateManager.connect("level_restart", self, "_on_level_reload")
	if enemy_already_defeated:
		_on_enemy_despawn()
	else:
		enemy.connect("enemy_death", self, "_on_enemy_death")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BGM P2"), true)

func set_camera_focus(smoothing: bool) -> void:
	if Utils.device_is_phone():
		CameraManager.set_camera_target(
			get_node("camera_mobile_focus").get_path(), smoothing
		)
		CameraManager.set_camera_zoom(Vector2(0.7, 0.7))
	else:
		CameraManager.set_camera_target(get_path(), smoothing)

func get_enemy_positions_list() -> Dictionary:
	return {
		"global": {
			SCREEN_CENTER = global_position,
			TOP_Y =  global_position.y - 432,
			BOTTOM_Y = global_position.y + 432,
			CENTER_Y = global_position.y,
			LEFT_X = global_position.x - 768,
			RIGHT_X = global_position.x + 768,
			CENTER_X = global_position.x,
		},
		"local": {
			SCREEN_CENTER = Vector2(0, 0),
			TOP_Y = -432,
			BOTTOM_Y = 432,
			CENTER_Y = 0,
			LEFT_X = -768,
			RIGHT_X = 768,
			CENTER_X = 0,
		}
	}

func get_board_info() -> Array:
	return board_space_list

func start_boss_fight(temporary: bool = false) -> void:
	EnemyManager.setup_enemy("level1")
	enemy.connect("enemy_death", self, "_on_enemy_death")
	enemy.connect("enemy_despawn", self, "_on_enemy_despawn")
	if not temporary:
		Settings.save_game_statistic("fighting_boss", true)
		Settings.save_game_statistic("current_boss", ENEMY_ID)
	else:
		GameStateManager.set_camera_focus(true, false)
	if PlayerManager.get_player_lamp_on():
		PlayerManager.player_emit_lamp_on_signal()

func get_bgm_to_play() -> Array:
	if enemy_already_defeated:
		return [ArenaManager.get_default_bgm()]
	else:
		return [bgm_intro, bgm_loop]

func manage_lights(enabled: bool) -> void:
	var light_list: Array = get_tree().get_nodes_in_group(
		"on_level1_enemy_despawn"
	)
	for light in light_list:
		light.visible = enabled 

func reset() -> void:
	enable_all_board_spaces()
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BGM P2"), true)

func get_center() -> Vector2:
	var middle_row: int = int(current_board_vertical_size / 2)
	var middle_column: int = int(len(board_space_list[middle_row]) / 2)
	return board_space_list[middle_row]\
			[middle_column].global_position

func create_board() -> void:
	var board_space: Node2D
	var row_array: Array
	for row in range(BASE_BOARD_VERTICAL_SIZE):
		row_array = []
		for column in range(BASE_BOARD_HORIZONTAL_SIZE):
			board_space = boardspacescene.instance()
			board_center.add_child(board_space)
			board_space.global_position = board_center.global_position + Vector2(
				DEVIATION_FROM_CENTER + (BOARD_SPACE_MARGIN * column),
				BOARD_SPACE_MARGIN * row
			)
			row_array += [board_space]
		board_space_list += [row_array]
	emit_signal("board_created")

func remove_all_board_spaces_except(to_keep: Array) -> void:
	var board_spaces_to_remove: Array = []
	for row in len(board_space_list):
		for column in range(len(board_space_list[row])):
			if not [row, column] in to_keep:
				board_spaces_to_remove.append(board_space_list[row][column])
	remove_board_space_list(board_spaces_to_remove)

func remove_board_spaces_by_row(rows_to_remove: Array) -> void:
	var board_spaces_to_remove: Array = []
	for row in rows_to_remove:
		for board_space in board_space_list[row]:
			board_spaces_to_remove.append(board_space)
	remove_board_space_list(board_spaces_to_remove)

func remove_board_spaces_by_column(columns_to_remove: Array) -> void:
	var board_spaces_to_remove: Array = []
	for column in columns_to_remove:
		for row in board_space_list:
			board_spaces_to_remove.append(row[column])
	remove_board_space_list(board_spaces_to_remove)

func remove_board_space_list(board_spaces_to_remove: Array) -> void:
	arena_light.visible = true
	for board_space in board_spaces_to_remove:
		board_space.enabled = false
	yield(
		get_tree().create_timer(TIME_BEFORE_BOARD_SPACE_DISAPPEARS, false),
		"timeout"
	)
	emit_signal("board_modified")

func remove_board_space(row: int, col: int) -> void:
	board_space_list[row][col].enabled = false
	yield(
		get_tree().create_timer(TIME_BEFORE_BOARD_SPACE_DISAPPEARS, false),
		"timeout"
	)
	emit_signal("board_modified")

func enable_all_board_spaces() -> void:
	for row in range(BASE_BOARD_VERTICAL_SIZE):
		for column in range(BASE_BOARD_HORIZONTAL_SIZE):
			enable_board_space(row, column)

func enable_board_space(row: int, col: int) -> void:
	board_space_list[row][col].enabled = true
	yield(board_space_list[row][col], "enabled")
	emit_signal("board_space_enabled")

func manage_spawner_spaces_row(row: int, is_spawner: bool) -> void:
	if row >= 0 and len(board_space_list) > row:
		var column_index: int = 0
		for board_space in board_space_list[row]:
			board_space_list[row][column_index].can_spawn_pieces = is_spawner
			column_index += 1
		emit_signal("spawners_modified")

func manage_spawner_spaces_column(column: int, is_spawner: bool) -> void:
	if column >= 0:
		var row_index: int = 0
		for row in board_space_list:
			if len(row) > column:
				board_space_list[row_index][column].can_spawn_pieces = is_spawner
			row_index += 1
		emit_signal("spawners_modified")

func manage_spawner_space_by_index(
	row: int, column: int, is_spawner: bool
) -> void:
	if (
		row >= 0 and column >= 0 and
		len(board_space_list) > row and
		len(board_space_list[row]) > column
	):
		board_space_list[row][column].can_spawn_pieces = is_spawner
		emit_signal("spawners_modified")

func manage_spawner_space(board_space: Node2D, is_spawner: bool) -> Node2D:
	if board_space.enabled:
		board_space.can_spawn_pieces = is_spawner 
		if is_spawner:
			board_space.can_spawn_powerups = false 
	return board_space

func make_all_board_spaces_safe() -> void:
	for row in board_space_list:
		for board_space in row:
			board_space.can_spawn_pieces = false

func disable_powerup_spawning_spaces() -> void:
	for row in board_space_list:
		for board_space in row:
			board_space.can_spawn_powerups = false 

func enable_powerup_spawning_spaces(board_spaces_to_enable: Dictionary) -> void:
	for row in board_spaces_to_enable.keys():
		for col in board_spaces_to_enable[row]:
			board_space_list[row][col].can_spawn_powerups = true 

func manage_board_space_light_by_index(row: int, column: int, on: bool) -> void:
	if (
		row >= 0 and column >= 0 and
		len(board_space_list) > row and
		len(board_space_list[row]) > column
	):
		board_space_list[row][column].manage_light(on)

func get_valid_spawn_points(player_id: int = 0) -> Array:
	var valid_spawn_points: Array = []
	for row in board_space_list:
		for space in row:
			if (
				space.can_spawn_powerups and
				not (space.being_used or (player_id in space.near_player))
			):
				valid_spawn_points.append(space)
	return valid_spawn_points

func update_board_spaces_near_player(player_position: Vector2, player_id: int) -> void:
	for row in range(BASE_BOARD_VERTICAL_SIZE):
		for column in range(BASE_BOARD_HORIZONTAL_SIZE):
			# We always remove the player_id from the list to avoid
			# creating duplicates. Could be done with an else, but then we
			# could need to do more deletions if a duplicate was created
			board_space_list[row][column].near_player.erase(player_id)
			if (
				player_position.y - 1 <= row and
				player_position.x - 1 <= column
			) and (
				player_position.y + 1 >= row and
				player_position.x + 1 >= column
			):
				board_space_list[row][column].near_player.append(player_id)


func _on_enemy_death() -> void:
	enemy_already_defeated = true

func _on_enemy_despawn() -> void:
	manage_lights(true)

func _on_level_reload() -> void:
	if enemy_already_defeated:
		_on_enemy_despawn()

func _on_bgm_intro_finished():
	bgm_loop.stop()
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BGM P2"), false)
	bgm_loop.play()

func _on_board_modified():
	arena_light.visible = false
