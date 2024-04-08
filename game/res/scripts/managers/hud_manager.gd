# Helper class with hud-related functions.
# Can be accessed from anywhere within the project
extends Node


var hud: Node
var fps_label: Label
var current_fps_update_timer: Timer


func _ready() -> void:
	hud = Utils.get_main_node().get_node("hud")
	fps_label = hud.get_node("current_fps")

	if not Utils.device_is_phone():
		hud.get_node("pause_menu").queue_free()
	
	manage_fps_label()
	Settings.connect("settings_file_changed", self, "manage_fps_label")

func enable_hud() -> void:
	hud.show()
	if Settings.get_config_parameter("show_fps", false):
		current_fps_update_timer.start()

func disable_hud() -> void:
	hud.hide()
	if Settings.get_config_parameter("show_fps", false):
		current_fps_update_timer.stop()

func manage_fps_label() -> void:
	fps_label.visible = Settings.get_config_parameter("show_fps", false)

	if Settings.get_config_parameter("show_fps", false):
		if not current_fps_update_timer:
			current_fps_update_timer = Timer.new()
			current_fps_update_timer.set_wait_time(1)
			current_fps_update_timer.set_one_shot(false)
			add_child(current_fps_update_timer)
			current_fps_update_timer.connect(
				"timeout", self, "_on_current_fps_update_timer_timeout"
			)
		current_fps_update_timer.start()

	elif current_fps_update_timer:
		current_fps_update_timer.stop()

func _on_current_fps_update_timer_timeout() -> void:
	fps_label.text = str(Engine.get_frames_per_second())
