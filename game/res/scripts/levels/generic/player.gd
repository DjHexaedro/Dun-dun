# The player that you know and love from the beginning of the game. Can move
# freely in both the x and y planes and can walk by pressing shift
extends BasePlayer

class_name GenericPlayer

signal lamp_on

const WALKING_SPEED_MULTIPLIER: float = 0.5
const WALKING_ANIMATION_SPEED_SCALE: float = 0.75
const BASE_SPEED_MULTIPLIER: float = 1.0
const BASE_ANIMATION_SPEED_SCALE: float = 2.0

onready var lamp_on_sound: AudioStreamPlayer = $lamp_on_sound

var speed_multiplier: float
var current_animation: String

var allow_lamp_to_turn_on: bool = false
var current_animation_name: String
var stop_get_hit_if_moving_timer_timer: Timer
var set_idle_animation_on_phone_timer: Timer
var new_global_position: Vector2 = Globals.OUT_OF_BOUNDS_POSITION


func set_player_id(new_player_id: int) -> void:
	.set_player_id(new_player_id)

	always_show_hitbox = Settings.get_config_parameter("always_show_hitbox")
	if always_show_hitbox:
		hitbox_marker_sprite.visible = true
		animation_list.modulate = GRAPHICS_WALKING_COLOR

func _ready():
	walk_default = Settings.get_config_parameter("walk_default")
	speed_multiplier =\
			WALKING_SPEED_MULTIPLIER if walk_default else BASE_SPEED_MULTIPLIER
	
	if GameStateManager.get_moving_does_damage():
		stop_get_hit_if_moving_timer_timer = Timer.new()
		stop_get_hit_if_moving_timer_timer.set_wait_time(
			STOP_GET_HIT_IF_MOVING_TIMER_TIME
		)
		stop_get_hit_if_moving_timer_timer.set_one_shot(true)
		add_child(stop_get_hit_if_moving_timer_timer)
		stop_get_hit_if_moving_timer_timer.connect(
			"timeout", self, "_on_stop_get_hit_if_moving_timer_timer_timeout"
		)

	if Utils.device_is_phone():
		set_idle_animation_on_phone_timer = Timer.new()
		set_idle_animation_on_phone_timer.set_wait_time(0.1)
		set_idle_animation_on_phone_timer.set_one_shot(true)
		add_child(set_idle_animation_on_phone_timer)
		set_idle_animation_on_phone_timer.connect(
			"timeout", self, "_on_set_idle_animation_on_phone_timer_timeout"
		)


func _input(event):
	if _allow_input():
		if alive:
			if event.is_action_pressed(action_walk):
				_player_walk(not walk_default)
			if not Input.is_action_pressed(action_walk):
				_player_walk(walk_default)
		_player_move(Input.get_vector(
			action_moveleft, action_moveright, action_moveup, action_movedown
		))

func _physics_process(delta: float):
	if visible:
		var space_state = get_world_2d().direct_space_state
		if velocity.length():
			var intended_velocity =\
					velocity.normalized() * BASE_SPEED * speed_multiplier
			velocity = Vector2(
				clamp(intended_velocity.x, -BASE_SPEED, BASE_SPEED),
				clamp(intended_velocity.y, -BASE_SPEED, BASE_SPEED)
			)
			new_global_position = global_position + (velocity * delta)

		var collision = space_state.intersect_ray(global_position, new_global_position)
		if collision:
			var is_limit = "limit" in collision.collider.name
			var is_horizontal = collision.collider.name in ["top", "bottom"]
			
			# This weird if is like this to prevent the wall bump sound playing
			# when you are running along a wall, instead of into it
			if (
				(is_limit and is_horizontal and velocity.y) or
				(is_limit and not is_horizontal and velocity.x)
			):
				get_hit(collision.collider)

		else:
			global_position = new_global_position

		if enable_input:
			if velocity == Vector2.ZERO:
				if (
					GameStateManager.get_standing_still_does_damage() and
					get_hit_if_standing_still_timer.is_stopped()
				):
					get_hit_if_standing_still_timer.start()
				if (
					GameStateManager.get_moving_does_damage() and
					stop_get_hit_if_moving_timer_timer.is_stopped()
				):
					stop_get_hit_if_moving_timer_timer.start()
			else:
				if (
					GameStateManager.get_standing_still_does_damage() and
					not get_hit_if_standing_still_timer.is_stopped()
				):
					get_hit_if_standing_still_timer.stop()
				if GameStateManager.get_moving_does_damage():
					if not stop_get_hit_if_moving_timer_timer.is_stopped():
						stop_get_hit_if_moving_timer_timer.stop()
					if get_hit_if_moving_timer.is_stopped():
						get_hit_if_moving_timer.start()

func _player_move(new_velocity: Vector2) -> void:
	velocity = new_velocity
	_update_player_animations(velocity == Vector2.ZERO)
	_flip_player_animations(
		(velocity.x > 0.0) or
			((velocity.x == 0.0) and (velocity.y > 0.0)),
		not moving_animation.is_playing() and
			(velocity.x == 0.0) and (velocity.y != 0.0)
	)

func _player_move_touch(relative: Vector2) -> void:
	if alive:
		new_global_position = global_position + relative * speed_multiplier

		if abs(relative.x) > 1 or abs(relative.y) > 2:
			_update_player_animations(false)
			_flip_player_animations(
				(relative.x > 0.0) or
					((relative.x == 0.0) and (relative.y > 0.0)),
				not moving_animation.is_playing() and
					(relative.x == 0.0) and (relative.y != 0.0)
			)

		if not set_idle_animation_on_phone_timer.is_stopped():
			set_idle_animation_on_phone_timer.stop()
		set_idle_animation_on_phone_timer.start()

func _player_walk(walking: bool) -> void:
	if not always_show_hitbox:
		hitbox_marker_sprite.visible = walking
		animation_list.modulate = (
			GRAPHICS_WALKING_COLOR if walking else GRAPHICS_DEFAULT_COLOR
		)
	speed_multiplier = (
		WALKING_SPEED_MULTIPLIER if walking else BASE_SPEED_MULTIPLIER
	)
	moving_animation.speed_scale = (
		WALKING_ANIMATION_SPEED_SCALE if walking else BASE_ANIMATION_SPEED_SCALE
	)

func _player_walk_touch(walking: bool) -> void:
	_player_walk(walking)

func reset() -> void:
	.reset()
	new_global_position = global_position

func stand_still() -> void:
	enable_input = false
	velocity = Vector2.ZERO
	idle_animation.visible = true 
	moving_animation.visible = false

func instance_player_ghost() -> void:
	.instance_player_ghost()
	_player_walk(false)

func emit_lamp_on_signal() -> void:
	emit_signal("lamp_on")

func _can_turn_lamp_on(event) -> bool:
	return (
		allow_lamp_to_turn_on and
		(event.is_action_pressed("ui_accept") or event is InputEventScreenTouch)
		and not light.visible
	)

func _on_stop_get_hit_if_moving_timer_timer_timeout() -> void:
	get_hit_if_moving_timer.stop()

func _on_set_idle_animation_on_phone_timer_timeout() -> void:
	_update_player_animations(true)
