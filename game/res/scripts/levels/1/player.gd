extends "res://juegodetriangulos/res/scripts/base/player.gd"


onready var has_attempted_movement_timer: Timer = $has_attempted_movement_timer

const INITIAL_POSITION: Vector2 = Vector2(-1, -1)
const KEYBOARD_MOVEMENT_DELAY: float = 0.05
const CONTROLLER_MOVEMENT_DELAY: float = 0.1

var current_position: Vector2 = INITIAL_POSITION
var can_move: bool = true
var has_attempted_movement: bool = false
var board_space_list: Array = []
var is_moving: bool = false 
var current_direction: Vector2 = Vector2.ZERO

func set_player_id(player_id: int) -> void:
	.set_player_id(player_id)

	# The player gets initialized after the board is created, so we need to
	# manually tell them the board has been modified
	_on_board_modified()

func _ready():
	player_type = Globals.LevelCodes.CHESSBOARD
	ArenaManager.get_current_location().connect(
		"board_modified", self, "_on_board_modified"
	)

func _input(event: InputEvent) -> void:
	# is_moving is also checked on _player_move(). I left this check here so
	# the button press evaluation is not done when it's gonna be discarded anyway
	if not is_moving and _allow_input():
		var direction: Vector2 = Vector2(
			1 if event.is_action_pressed(action_moveright) else
				(-1 if event.is_action_pressed(action_moveleft) else 0),
			1 if event.is_action_pressed(action_movedown) else
				(-1 if event.is_action_pressed(action_moveup) else 0)
		)
		_player_move(direction)

func _update_player_animations(idle: bool) -> void:
	._update_player_animations(idle)
	if not idle:
		moving_animation.set_frame(0)

func _player_move(direction: Vector2) -> void:
	if (
		(not is_moving) and
		(direction != Vector2.ZERO) and
		_check_new_position_is_valid(direction)
	):
		is_moving = true
		_flip_player_animations(direction.x == 1, false)
		_update_player_animations(false)
		if player_id == Globals.PlayerIDs.PLAYER_ONE:
			var offset_multiplier: float = (
				direction.x if not direction.y else -1.0
			)
			moving_animation.offset.x = 10 * offset_multiplier

		current_direction = direction
		current_position += direction

func reset() -> void:
	.reset()
	current_position = INITIAL_POSITION
	_on_board_modified()

func get_hit(dmg_source: Object, dmg: int = 1) -> void:
	.get_hit(dmg_source, dmg)
	if not is_light_enabled:
		# Doesn't use manage_light(false) because that would also update the
		# is_light_enabled variable
		light.visible = true

func can_be_hit() -> bool:
	return alive and not is_moving

func _allow_input() -> bool:
	return (
		visible and
		enable_input and
		not has_attempted_movement and
		Settings.get_config_parameter("input_method") !=\
				Globals.InputTypes.ONSCREEN_JOYSTICK
	)

func _check_new_position_is_valid(direction: Vector2) -> bool:
	var new_position: Vector2 = current_position + direction
	return not (
		new_position.y > (len(board_space_list) - 1) or
		new_position.y < 0 or
		new_position.x > (len(board_space_list[new_position.y]) - 1) or
		new_position.x < 0 or
		not board_space_list[new_position.y][new_position.x].enabled
	)

func _update_position() -> void:
	global_position = board_space_list[current_position.y][
		current_position.x
	].global_position
	board_space_list[current_position.y][current_position.x].show_waves()

	_update_player_animations(true)
	is_moving = false
	current_direction = Vector2.ZERO

func _on_board_modified() -> void:
	board_space_list = ArenaManager.get_current_location().get_board_info()
	if current_position == INITIAL_POSITION:
		var middle_row: int = int(len(board_space_list) / 2)
		current_position = Vector2(
			int(len(board_space_list[middle_row]) / 2), middle_row
		)
		_update_position()
	if not board_space_list[current_position.y][current_position.x].enabled:
		get_hit(self)
		current_position = Vector2(4, 4)
		_update_position()

func _on_moving_animation_frame_changed() -> void:
	global_position.x += 8 * current_direction.x
	global_position.y += 8 * current_direction.y

func _on_moving_animation_animation_finished() -> void:
	_update_position()

func _on_can_get_hit_timer_timeout() -> void:
	._on_can_get_hit_timer_timeout()
	if not is_light_enabled:
		# Doesn't use manage_light(false) because that would also update the
		# is_light_enabled variable
		light.visible = false

