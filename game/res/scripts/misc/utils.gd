# Script with a lot of different, useful functions to help reuse code.
# Can be accessed from anywhere within the project
extends Node


const SCORE_LABEL_POSITION: Vector2 = Vector2(1910, 95)
const EFFECTS_AUDIO_BUS: String = "Effects"
const MUSIC_AUDIO_BUS: String = "BGM"
const MASTER_AUDIO_BUS: String = "Master"

onready var labelscene: PackedScene = preload("res://juegodetriangulos/scenes/level_assets/generic/score_label.tscn")
onready var messagescene: PackedScene = preload("res://juegodetriangulos/scenes/level_assets/generic/message_label.tscn")
onready var optionsmenuscene: PackedScene = preload("res://juegodetriangulos/scenes/menu/options_menu.tscn")
onready var optionsmenuandroidscene: PackedScene = preload("res://juegodetriangulos/scenes/menu/options_menu_android.tscn")

var timer: Timer = Timer.new()
var label_list: Array = []

func _ready() -> void:
	var options_menu: CanvasLayer 
	if device_is_phone():
		options_menu = optionsmenuandroidscene.instance()
	else:
		options_menu = optionsmenuscene.instance()
	get_tree().get_root().get_node("Main").add_child(options_menu)
	options_menu.connect("master_volume_changed", self, "set_current_master_volume")
	options_menu.connect("music_volume_changed", self, "set_current_music_volume")
	options_menu.connect("effects_volume_changed", self, "set_current_effects_volume")
	set_audio_bus_volume(MASTER_AUDIO_BUS, Settings.get_config_parameter("master_volume"))
	set_audio_bus_volume(MUSIC_AUDIO_BUS, Settings.get_config_parameter("music_volume"))
	set_audio_bus_volume(EFFECTS_AUDIO_BUS, Settings.get_config_parameter("effects_volume"))
	add_child(timer)

func enable_pause_node() -> void:
	get_tree().get_root().get_node("Main").get_node("pause_menu").enabled = true

func disable_pause_node() -> void:
	get_tree().get_root().get_node("Main").get_node("pause_menu").enabled = false

func show_map_node() -> void:
	get_tree().get_root().get_node("map").show()

func hide_map_node() -> void:
	get_tree().get_root().get_node("map").hide()

func set_map_current_level_node(level_node: Node) -> void:
	get_tree().get_root().get_node("map").current_level_node = level_node

func get_map_current_level_node() -> Node:
	return get_tree().get_root().get_node("map").current_level_node

func set_level_max_score(new_score: int) -> void:
	get_tree().get_root().get_node("map").current_level_node.set_max_score(new_score)

func get_level_max_score() -> int:
	return get_tree().get_root().get_node("map").current_level_node.max_score

func show_extra_challenges_screen() -> void:
	get_tree().get_root().get_node("Main").get_node("extra_challenges_menu").get_node("container").show()

func wait(time_to_wait: float, one_shot: bool = true) -> Timer:
	timer.set_wait_time(time_to_wait)
	timer.set_one_shot(one_shot)
	timer.start()
	return timer

func show_message(message: String = "") -> void:
	var message_node = messagescene.instance()
	if message:
		message_node.get_node("message_label").text = message
	get_tree().get_root().add_child(message_node)

func show_score(score: int) -> void:
	var label = labelscene.instance()
	label.get_node("score_label").text = str(score)
	label.get_node("score_label").rect_position = HudManager.get_score_label_position()
	get_tree().get_root().add_child(label)
	label_list.append(label)

func remove_score_labels() -> void:
	for label in label_list:
		var ref = weakref(label)
		if ref.get_ref():
			label.queue_free()
	label_list = []

func set_current_master_volume(new_volume: float) -> void:
	set_audio_bus_volume(MASTER_AUDIO_BUS, new_volume)

func set_current_music_volume(new_volume: float) -> void:
	set_audio_bus_volume(MUSIC_AUDIO_BUS, new_volume)

func set_current_effects_volume(new_volume: float) -> void:
	set_audio_bus_volume(EFFECTS_AUDIO_BUS, new_volume)

func set_audio_bus_volume(audio_bus_name: String, new_volume: float):
	var audio_server_index: int = AudioServer.get_bus_index(audio_bus_name)
	AudioServer.set_bus_volume_db(audio_server_index, linear2db(new_volume))

func hide_mouse_if_necessary() -> void:
	if not Settings.get_config_parameter("input_method") == Globals.InputTypes.ONSCREEN_JOYSTICK:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func show_mouse_if_necessary() -> void:
	if not Settings.get_config_parameter("input_method") == Globals.InputTypes.ONSCREEN_JOYSTICK:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func device_is_phone() -> bool:
	return OS.get_name() in ["Android", "iOS"]

# No return value type (both actual return value and return_value parameter)
# because they can both be any type
func log_error(log_message: String, return_value = false):
	if GameStateManager.debug:
		print(log_message)
	return return_value
