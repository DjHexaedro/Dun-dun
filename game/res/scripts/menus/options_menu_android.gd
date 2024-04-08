# Functions used by the options menu in the Android version
extends BaseOptionsMenu 

func _ready() -> void:
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
	var sections_dict = {"input": {}}
	var tab_count = tabs_container.get_child_count()
	var c = 0
	while c < tab_count:
		var tab_name = tabs_container.get_tab_title(c)
		var control_list = tabs_container.get_node(tab_name).get_children()
		var keybind_dict = {}
		for control in control_list:
			if not "label" in control.name:
				if control is CheckBox:
					if "onscreen_joystick" in control.name:
						sections_dict["input"][control.name] = control.pressed
					else:
						keybind_dict[control.name] = control.pressed
				elif control is HSlider:
					if "onscreen_joystick" in control.name:
						sections_dict["input"][control.name] = control.value
					else:
						keybind_dict[control.name] = control.value
				elif control is Button:
					keybind_dict[control.name] = control.text
		sections_dict[tab_name.to_lower()] = keybind_dict
		c += 1
	Settings.save_to_config_file(sections_dict)
	hide_options_menu()
