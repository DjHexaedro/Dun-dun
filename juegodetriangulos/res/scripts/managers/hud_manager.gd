# Helper class with hud-related functions.
# Can be accessed from anywhere within the project
extends Node


const LIFEBAR_X_SCALE = 20.3
const SCORE_LABEL_POSITION_DEFAULT = Vector2(1915, 95)
const SCORE_LABEL_POSITION_ONSCREEN_JOYSTICK = Vector2(1810, 95)
const HUD_JOYSTICK_LEFT_POSITION = Vector2(240, 840)
const HUD_JOYSTICK_RIGHT_POSITION = Vector2(1680, 840)

var hud: Node = null
var dpad_is_enabled: bool
var score_label_position: Vector2
var marker_list: Array = []
var current_fps_update_timer: Timer
var enemy_lifebar: Sprite
var joystick_bg: Sprite

onready var hudscene = preload("res://juegodetriangulos/scenes/level_assets/generic/hud.tscn")
onready var onscreenhudscene = preload("res://juegodetriangulos/scenes/level_assets/generic/onscreen_controls_hud.tscn")
onready var markerscene = preload("res://juegodetriangulos/scenes/level_assets/generic/boss_phase_lifebar_marker.tscn")

func enable_hud() -> void:
	if not hud:
		marker_list = []
		if Utils.device_is_phone():
			hud = onscreenhudscene.instance()
			score_label_position = SCORE_LABEL_POSITION_ONSCREEN_JOYSTICK
			joystick_bg = hud.get_node("joystick_bg")
		else:
			hud = hudscene.instance()
			score_label_position = SCORE_LABEL_POSITION_DEFAULT
			joystick_bg = hud.get_node("joystick_bg")
			manage_hud_joystick(Settings.get_config_parameter("input_method") == Globals.InputTypes.ONSCREEN_JOYSTICK)
		set_phase_markers()
		get_tree().get_root().add_child(hud)
		show_fps_label(Settings.get_config_parameter("show_fps", false))
		current_fps_update_timer = Timer.new()
		current_fps_update_timer.set_wait_time(1)
		current_fps_update_timer.set_one_shot(false)
		get_tree().get_root().add_child(current_fps_update_timer)
		current_fps_update_timer.connect("timeout", self, "_on_current_fps_update_timer_timeout")
		current_fps_update_timer.start()
		enemy_lifebar = hud.get_node("lifebar")
		move_hud_joystick(Settings.get_config_parameter("onscreen_joystick_right"))

func reset_hud() -> void:
	if is_instance_valid(hud):
		update_enemy_health(EnemyManager.get_enemy_current_damage_taken(), EnemyManager.get_enemy_current_boss_phase(), EnemyManager.get_enemy_max_health())
		update_player_health(PlayerManager.get_player_max_health())
		update_current_score(0)

func disable_hud() -> void:
	if is_instance_valid(hud):
		current_fps_update_timer.queue_free()
		hud.queue_free()
		hud = null

func show_fps_label(visible: bool) -> void:
	if is_instance_valid(hud):
		hud.get_node("current_fps").set_visible(visible)

func move_hud_joystick(to_the_right: bool = false) -> void:
	if is_instance_valid(hud):
		if to_the_right:
			joystick_bg.set_position(HUD_JOYSTICK_RIGHT_POSITION)
		else:
			joystick_bg.set_position(HUD_JOYSTICK_LEFT_POSITION)

func manage_hud_joystick(enabled: bool) -> void:
	if is_instance_valid(hud):
		joystick_bg.set_visible(enabled)
		joystick_bg.get_node("joystick").set_visible(enabled)

func get_score_label_position() -> Vector2:
	return score_label_position

func set_phase_markers() -> void:
	for marker in marker_list:
		marker.queue_free()
	marker_list = []
	var lifebar_decoration_node: Sprite = hud.get_node("lifebar_decoration")
	lifebar_decoration_node.get_node("boss_name").text = EnemyManager.get_enemy_name()
	var position_increment: float = lifebar_decoration_node.texture.get_size().x / 5
	for i in range(1, 5):
		var new_marker: Node = markerscene.instance()
		lifebar_decoration_node.add_child(new_marker)
		new_marker.position = Vector2(i * position_increment, lifebar_decoration_node.texture.get_size().y / 2)
		marker_list.append(new_marker)

func set_phase_markers_as_timer(timing_list: Array, total_time: float) -> void:
	for marker in marker_list:
		marker.queue_free()
	marker_list = []
	var lifebar_decoration_node: Node = hud.get_node("lifebar_decoration")
	for timing in timing_list:
		var new_marker: Node = markerscene.instance()
		var new_marker_x_position: float = lifebar_decoration_node.texture.get_size().x * (1 - (timing / total_time))
		lifebar_decoration_node.add_child(new_marker)
		new_marker.position = Vector2(new_marker_x_position, lifebar_decoration_node.texture.get_size().y / 2)
		marker_list.append(new_marker)


func update_enemy_health_as_timer(time_left: float, total_time: float) -> void:
	if is_instance_valid(hud):
		var scale_modifier: float = (1.0 - (time_left / total_time))
		var scale: float = LIFEBAR_X_SCALE * scale_modifier
		enemy_lifebar.scale.x = scale

func update_enemy_health(damage_received: int, current_boss_phase: int, max_health: int) -> void:
	if is_instance_valid(hud):
		var current_life_lost: float = 1000 * (current_boss_phase - 1)
		var total_life_lost: float = damage_received + current_life_lost
		var scale: float = LIFEBAR_X_SCALE * (max_health - total_life_lost) / max_health
		enemy_lifebar.scale.x = scale

func update_player_health(current_health: int) -> void:
	if is_instance_valid(hud):
		var heart_node: Node 
		for i in range(1, PlayerManager.get_player_max_health() + 1):
			heart_node = hud.get_node("player_life_container").get_node("heart%s" % i)
			heart_node.visible = i <= current_health

func update_current_score(new_score: int) -> void:
	if is_instance_valid(hud):
		hud.get_node("current_score").text = "Current score: %s" % new_score 

func _on_current_fps_update_timer_timeout() -> void:
	hud.get_node("current_fps").text = str(Engine.get_frames_per_second())
