# Base class for both the PC and Android options menu. It contains the logic
# common to both of them
extends CanvasLayer

class_name BaseOptionsMenu

signal master_volume_changed(new_volume)
signal music_volume_changed(new_volume)
signal effects_volume_changed(new_volume)
signal options_menu_exit

onready var save_button: Button = $save_button
onready var tabs_container: TabContainer = $tabs_container
onready var master_volume_current_value_label: Label = $tabs_container/Audio/master_volume/current_value
onready var music_volume_current_value_label: Label = $tabs_container/Audio/music_volume/current_value
onready var effects_volume_current_value_label: Label = $tabs_container/Audio/effects_volume/current_value

const CONTROLS_TO_LOAD_GROUP: String = "control_to_load"


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and tabs_container.visible:
		_on_save_button_pressed()

func show_options_menu() -> void:
	GameStateManager.set_on_options_menu(true)
	tabs_container.visible = true 
	save_button.visible = true 

func hide_options_menu() -> void:
	GameStateManager.set_on_options_menu(false)
	tabs_container.visible = false
	save_button.visible = false

func _on_master_volume_value_changed(value: float) -> void:
	master_volume_current_value_label.set_text(str(value * 100))
	emit_signal("master_volume_changed", value)

func _on_music_volume_value_changed(value: float) -> void:
	music_volume_current_value_label.set_text(str(value * 100))
	emit_signal("music_volume_changed", value)

func _on_effects_volume_value_changed(value: float) -> void:
	effects_volume_current_value_label.set_text(str(value * 100))
	emit_signal("effects_volume_changed", value)

func _on_save_button_pressed() -> void:
	hide_options_menu()
	yield(Utils.wait(0.1), "timeout")
	emit_signal("options_menu_exit")
