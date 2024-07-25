# Base class for each different gameplay experience the player can play. It
# contains methods that should be used by most if not all of them.
extends Area2D

class_name BasePlayer

signal player_begin_death
signal player_death
signal player_hit

export (int) var BASE_SPEED
export (int) var BASE_HEALTH
export (float) var HIT_DELAY


onready var revive_heart_scene: PackedScene = preload(
	"res://juegodetriangulos/scenes/level_assets/generic/revive_player_heart.tscn"
)
onready var heal_heart_scene: PackedScene = preload(
	"res://juegodetriangulos/scenes/level_assets/generic/health_refill.tscn"
)
onready var player_corpse_scene: PackedScene = preload(
	"res://juegodetriangulos/scenes/level_assets/generic/corpse.tscn"
)

onready var got_healed_sound: AudioStreamPlayer = $got_healed_sound
onready var got_hit_sound: AudioStreamPlayer = $got_hit_sound
onready var light: Light2D = $light
onready var hitbox_marker_sprite: Sprite = $hitbox_marker
onready var blink_timer: Timer = $blink_timer
onready var can_get_hit_timer: Timer = $can_get_hit_timer
onready var unblink_timer: Timer = $unblink_timer

var GRAPHICS_DEFAULT_COLOR: Color = Color(1, 1, 1, 1)
var GRAPHICS_WALKING_COLOR: Color = Color(0, 0, 0, 0.25)
const LIGHT_DECREASE_STEP_AMOUNT: float = 3.0
const STOP_GET_HIT_IF_MOVING_TIMER_TIME: float = 0.075
const TIME_TO_GET_HIT_IF_STANDING_STILL: float = 3.0
const TIME_TO_GET_HIT_IF_MOVING: float = 1.0
const TOTAL_LIGHT_HORIZONTAL_MOVEMENT: float = -6.0
const TOTAL_LIGHT_VERTICAL_MOVEMENT: float = 12.0
const IDLE_ANIMATION_NAME: String = "idle_animation"
const MOVING_ANIMATION_NAME: String = "moving_animation"
const DEATH_ANIMATION_NAME: String = "death_animation"
const LIGHT_FADE_ANIMATION_NAME: String = "light_fade_animation"

# These action names are defined under Project > Project Settings > Input Mapping
var action_walk: String = "player%s_walk"
var action_moveup: String  = "player%s_moveup"
var action_movedown: String  = "player%s_movedown"
var action_moveleft: String  = "player%s_moveleft"
var action_moveright: String  = "player%s_moveright"

# Animations
var animation_list: Node2D
var death_animation: AnimatedSprite
var idle_animation: AnimatedSprite
var light_fade_animation: AnimatedSprite
var moving_animation: AnimatedSprite

var current_health: int
var can_get_hit: int
var invencible: bool
var velocity: Vector2 = Vector2.ZERO
var old_position: Vector2
var current_score: int = 0
var play_wall_bump_sound: bool = true
var enable_input: bool = false
var get_hit_if_standing_still_timer: Timer
var get_hit_if_moving_timer: Timer
var got_healed_audio_list: Array = [
	load("res://juegodetriangulos/res/music/get_health_sfx0.wav"),
	load("res://juegodetriangulos/res/music/get_health_sfx1.wav"),
]
var initial_light_scale: float
var light_on_death_texture_decrement: float
var light_on_death_position_horizontal_movement: float =\
	TOTAL_LIGHT_HORIZONTAL_MOVEMENT / LIGHT_DECREASE_STEP_AMOUNT
var light_on_death_position_vertical_movement: float =\
	TOTAL_LIGHT_VERTICAL_MOVEMENT / LIGHT_DECREASE_STEP_AMOUNT
var player_id: int = -1
var alive: bool = true
var walk_default: bool
var always_show_hitbox: bool = false
var player_type: String = Globals.LevelCodes.GENERIC
var is_ghost: bool = false
var player_corpse: Node2D 
var is_light_enabled: bool = true

func set_player_id(new_player_id: int) -> void:
	player_id = new_player_id

	var animation_list_name: String = "animation_list%s" % player_id
	animation_list = get_node(animation_list_name)
	animation_list.show()
	death_animation = animation_list.get_node(DEATH_ANIMATION_NAME)
	idle_animation = animation_list.get_node(IDLE_ANIMATION_NAME)
	light_fade_animation = animation_list.get_node(LIGHT_FADE_ANIMATION_NAME)
	moving_animation = animation_list.get_node(MOVING_ANIMATION_NAME)
	update_idle_animation_speed(PlayerManager.get_player_health())

	for player in range(PlayerManager.get_number_of_players()):
		if player != player_id:
			get_node("animation_list%s" % player).hide()

	var is_input_method_controller: bool = (
		Settings.get_config_parameter("input_method") == Globals.InputTypes.CONTROLLER
	)
	if player_id != Globals.PlayerIDs.PLAYER_ONE:
		var n_of_controllers: int = len(Input.get_connected_joypads())
		if is_input_method_controller:
			if n_of_controllers > 1:
				set_controller_actions()
			else:
				set_keyboard_actions(Globals.PlayerIDs.PLAYER_ONE)
		else:
			if n_of_controllers > 0:
				set_controller_actions(Globals.PlayerIDs.PLAYER_ONE)
			else:
				set_keyboard_actions()
	else:
		set_keyboard_actions()
		if is_input_method_controller:
			set_controller_actions()
	enable_input = true

