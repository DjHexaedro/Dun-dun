# Script that manages the settings file and allows other scripts to easily
# access its values. It also manages the save data, for some reason
# Can be accessed from anywhere within the project
extends Node

signal settings_file_changed

var save_data_file: File = File.new()
var save_data_file_path: String = "user://save_data.json"
var save_data: Dictionary = {}
var config: ConfigFile = ConfigFile.new()
var config_path: String = "user://settings.cfg"
var config_file_status: int = config.load(config_path)
var config_params_dict: Dictionary = {}

func _ready() -> void:
	if config_file_status != OK:
		create_default_config_file()
	load_config_file()
	get_saved_game_data()
	if not save_data:
		create_save_game_file()

func get_config_parameter(parameter_name: String, return_value = null):
	var current_parameter_value
	for section in config_params_dict:
		current_parameter_value = config_params_dict[section].get(parameter_name, null)
		if current_parameter_value != null:
			return current_parameter_value 
	return Utils.log_error("Parameter %s does not exist or is null" % parameter_name, return_value)

func create_save_game_file() -> void:
	save_data["deaths"] = 0
	save_data["selected_level"] = 0
	save_data["inside_level"] = false
	save_data["level_list"] = {}
	save_game_data()

func get_saved_game_data() -> void:
	save_data_file.open(save_data_file_path, File.READ)
	var saved_data_json = save_data_file.get_as_text()
	if parse_json(saved_data_json) == null:
		save_data = {}
	else:
		save_data = parse_json(saved_data_json)
	save_data_file.close()

func save_game_data() -> void:
	save_data_file.open(save_data_file_path, File.WRITE)
	save_data_file.store_string(to_json(save_data))
	save_data_file.close()

func save_game_statistic(statistic: String, value) -> void:
	save_data[statistic] = value
	save_game_data()

func increase_game_statistic(statistic: String, increment: int) -> void:
	if save_data.get(statistic, 0):
		save_data[statistic] += increment
	else:
		save_data[statistic] = increment
	save_game_data()

func get_game_statistic(statistic: String, default_value):
	return save_data.get(statistic, default_value)
	
func save_current_level_state(completed: bool, max_score: int, inside_level: bool) -> void:
	var map_node = get_tree().get_root().get_node("map")
	var selected_level = map_node.current_level_node
	var level_list_data = save_data["level_list"]
	var level_data = level_list_data.get(str(selected_level.get_path()), {})
	level_data["completed"] = completed
	level_data["max_score"] = max_score 
	save_data["level_list"][str(selected_level.get_path())] = level_data
	save_data["inside_level"] = inside_level
	save_data["selected_level"] = map_node.selected_level
	save_game_data()

func save_to_config_file(sections_dict: Dictionary) -> void:
	for section in sections_dict:
		var keybinds_dict = sections_dict[section]
		for bind in keybinds_dict:
			config.set_value(section, bind, keybinds_dict[bind])
	config.save(config_path)
	load_config_file()
	emit_signal("settings_file_changed")

func load_config_file() -> void:
	# Loads all the data in the config file into a dictionary for ease of use
	for section in config.get_sections():
		config_params_dict[section] = {}
		for section_key in config.get_section_keys(section):
			config_params_dict[section][section_key] = config.get_value(section, section_key)

	GameStateManager.set_debug(config_params_dict.get("misc", {}).get("debug", false))
	load_into_input_map()
	OS.set_window_fullscreen(config_params_dict.get("general", {}).get("fullscreen", false))
	HudManager.move_hud_joystick(config_params_dict.get("input", {}).get("onscreen_joystick_right", false))
	HudManager.show_fps_label(config_params_dict.get("general", {}).get("show_fps", false))

func load_into_input_map() -> void:
	# Loads all variables into the input map so they can actually be used
	var action_list = InputMap.get_actions()
	var new_input
	var new_key
	var keys_list
	for action in action_list:
		# Gets the variable with the same name as the action
		new_key = get_config_parameter(action)
		if new_key == null:
			# If it doesn't exists, it skips to the next action
			continue
		keys_list = InputMap.get_action_list(action)
		for key in keys_list:
			if key is InputEventKey:
				new_input = InputEventKey.new()
				# We need the scancode from the key, not the string, in order to actually
				# map it (i.e., we need 65, not "a")
				new_input.set_scancode(OS.find_scancode_from_string(new_key))
				InputMap.action_erase_event(action, key)
				InputMap.action_add_event(action, new_input)

func create_default_config_file() -> void:
	config.set_value("general", "fullscreen", true)
	config.set_value("general", "walk_default", false)
	config.set_value("general", "always_show_hitbox", false)
	config.set_value("general", "show_fps", false)
	config.set_value("audio", "master_volume", 50)
	config.set_value("audio", "effects_volume", 75)
	config.set_value("audio", "music_volume", 50)
	config.set_value("input", "player_moveup", "w")
	config.set_value("input", "player_movedown", "s")
	config.set_value("input", "player_moveleft", "a")
	config.set_value("input", "player_moveright", "d")
	config.set_value("input", "player_walk", "Shift")
	config.set_value("input", "player_moveup_controller", "w")
	config.set_value("input", "player_movedown_controller", "s")
	config.set_value("input", "player_moveleft_controller", "a")
	config.set_value("input", "player_moveright_controller", "d")
	config.set_value("input", "player_walk_controller", "Shift")
	config.set_value("input", "player_deadzone_controller", 0.5)
	config.set_value("input", "player_deadzone_onscreen_joystick", 0.2)
	config.set_value("input", "player_running_deadzone_onscreen_joystick", 0.5)
	config.set_value("input", "onscreen_joystick_right", false)
	config.set_value("input", "show_pause_menu", "Escape")
	config.set_value("input", "input_method", Globals.InputTypes.ONSCREEN_JOYSTICK if Utils.device_is_phone() else Globals.InputTypes.KEYBOARD)
	config.set_value("misc", "debug", false)
	config.save(config_path)
