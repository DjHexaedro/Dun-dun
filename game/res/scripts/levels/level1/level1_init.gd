extends "res://juegodetriangulos/res/scripts/base/base_level.gd"


onready var boardspacescene = preload("res://juegodetriangulos/scenes/level_assets/level1/board_space.tscn")

var screen_middle_point
var board_space_margin
var board_space_list = []
var board_space_spawners = {}
var safe_board_space_list = {}
var board_horizontal_size = 8
var board_vertical_size = 8
var board_center = Position2D.new()

func _ready():
	._ready()
	# powerupscene = preload("res://juegodetriangulos/scenes/level_assets/level1/powerup.tscn")
	screen_middle_point = Globals.Positions.SCREEN_CENTER
	board_space_margin = 15

func start_level():
	create_board()
	.start_level()

func end_level(player_victory = false):
	delete_board()
	.end_level(player_victory)

func create_board():
	var row = 0
	var column = 0
	var board_space
	var vertical_array
	var initial_position = Vector2(screen_middle_point.x - 135, screen_middle_point.y - 90)
	get_tree().get_root().add_child(board_center)
	board_center.position = screen_middle_point 
	while (row < board_vertical_size):
		vertical_array = []
		while (column < board_horizontal_size):
			board_space = boardspacescene.instance()
			board_center.add_child(board_space)
			board_space.set_position_from_two_values(initial_position.x + (board_space_margin + (board_space_margin * 2 * column)), initial_position.y + (board_space_margin * 2 * row))
			vertical_array += [board_space]
			column += 1
		column = 0
		row += 1
		board_space_list += [vertical_array]
	safe_board_space_list = {}
	row = 0
	column = 0
	while row < board_vertical_size:
		safe_board_space_list[row] = []
		while column < board_horizontal_size:
			safe_board_space_list[row] += [column]
			column += 1
		column = 0
		row += 1
	row = 0
	board_space_spawners = {}
	while row < board_vertical_size:
		board_space_spawners[row] = []
		row += 1
	column = 0
	while column < board_horizontal_size:
		add_space_to_spawner_list(0, column)
		column += 1

func add_space_to_spawner_list(row, column):
	board_space_list[row][column].set_can_spawn_pieces(true)
	board_space_spawners[row] += [column]
	safe_board_space_list[row].erase(column)
	if not safe_board_space_list[row]:
		safe_board_space_list.erase(row)

func make_board_space_safe(row, column):
	board_space_list[row][column].set_can_spawn_pieces(false)
	if not safe_board_space_list.get(row, false):
		safe_board_space_list[row] = []
	safe_board_space_list[row] += [column]
	board_space_spawners[row].erase(column)

func delete_board():
	for row in board_space_list:
		for board_space in row:
			board_space.queue_free()
	board_space_list = []

# func spawn_powerup(userdata=null):
	# var new_powerup = powerupscene.instance()
	# get_tree().get_root().add_child(new_powerup)
	# new_powerup.set_properties(self)
	# powerup_list.append(new_powerup)
