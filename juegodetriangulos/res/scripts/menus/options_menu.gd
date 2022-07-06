# Functions used by the options menu in the PC version
extends BaseOptionsMenu

signal options_menu_exit

onready var controller_controls_control: Control = $tabs_container/Input/controller_controls
onready var keyboard_controls_control: Control = $tabs_container/Input/keyboard_controls
onready var onscreen_joystick_controls_control: Control = $tabs_container/Input/onscreen_joystick_controls
onready var input_method_option_button: OptionButton = $tabs_container/Input/input_method

func _ready() -> void:
	# Input method OptionButton
	input_method_option_button.add_item("Keyboard")
	input_method_option_button.add_item("Controller")
	input_method_option_button.add_item("Onscreen joystick")
	input_method_option_button.select(int(Settings.get_config_parameter(input_method_option_button.get_name())))
	_on_input_method_item_selected(int(Settings.get_config_parameter(input_method_option_button.get_name())))

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
			if not "label" in control.name:
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
						if not "label" in input.name:
							if input is CheckBox:
								keybind_dict[input.name] = input.pressed
							elif input is HSlider:
								keybind_dict[input.name] = input.value
							else:
								keybind_dict[input.name] = input.text
		sections_dict[tab_name.to_lower()] = keybind_dict
		c += 1
	Settings.save_to_config_file(sections_dict)
	hide_options_menu()
	emit_signal("options_menu_exit")

func _on_input_method_item_selected(index: int) -> void:
	if index == Globals.InputTypes.KEYBOARD:
		keyboard_controls_control.show()
		controller_controls_control.hide()
		onscreen_joystick_controls_control.hide()
	elif index == Globals.InputTypes.CONTROLLER:
		keyboard_controls_control.hide()
		controller_controls_control.show()
		onscreen_joystick_controls_control.hide()
	elif index == Globals.InputTypes.ONSCREEN_JOYSTICK:
		keyboard_controls_control.hide()
		controller_controls_control.hide()
		onscreen_joystick_controls_control.show()
