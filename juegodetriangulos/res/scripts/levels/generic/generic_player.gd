# The player that you know and love from the beginning of the game. Can move
# freely in both the x and y planes and can walk by pressing shift
extends BasePlayer

class_name GenericPlayer

signal lamp_on

const WALKING_SPEED_MULTIPLIER: float = 0.5
const WALKING_ANIMATION_SPEED_SCALE: float = 0.75
const BASE_SPEED_MULTIPLIER: float = 1.0
const BASE_ANIMATION_SPEED_SCALE: float = 2.0
const GRAPHICS_DEFAULT_COLOR: Color = Color(1, 1, 1, 1)
const GRAPHICS_WALKING_COLOR: Color = Color(0, 0, 0, 0.25)
const ANIMATION_LIST: Dictionary = {
	IDLE = "idle_animation",
	MOVING = "moving_animation",
	DEATH = "death_animation",
}
const LIGHT_DECREASE_STEP_AMOUNT: float = 3.0
const STOP_GET_HIT_IF_MOVING_TIMER_TIME: float = 0.075
const TOTAL_LIGHT_HORIZONTAL_MOVEMENT: float = -6.0
const TOTAL_LIGHT_VERTICAL_MOVEMENT: float = 12.0

onready var lamp_on_sound: AudioStreamPlayer = $lamp_on_sound
onready var light: Light2D = $light
onready var hitbox_marker_sprite: Sprite = $hitbox_marker
onready var light_decrease_on_death_timer: Timer = $light_decrease_on_death_timer

var speed_multiplier: float
var current_animation: String

# These action names are defined under Project > Project Settings > Input Mapping
var action_walk: String = "player_walk"
var action_moveup: String  = "player_moveup"
var action_movedown: String  = "player_movedown"
var action_moveleft: String  = "player_moveleft"
var action_moveright: String  = "player_moveright"

var allow_lamp_to_turn_on: bool = false
var walk_default: bool
var current_animation_name: String
var always_show_hitbox: bool = false
var initial_light_scale: float = 0.5
var is_lamp_on: bool = false
var stop_get_hit_if_moving_timer_timer: Timer
var light_on_death_texture_decrement: float
var light_on_death_position_horizontal_movement: float = TOTAL_LIGHT_HORIZONTAL_MOVEMENT / LIGHT_DECREASE_STEP_AMOUNT
var light_on_death_position_vertical_movement: float = TOTAL_LIGHT_VERTICAL_MOVEMENT / LIGHT_DECREASE_STEP_AMOUNT


func _ready():

	# If the player isn't currently in a boss fight, the camera should follow them
	if not Settings.get_game_statistic("fighting_boss", false):
		CameraManager.set_camera_target(get_path())

	initial_light_scale = light.texture_scale
	Settings.connect("settings_file_changed", self, "_on_settings_file_changed")
	walk_default = Settings.get_config_parameter("walk_default")
	speed_multiplier = WALKING_SPEED_MULTIPLIER if walk_default else BASE_SPEED_MULTIPLIER
	if Settings.get_config_parameter("input_method") == Globals.InputTypes.CONTROLLER:
		set_controller_actions()
	always_show_hitbox = Settings.get_config_parameter("always_show_hitbox")
	if always_show_hitbox:
		hitbox_marker_sprite.visible = true
		animation_list.modulate = GRAPHICS_WALKING_COLOR
	lamp_on_sound.stream.loop = false
	
	# The initial Enter press when the player chooses the difficulty
	# can (and will) trigger the code to turn the lamp on.
	# This small delay fixes that problem
	yield(get_tree().create_timer(0.1), "timeout")
	
	allow_lamp_to_turn_on = not Settings.get_game_statistic("is_lamp_on", false)
	if GameStateManager.get_moving_does_damage():
		stop_get_hit_if_moving_timer_timer = Timer.new()
		stop_get_hit_if_moving_timer_timer.set_wait_time(STOP_GET_HIT_IF_MOVING_TIMER_TIME)
		stop_get_hit_if_moving_timer_timer.set_one_shot(true)
		add_child(stop_get_hit_if_moving_timer_timer)
		stop_get_hit_if_moving_timer_timer.connect("timeout", self, "_on_stop_get_hit_if_moving_timer_timer_timeout")
	light_on_death_texture_decrement = light.texture_scale / LIGHT_DECREASE_STEP_AMOUNT

func _input(event):
	if _can_turn_lamp_on(event):
		light.visible = true
		lamp_on_sound.play()
		is_lamp_on = true
		Settings.save_game_statistic("is_lamp_on", true)
	if _allow_input():
		if event.is_action_pressed(action_walk):
			PlayerManager.set_player_walking(not walk_default)
		if not Input.is_action_pressed(action_walk):
			PlayerManager.set_player_walking(walk_default)
		PlayerManager.set_player_velocity(Input.get_vector(
			action_moveleft, action_moveright, action_moveup, action_movedown
		))

