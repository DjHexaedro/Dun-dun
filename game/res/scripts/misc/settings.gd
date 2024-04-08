# Script that manages the settings file and allows other scripts to easily
# access its values. It also manages the save data, for some reason
# Can be accessed from anywhere within the project
extends Node

signal settings_file_changed
signal game_statistic_updated(game_statistic, new_value)

var saved_games_dir: Directory = Directory.new()
var saved_games_dir_path: String = "user://saved_games"
var save_data_file: File = File.new()
var save_data_file_path: String = "user://saved_games/save_data_%s.json"
var save_data_file_id: int = -1
var save_data: Dictionary = {}
var config: ConfigFile = ConfigFile.new()
var config_path: String = "user://settings.cfg"
var config_file_status: int = config.load(config_path)
var config_params_dict: Dictionary = {}

func _ready() -> void:
	if config_file_status != OK:
		create_default_config_file()
	load_config_file()
	if not saved_games_dir.dir_exists(saved_games_dir_path):
		saved_games_dir.make_dir(saved_games_dir_path)
	# if exists_saved_game_data():
	# 	load_save_game_file(get_config_parameter("default_save_file_id", 0))
	create_save_game_file()


func get_config_parameter(parameter_name: String, return_value = null):
	var current_parameter_value
	for section in config_params_dict:
		current_parameter_value = config_params_dict[section].get(parameter_name, null)
		if current_parameter_value != null:
			return current_parameter_value 
	return Utils.log_error("Parameter %s does not exist or is null" % parameter_name, return_value)

func create_save_game_file() -> void:
	save_data_file_id = get_config_parameter("next_save_file_id", 0)
	save_data = {}
	save_data["deaths"] = 0
	save_data["selected_level"] = 0
	save_data["inside_level"] = true
	save_data["current_boss"] = 0 
	save_data["fighting_boss"] = true
	save_data["is_lamp_on"] = true
	save_data["level_scores"] = {}
	# save_game_data()
	save_to_config_file({
		"saved_games": {
			"default_save_file_id": save_data_file_id,
			"next_save_file_id": save_data_file_id + 1,
		}
	})

# func create_save_game_file() -> void:
# 	save_data_file_id = get_config_parameter("next_save_file_id", 0)
# 	save_data = {}
# 	save_data["deaths"] = 0
# 	save_data["selected_level"] = 0
# 	save_data["inside_level"] = false
# 	save_data["level_scores"] = {}
# 	save_game_data()
# 	save_to_config_file({
# 		"saved_games": {
# 			"default_save_file_id": save_data_file_id,
# 			"next_save_file_id": save_data_file_id + 1,
# 		}
# 	})

func exists_saved_game_data() -> bool:
	if saved_games_dir.open(saved_games_dir_path) == OK:
		saved_games_dir.list_dir_begin()
		var file_name: String = saved_games_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				return true
			file_name = saved_games_dir.get_next()
	return false

func load_save_game_file(file_id: int = save_data_file_id) -> void:
	save_data_file.open(save_data_file_path % file_id, File.READ)
	var saved_data_json = save_data_file.get_as_text()
	save_data_file.close()
	if parse_json(saved_data_json) == null:
		create_save_game_file()
	else:
		save_data = parse_json(saved_data_json)
	save_data_file_id = file_id
	save_to_config_file({
		"saved_games": {
			"default_save_file_id": file_id,
		}
	})

# func save_game_data(file_id: int = save_data_file_id) -> void:
# 	save_data_file.open(save_data_file_path % file_id, File.WRITE)
# 	save_data_file.store_string(to_json(save_data))
# 	save_data_file.close()

func save_game_statistic(statistic: String, value, key: String = "") -> void:
	if key:
		save_data[statistic][key] = value
	else:
		save_data[statistic] = value
	# save_game_data()
	emit_signal("game_statistic_updated", statistic, value)

func increase_game_statistic(statistic: String, increment: int) -> void:
	if save_data.get(statistic, 0):
		save_data[statistic] += increment
	else:
		save_data[statistic] = increment
	# save_game_data()

func get_game_statistic(statistic: String, default_value, key: String = ""):
	if key:
		return save_data.get(statistic, {}).get(key, default_value)
	else:
		return save_data.get(statistic, default_value)

func get_save_files_list() -> Array:
	var save_files_list: Array = []
	if saved_games_dir.open(saved_games_dir_path) == OK:
		saved_games_dir.list_dir_begin()
		var file_name: String = saved_games_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				save_files_list.append(_format_file_name(file_name))
			file_name = saved_games_dir.get_next()
	return save_files_list

func _format_file_name(file_name: String) -> String:
	var new_file_name: String = file_name.replace("_", " ")
	new_file_name = new_file_name.replace(".json", "")
	new_file_name = new_file_name.capitalize()
	return new_file_name

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
	GameStateManager.set_multiplayer_enabled(config_params_dict.get("general", {}).get("multiplayer_enabled", false))

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
	config.set_value("general", "multiplayer_enabled", false)
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
	config.set_value("saved_data", "default_save_file_id", -1)
	config.set_value("saved_data", "next_save_file_id", 0)
	config.set_value("misc", "debug", false)
	config.save(config_path)
