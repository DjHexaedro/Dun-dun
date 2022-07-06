# The logic used by the on screen joystick to move the player
extends Sprite


const MAX_DISTANCE_FROM_CENTER: float = 256.0

var mouse_position: Vector2
var distance_to_mouse_position: float
var angle_to_mouse: float
var current_distance_to_center: float
var player_velocity: Vector2 = Vector2.ZERO
var player_walking: bool = false
var deadzone: float
var running_deadzone: float
var walk_default: bool


func _ready():
	Settings.connect("settings_file_changed", self, "_on_settings_file_changed")
	walk_default = Settings.get_config_parameter("walk_default")
	deadzone = float(Settings.get_config_parameter("player_deadzone_onscreen_joystick"))
	running_deadzone = float(Settings.get_config_parameter("player_running_deadzone_onscreen_joystick"))

func _process(_delta):
	if visible:
		if Settings.get_config_parameter("input_method") == Globals.InputTypes.ONSCREEN_JOYSTICK and PlayerManager.get_player_input_enabled() and Input.is_mouse_button_pressed(BUTTON_LEFT):
			mouse_position = get_viewport().get_mouse_position()
			if get_parent().global_position.distance_to(mouse_position) <= 512:
				distance_to_mouse_position = clamp(
					get_parent().global_position.distance_to(mouse_position),
					-MAX_DISTANCE_FROM_CENTER,
					MAX_DISTANCE_FROM_CENTER
				)
				angle_to_mouse = (mouse_position - get_parent().global_position).angle()
				position = Vector2(
					clamp(
						cos(angle_to_mouse) * distance_to_mouse_position, 
						-MAX_DISTANCE_FROM_CENTER,
						MAX_DISTANCE_FROM_CENTER
					),
					clamp(
						sin(angle_to_mouse) * distance_to_mouse_position,
						-MAX_DISTANCE_FROM_CENTER,
						MAX_DISTANCE_FROM_CENTER
					)
				)

				var distance_to_mouse_percent = distance_to_mouse_position / MAX_DISTANCE_FROM_CENTER
				var x_distance_to_center_percent = position.x / MAX_DISTANCE_FROM_CENTER
				var y_distance_to_center_percent = position.y / MAX_DISTANCE_FROM_CENTER

				player_walking = walk_default
				if distance_to_mouse_percent < running_deadzone:
					player_walking = not walk_default
				
				PlayerManager.set_player_walking(player_walking)

				if abs(distance_to_mouse_percent) >= deadzone:
					player_velocity.x = x_distance_to_center_percent
					player_velocity.y = y_distance_to_center_percent
				else:
					player_velocity.x = 0.0
					player_velocity.y = 0.0
					
				PlayerManager.set_player_velocity(player_velocity)

		else:
			position = Vector2.ZERO
			player_velocity = Vector2.ZERO
			PlayerManager.set_player_velocity(player_velocity)

# Triggers when a change is made in the options menu and updates
# the joystick accordingly
func _on_settings_file_changed():
	walk_default = Settings.get_config_parameter("walk_default")
	deadzone = float(Settings.get_config_parameter("player_deadzone_onscreen_joystick"))
	running_deadzone = float(Settings.get_config_parameter("player_running_deadzone_onscreen_joystick"))