func _process(delta):
	if visible:
		if velocity.length():
			var intended_velocity = velocity.normalized() * BASE_SPEED * speed_multiplier
			velocity = Vector2(clamp(intended_velocity.x, -BASE_SPEED, BASE_SPEED), clamp(intended_velocity.y, -BASE_SPEED, BASE_SPEED))

		var collision = move_and_collide(velocity * delta)
		if collision:
			var is_limit = "limit" in collision.collider.name
			var is_horizontal = collision.collider.name in ["top", "bottom"]
			
			# This weird if is like this to prevent the wall bump sound to play
			# when you are running along a wall, instead of into it
			if (is_limit and is_horizontal and velocity.y) or (is_limit and not is_horizontal and velocity.x):
				get_hit(collision.collider)

		if enable_input:
			if velocity == Vector2.ZERO:
				if GameStateManager.get_standing_still_does_damage() and get_hit_if_standing_still_timer.is_stopped():
					get_hit_if_standing_still_timer.start()
				if GameStateManager.get_moving_does_damage() and stop_get_hit_if_moving_timer_timer.is_stopped():
					stop_get_hit_if_moving_timer_timer.start()
				idle_animation.visible = true
				idle_animation.play()
				moving_animation.visible = false 
				moving_animation.stop()
			else:
				if GameStateManager.get_standing_still_does_damage() and not get_hit_if_standing_still_timer.is_stopped():
					get_hit_if_standing_still_timer.stop()
				if GameStateManager.get_moving_does_damage():
					if not stop_get_hit_if_moving_timer_timer.is_stopped():
						stop_get_hit_if_moving_timer_timer.stop()
					if get_hit_if_moving_timer.is_stopped():
						get_hit_if_moving_timer.start()
				if velocity.x > 0.0:
					moving_animation.flip_h = true 
					idle_animation.flip_h = true 
					death_animation.flip_h = true 
					light_fade_animation.flip_h = true 
				elif velocity.x < 0.0:
					moving_animation.flip_h = false 
					idle_animation.flip_h = false 
					death_animation.flip_h = false 
					light_fade_animation.flip_h = false 
				elif velocity.y > 0.0:
					if not moving_animation.is_playing():
						moving_animation.flip_h = true 
				elif velocity.y < 0.0:
					if not moving_animation.is_playing():
						moving_animation.flip_h = false 
				if not moving_animation.is_playing():
					idle_animation.visible = false 
					idle_animation.stop()
					moving_animation.visible = true 
					moving_animation.play()

func reset() -> void:
	.reset()
	light.texture_scale = initial_light_scale
	light.position = Vector2.ZERO

func stand_still() -> void:
	enable_input = false
	velocity = Vector2.ZERO
	idle_animation.visible = true 
	moving_animation.visible = false 

func death() -> void:
	invencible = true
	enable_input = false
	PlayerManager.set_player_velocity(Vector2.ZERO)
	Settings.increase_game_statistic("deaths", 1)
	animation_list.modulate = GRAPHICS_DEFAULT_COLOR
	idle_animation.visible = false
	moving_animation.visible = false
	death_animation.visible = true 
	death_animation.play()

# Again, all these action names are defined under:
# Project > Project Settings > Input Mapping
func set_controller_actions() -> void:
	action_walk = "player_walk_controller"
	action_moveup = "player_moveup_controller"
	action_movedown = "player_movedown_controller"
	action_moveleft = "player_moveleft_controller"
	action_moveright = "player_moveright_controller"

func set_keyboard_actions() -> void:
	action_walk = "player_walk"
	action_moveup = "player_moveup"
	action_movedown = "player_movedown"
	action_moveleft = "player_moveleft"
	action_moveright = "player_moveright"

func emit_lamp_on_signal() -> void:
	emit_signal("lamp_on")

func _can_turn_lamp_on(event) -> bool:
	return (
		allow_lamp_to_turn_on and
		(event.is_action_pressed("ui_accept") or event is InputEventScreenTouch) and
		not light.visible
	)

func _allow_input() -> bool:
	return (
		visible and
		enable_input and
		Settings.get_config_parameter("input_method") != Globals.InputTypes.ONSCREEN_JOYSTICK
	)

func _on_light_fade_animation_frame_changed():
	light.texture_scale -= light_on_death_texture_decrement
	light.position += Vector2(light_on_death_position_horizontal_movement, light_on_death_position_vertical_movement)

func _on_death_animation_animation_finished() -> void:
	emit_signal("player_begin_death")
	death_animation.visible = false
	light_fade_animation.visible = true
	light_fade_animation.play()

func _on_light_fade_animation_animation_finished():
	light_fade_animation.stop()
	emit_signal("player_death")

# Triggers when a change is made in the options menu and updates
# the character accordingly
func _on_settings_file_changed() -> void:
	walk_default = Settings.get_config_parameter("walk_default")
	always_show_hitbox = Settings.get_config_parameter("always_show_hitbox")
	hitbox_marker_sprite.visible = always_show_hitbox
	animation_list.modulate = GRAPHICS_WALKING_COLOR if always_show_hitbox else GRAPHICS_DEFAULT_COLOR
	if Settings.get_config_parameter("input_method") == Globals.InputTypes.KEYBOARD:
		set_keyboard_actions()
		HudManager.manage_hud_joystick(false)
	elif Settings.get_config_parameter("input_method") == Globals.InputTypes.CONTROLLER:
		set_controller_actions()
		HudManager.manage_hud_joystick(false)
	else:
		HudManager.manage_hud_joystick(true)

func _on_stop_get_hit_if_moving_timer_timer_timeout() -> void:
	get_hit_if_moving_timer.stop()