func get_player_id() -> int:
	return player_id

func _ready() -> void:
	old_position = position
	can_get_hit = true
	can_get_hit_timer.set_wait_time(HIT_DELAY)
	current_health = BASE_HEALTH

	initial_light_scale = light.texture_scale
	light_on_death_texture_decrement =\
			light.texture_scale / LIGHT_DECREASE_STEP_AMOUNT

	Settings.connect("settings_file_changed", self, "_on_settings_file_changed")

	if GameStateManager.get_standing_still_does_damage():
		get_hit_if_standing_still_timer = Timer.new()
		get_hit_if_standing_still_timer.set_wait_time(
			TIME_TO_GET_HIT_IF_STANDING_STILL
		)
		get_hit_if_standing_still_timer.set_one_shot(false)
		add_child(get_hit_if_standing_still_timer)
		get_hit_if_standing_still_timer.connect(
			"timeout", self, "get_hit", [self]
		)

	if GameStateManager.get_moving_does_damage():
		get_hit_if_moving_timer = Timer.new()
		get_hit_if_moving_timer.set_wait_time(TIME_TO_GET_HIT_IF_MOVING)
		get_hit_if_moving_timer.set_one_shot(false)
		add_child(get_hit_if_moving_timer)
		get_hit_if_moving_timer.connect("timeout", self, "get_hit", [self])
	
	Utils.get_pause_menu().connect("game_paused", self, "_on_game_paused")

func _flip_player_animations(flipped: bool, vertical_only: bool) -> void:
	if vertical_only:
		moving_animation.flip_h = flipped
	else:
		for animation in animation_list.get_children():
			animation.flip_h = flipped

func _update_player_animations(idle: bool) -> void:
	idle_animation.visible = idle
	idle_animation.playing = idle
	moving_animation.visible = not idle
	moving_animation.playing = not idle

func _reset_common() -> void:
	_update_player_animations(true)
	light_fade_animation.visible = false
	light_fade_animation.stop()
	light_fade_animation.set_frame(0)
	death_animation.visible = false
	death_animation.stop()
	death_animation.set_frame(0)
	light.texture_scale = initial_light_scale
	light.position = Vector2.ZERO
	invencible = false
	enable_input = true
	update_idle_animation_speed(current_health)
	if player_corpse:
		player_corpse.queue_free()

func reset() -> void:
	alive = true
	old_position = position
	can_get_hit = true
	current_health = BASE_HEALTH
	update_idle_animation_speed(BASE_HEALTH)
	current_score = 0
	position = ArenaManager.get_arena_center()
	idle_animation.hide()
	moving_animation.hide()
	idle_animation = animation_list.get_node(IDLE_ANIMATION_NAME)
	moving_animation = animation_list.get_node(MOVING_ANIMATION_NAME)
	_reset_common()

func revive() -> void:
	alive = true
	can_get_hit = false
	can_get_hit_timer.start()
	blink_timer.start()
	GameStateManager.update_match_history(Globals.MatchEvents.PLAYER_REVIVE, player_id)
	_reset_common()

func get_hit(dmg_source: Object, dmg: int = 1):
	if not invencible:
		if (
			not "limit" in dmg_source.name or
			GameStateManager.get_edge_touching_does_damage()
		) and can_get_hit:
			PlayerManager.player_lose_health(dmg)
			if GameStateManager.get_debug():
				print(
					'Player got hit by %s. Current health: %s' %
					[dmg_source.name, current_health]
				)
			got_hit_sound.play()
			emit_signal("player_hit")
			if PlayerManager.get_player_health() <= 0:
				death()
			else:
				can_get_hit = false
				can_get_hit_timer.start()
				blink_timer.start()
				GameStateManager.update_match_history(
					Globals.MatchEvents.PLAYER_HIT, player_id
				)

func get_healed(heal_amount: int = 1):
	var health_refill: AnimatedSprite = heal_heart_scene.instance()
	add_child(health_refill)
	health_refill.spawn()
	yield(health_refill, "player_healed")

	PlayerManager.player_increase_health(heal_amount)
	if GameStateManager.get_debug():
		print(
			'Player got healed by %s point(s). Current health: %s' %
			[heal_amount, current_health]
		)

	got_healed_sound.stream = got_healed_audio_list[randi()%2]
	got_healed_sound.play()

func death() -> void:
	invencible = true
	enable_input = false
	alive = false
	PlayerManager.set_player_velocity(Vector2.ZERO, player_id)
	GameStateManager.update_match_history(Globals.MatchEvents.PLAYER_DEATH, player_id)
	Settings.increase_game_statistic("deaths", 1)
	animation_list.modulate = GRAPHICS_DEFAULT_COLOR
	idle_animation.visible = false
	moving_animation.visible = false
	death_animation.visible = true 
	death_animation.play()

