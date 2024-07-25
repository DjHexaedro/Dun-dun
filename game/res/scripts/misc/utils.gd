# Script with a lot of different, useful functions to help reuse code.
# Can be accessed from anywhere within the project
extends Node


const EFFECTS_AUDIO_BUS: String = "Effects"
const MUSIC_AUDIO_BUS: String = "BGM Base"
const MASTER_AUDIO_BUS: String = "Master"

onready var messagescene: PackedScene = preload("res://juegodetriangulos/scenes/level_assets/generic/message_label.tscn")
onready var optionsmenuscene: PackedScene = preload("res://juegodetriangulos/scenes/menu/options_menu.tscn")
onready var optionsmenuandroidscene: PackedScene = preload("res://juegodetriangulos/scenes/menu/options_menu_android.tscn")

var timer: Timer = Timer.new()
var label_list: Array = []
var main_node: Node
var options_menu: CanvasLayer 
var extra_challenges_container: Panel 
var dialog_box: CanvasLayer
var pause_menu: CanvasLayer
var message_node = null

func _ready() -> void:
	main_node = get_tree().get_root().get_node("Main")
	extra_challenges_container = main_node.get_node("extra_challenges_menu").get_node("container")
	dialog_box = main_node.get_node("dialog_box")
	pause_menu = main_node.get_node("pause_menu")
	if device_is_phone():
		options_menu = optionsmenuandroidscene.instance()
	else:
		options_menu = optionsmenuscene.instance()
	main_node.add_child(options_menu)
	options_menu.connect("master_volume_changed", self, "set_current_master_volume")
	options_menu.connect("music_volume_changed", self, "set_current_music_volume")
	options_menu.connect("effects_volume_changed", self, "set_current_effects_volume")
	set_audio_bus_volume(MASTER_AUDIO_BUS, Settings.get_config_parameter("master_volume"))
	set_audio_bus_volume(MUSIC_AUDIO_BUS, Settings.get_config_parameter("music_volume"))
	set_audio_bus_volume(EFFECTS_AUDIO_BUS, Settings.get_config_parameter("effects_volume"))
	add_child(timer)

func get_main_node() -> Node:
	return main_node

func get_options_menu() -> CanvasLayer:
	return options_menu

func get_main_menu() -> Node:
	return main_node.main_menu_canvas

func get_pause_menu() -> CanvasLayer:
	return pause_menu

func enable_pause_node() -> void:
	pause_menu.enabled = true

func disable_pause_node() -> void:
	pause_menu.enabled = false

func show_extra_challenges_screen() -> void:
	yield(get_tree().create_timer(0.1), "timeout")
	extra_challenges_container.show()

func update_extra_challenges_options(boss_id: int) -> void:
	main_node.get_node("extra_challenges_menu").switch_challenges(boss_id)

func get_main_attack_timer() -> Node:
	return main_node.get_node("main_attack_timer")

func get_secondary_attack_timer() -> Node:
	return main_node.get_node("secondary_attack_timer")

func wait(time_to_wait: float, one_shot: bool = true) -> Timer:
	timer.set_wait_time(time_to_wait)
	timer.set_one_shot(one_shot)
	timer.start()
	return timer

func show_dialog_box(dialog_list: Array) -> void:
	dialog_box.show_dialog_box(dialog_list)

func hide_dialog_box() -> void:
	dialog_box.hide_dialog_box()

func is_dialog_box_visible() -> bool:
	return dialog_box.visible

func show_message(message: String = "") -> void:
	if not message_node:
		message_node = messagescene.instance()
		get_tree().get_root().add_child(message_node)
	if message:
		message_node.get_node("message_label").text = message

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

func is_difficulty_normal() -> bool:
	return (
		GameStateManager.get_difficulty_level() == Globals.DifficultyLevels.NORMAL
	)

func is_difficulty_hard() -> bool:
	return (
		GameStateManager.get_difficulty_level() == Globals.DifficultyLevels.HARD
	)

func is_difficulty_hardest() -> bool:
	return (
		GameStateManager.get_difficulty_level() == Globals.DifficultyLevels.HARDEST
	)

# No return value type (both actual return value and return_value parameter)
# because they can both be any type
func log_error(log_message: String, return_value = false):
	if GameStateManager.debug:
		print(log_message)
	return return_value
