# Manages the buttons that appear onscreen when using the Android HUD
extends Button

var pause_menu: Node
var is_walking: bool = false
var can_move: bool = true


func _ready() -> void:
	pause_menu = Utils.get_pause_menu()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		manage_drag_events(event)
	if event is InputEventScreenTouch:
		manage_touch_events(event)

func manage_drag_events(event: InputEvent) -> void:
	if event.index == 0:
		if PlayerManager.get_player_type() == Globals.LevelCodes.CHESSBOARD:
			if event.relative != Vector2.ZERO and can_move:
				var direction: Vector2 = Vector2.ZERO

				if abs(event.relative.x) < abs(event.relative.y):
					direction = Vector2.DOWN if event.relative.y >= 0 else Vector2.UP
				elif abs(event.relative.x) > abs(event.relative.y):
					direction = Vector2.RIGHT if event.relative.x >= 0 else Vector2.LEFT

				if direction:
					PlayerManager.set_player_velocity(direction)
					can_move = false
		else:
			PlayerManager.set_player_velocity_touch(event.relative)

func manage_touch_events(event: InputEvent) -> void:
	if PlayerManager.get_player_type() != Globals.LevelCodes.CHESSBOARD:
		if event.index == 0:
			PlayerManager.set_player_velocity_touch(Vector2.ZERO)
		if event.index == 1:
			PlayerManager.set_player_walking_touch(event.pressed)
	else:
		if event.index == 0 and not event.pressed:
			can_move = true

func _on_pause_menu_pressed() -> void:
	if pause_menu.enabled:
		pause_menu.manage_pausing(true)
