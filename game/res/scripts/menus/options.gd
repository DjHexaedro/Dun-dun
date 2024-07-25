# Functions used by the options menu in the PC version
extends BaseOptionsMenu

onready var controller_controls_control: Control = $tabs_container/Input/controller_controls
onready var keyboard_controls_control: Control = $tabs_container/Input/keyboard_controls
onready var onscreen_joystick_controls_control: Control = $tabs_container/Input/onscreen_joystick_controls
onready var input_method_option_button: OptionButton = $tabs_container/Input/input_method
onready var selected_option_marker_sprite: Sprite = $selected_option_marker

var options_list: Array = [[], [], []]
var current_option: int = 0
var current_tab: int = 0
var ignore_next_ui_accept: bool = false

func _ready() -> void:
	# Input method OptionButton
	input_method_option_button.add_item("Keyboard")
	input_method_option_button.add_item("Controller")
	input_method_option_button.select(int(
		Settings.get_config_parameter(input_method_option_button.get_name())
	))
	_on_input_method_item_selected(int(
		Settings.get_config_parameter(input_method_option_button.get_name())
	))

	# Load value stored in the config file into the corresponding control.
	# Uses the controls' groups to know which to load and which property
	# to update (pressed for checkboxes, value for HSliders, etc)
	var child_group_list: Array
	var property_name: String
	for child in get_tree().get_nodes_in_group(Globals.OPTIONS_MENU_CONTROLS_TO_LOAD_GROUP):
		child_group_list = child.get_groups()
		child_group_list.erase(Globals.OPTIONS_MENU_CONTROLS_TO_LOAD_GROUP)
		property_name = child_group_list[0]
		child.set(property_name, Settings.get_config_parameter(child.get_name()))
	
	options_list[0] = [
		$tabs_container/General/fullscreen,
		$tabs_container/General/walk_default,
		$tabs_container/General/always_show_hitbox,
		$tabs_container/General/show_fps,
		$tabs_container/General/multiplayer_enabled,
	]
	options_list[1] = [
		$tabs_container/Audio/master_volume,
		$tabs_container/Audio/music_volume,
		$tabs_container/Audio/effects_volume,
	]
	options_list[2] = [
		$tabs_container/Input/keyboard_controls/player_moveup,
		$tabs_container/Input/keyboard_controls/player_movedown,
		$tabs_container/Input/keyboard_controls/player_moveleft,
		$tabs_container/Input/keyboard_controls/player_moveright,
		$tabs_container/Input/keyboard_controls/player_walk,
	]

func _input(event: InputEvent) -> void:
	if tabs_container.visible:
		._input(event)
		if event is InputEventMouseButton:
			selected_option_marker_sprite.visible = false
			current_tab = tabs_container.current_tab
		elif (
			event is InputEventKey or
			event is InputEventJoypadMotion or
			event is InputEventJoypadButton
		):
			if event.is_action_pressed("ui_focus_prev", false, true):
				current_tab -= 1
				if current_tab < 0:
					current_tab = len(options_list) - 1
			if event.is_action_pressed("ui_focus_next", false, true):
				current_tab += 1
				if current_tab > len(options_list) - 1:
					current_tab = 0
			if event.is_action_pressed("ui_up"):
				current_option -= 1
				if current_option < 0:
					current_option = len(options_list[current_tab]) - 1
			if event.is_action_pressed("ui_down"):
				current_option += 1
				if current_option > len(options_list[current_tab]) - 1:
					current_option = 0

			move_marker()

			var current_control = options_list[current_tab][current_option]
			if event.is_action_pressed("ui_left", true) and current_control is HSlider:
				current_control.value -= 0.01
			elif event.is_action_pressed("ui_right", true) and current_control is HSlider:
				current_control.value += 0.01

			if event.is_action_pressed("ui_accept") and not ignore_next_ui_accept:
				if current_control is CheckBox:
					current_control.pressed = not current_control.pressed
				elif current_control is Button:
					yield(Utils.wait(0.1), "timeout")
					ignore_next_ui_accept = true
					current_control.emit_signal("pressed")
			elif ignore_next_ui_accept:
				ignore_next_ui_accept = false

func move_marker() -> void:
	if tabs_container.visible:
		if tabs_container.current_tab != current_tab:
			tabs_container.current_tab = current_tab
			current_option = 0
		selected_option_marker_sprite.visible = true 
		selected_option_marker_sprite.global_position.y =\
			options_list[current_tab][current_option].rect_global_position.y +\
			(options_list[current_tab][current_option].rect_size.y / 2)

func show_options_menu() -> void:
	.show_options_menu()
	selected_option_marker_sprite.visible = true

func hide_options_menu() -> void:
	.hide_options_menu()
	selected_option_marker_sprite.visible = false 

func _on_save_button_pressed() -> void:
	var sections_dict: Dictionary = {}
	var tab_count: int = tabs_container.get_child_count()
	var c: int = 0
	var tab_name: String
	var control_list: Array
	var keybind_dict: Dictionary
	while c < tab_count:
		tab_name = tabs_container.get_tab_title(c)
		control_list = tabs_container.get_node(tab_name).get_children()
		keybind_dict = {}

		for control in control_list:
			if control is CheckBox:
				keybind_dict[control.name] = control.pressed
			elif control is HSlider:
				keybind_dict[control.name] = control.value
			elif control is OptionButton:
				keybind_dict[control.name] = control.get_selected_id()
			elif control is Button:
				keybind_dict[control.name] = control.text
			elif control is Control:
				var input_list: Array = control.get_children()
				for input in input_list:
					if input is CheckBox:
						keybind_dict[input.name] = input.pressed
					elif input is HSlider:
						keybind_dict[input.name] = input.value
					elif input is Button:
						keybind_dict[input.name] = input.text

		sections_dict[tab_name.to_lower()] = keybind_dict
		c += 1
	Settings.save_to_config_file(sections_dict)
	._on_save_button_pressed()

func _on_input_method_item_selected(index: int) -> void:
	keyboard_controls_control.visible = index == Globals.InputTypes.KEYBOARD
	controller_controls_control.visible = index == Globals.InputTypes.CONTROLLER