func manage_light(on: bool) -> void:
	light.visible = on
	is_light_enabled = on

# Again, all these action names are defined under:
# Project > Project Settings > Input Mapping
func set_controller_actions(player_id_to_use: int = player_id) -> void:
	action_walk = "player%s_walk_controller" % player_id_to_use
	action_moveup = "player%s_moveup_controller" % player_id_to_use
	action_movedown = "player%s_movedown_controller" % player_id_to_use
	action_moveleft = "player%s_moveleft_controller" % player_id_to_use
	action_moveright = "player%s_moveright_controller" % player_id_to_use

func set_keyboard_actions(player_id_to_use: int = player_id) -> void:
	action_walk = "player%s_walk" % player_id_to_use
	action_moveup = "player%s_moveup" % player_id_to_use
	action_movedown = "player%s_movedown" % player_id_to_use
	action_moveleft = "player%s_moveleft" % player_id_to_use
	action_moveright = "player%s_moveright" % player_id_to_use

func _allow_input() -> bool:
	return (
		visible and
		enable_input and
		not Utils.device_is_phone() and
		Settings.get_config_parameter("input_method") !=\
				Globals.InputTypes.ONSCREEN_JOYSTICK
	)

func instance_player_ghost() -> void:
	player_corpse = player_corpse_scene.instance()
	get_tree().get_root().add_child(player_corpse)
	player_corpse.set_global_position(global_position)
	player_corpse.set_player_revive_position(global_position)
	player_corpse.set_player_corpse_graphics(player_id, light_fade_animation.flip_h)
	is_ghost = true 
	enable_input = true 
	idle_animation = animation_list.get_node("ghost_%s" % IDLE_ANIMATION_NAME)
	moving_animation = animation_list.get_node("ghost_%s" % MOVING_ANIMATION_NAME)
	light_fade_animation.hide()
	idle_animation.show()

func instance_revive_heart() -> void:
	var revive_heart = revive_heart_scene.instance()
	get_tree().get_root().add_child(revive_heart)
	revive_heart.spawn(self)

func unload() -> void:
	if player_corpse and is_instance_valid(player_corpse):
		player_corpse.queue_free()
	queue_free()

func update_idle_animation_speed(current_health: int) -> void:
	idle_animation.speed_scale = [3, 2, 1, 0.5][current_health]

func can_be_hit() -> bool:
	# Function used to decide if a bullet should disapper when colliding with a
	# player. By default this happens if the player is alive. Note that this
	# doesn't mean they'll receive damage (that'll be checked inside the
	# get_hit() function)
	return alive

func _on_can_get_hit_timer_timeout() -> void:
	can_get_hit = true
	blink_timer.stop()
	unblink_timer.stop()
	animation_list.visible = true

func _on_blink_timer_timeout() -> void:
	animation_list.visible = false
	unblink_timer.start()

func _on_unblink_timer_timeout() -> void:
	animation_list.visible = true
	blink_timer.start()

func _on_update_old_position_timer_timeout() -> void:
	old_position = position

func _on_light_fade_animation_frame_changed():
	light.texture_scale -= light_on_death_texture_decrement
	light.position += Vector2(
		light_on_death_position_horizontal_movement,
		light_on_death_position_vertical_movement
	)

func _on_death_animation_animation_finished() -> void:
	if PlayerManager.all_players_are_dead():
		emit_signal("player_begin_death")
	death_animation.visible = false
	light_fade_animation.visible = true
	light_fade_animation.play()

func _on_light_fade_animation_animation_finished():
	light_fade_animation.stop()
	if GameStateManager.get_multiplayer_enabled():
		instance_player_ghost()
	if PlayerManager.all_players_are_dead():
		emit_signal("player_death")

# Triggers when a change is made in the options menu and updates
# the character accordingly
func _on_settings_file_changed() -> void:
	walk_default = Settings.get_config_parameter("walk_default")
	always_show_hitbox = Settings.get_config_parameter("always_show_hitbox")
	hitbox_marker_sprite.visible = always_show_hitbox
	animation_list.modulate =\
		GRAPHICS_WALKING_COLOR if always_show_hitbox else GRAPHICS_DEFAULT_COLOR
	_update_input_method(Settings.get_config_parameter("input_method"))

func _update_input_method(input_method: int) -> void:
	if player_id == Globals.PlayerIDs.PLAYER_ONE:
		if input_method == Globals.InputTypes.KEYBOARD:
			set_keyboard_actions()
		elif input_method == Globals.InputTypes.CONTROLLER:
			set_controller_actions()
	else:
		var n_of_controllers: int = len(Input.get_connected_joypads())
		if input_method == Globals.InputTypes.CONTROLLER:
			if n_of_controllers > 1:
				set_controller_actions()
			else:
				set_keyboard_actions(Globals.PlayerIDs.PLAYER_ONE)
		else:
			if n_of_controllers > 0:
				set_controller_actions(Globals.PlayerIDs.PLAYER_ONE)
			else:
				set_keyboard_actions()

func _on_game_paused(paused: bool) -> void:
	set_process_input(not paused)
