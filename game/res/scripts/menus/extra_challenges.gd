# Functions used by the extra challenges screen
extends CanvasLayer

signal extra_challenges_menu_exit

onready var save_button: Button = $container/save_button
onready var missed_grabs_do_damage_checkbox: CheckBox = $container/missed_grabs_do_damage
onready var moving_does_damage_checkbox: CheckBox = $container/moving_does_damage
onready var standing_still_does_damage_checkbox: CheckBox = $container/standing_still_does_damage
onready var edge_touching_does_damage_checkbox: CheckBox = $container/edge_touching_does_damage
onready var one_hit_death_checkbox: CheckBox = $container/one_hit_death
onready var only_perfect_grabs_checkbox: CheckBox = $container/only_perfect_grabs
onready var container_node: Panel = $container
onready var selected_challenge_marker_sprite: Sprite = $container/selected_challenge_marker

var options_list: Array
var current_option: int = 0
var all_options: Array
var options_by_boss: Dictionary
var joystick_ui_timer: Timer = Timer.new()
var can_move_joystick_ui: bool = true


func _ready() -> void:
	all_options = [
		one_hit_death_checkbox,
		only_perfect_grabs_checkbox,
		missed_grabs_do_damage_checkbox,
		edge_touching_does_damage_checkbox,
		standing_still_does_damage_checkbox,
		moving_does_damage_checkbox,
		save_button,
	]
	options_by_boss = {
		0: all_options,
		1: [
			one_hit_death_checkbox,
			only_perfect_grabs_checkbox,
			missed_grabs_do_damage_checkbox,
			save_button,
		],
		2: [
			one_hit_death_checkbox,
			standing_still_does_damage_checkbox,
			moving_does_damage_checkbox,
			save_button,
		],
	}
	options_list = options_by_boss[0]
	joystick_ui_timer.set_wait_time(0.1)
	joystick_ui_timer.connect("timeout", self, "_on_joystick_ui_timer_timeout")
	add_child(joystick_ui_timer)

func _input(event: InputEvent) -> void:
	if container_node.visible:
		if event.is_action_pressed("ui_cancel"):
			_on_save_button_pressed()
		else:
			if (
				event.is_action_pressed("ui_up") or
				event.is_action_pressed("ui_down")
			):
				_update_current_option(
					-1 if event.is_action_pressed("ui_up") else 1
				)

			if (
				event.is_action_pressed("ui_up_joystick") or
				event.is_action_pressed("ui_down_joystick")
			) and can_move_joystick_ui:
				_update_current_option(
					-1 if event.is_action_pressed("ui_up_joystick") else 1
				)
				can_move_joystick_ui = false
				joystick_ui_timer.start()

			move_marker()

			if event.is_action_pressed("ui_accept"):
				if options_list[current_option].name == "save_button":
					_on_save_button_pressed()
				else:
					options_list[current_option].pressed =\
						not options_list[current_option].pressed

func _update_current_option(option_increase: int) -> void:
	current_option += option_increase
	if current_option < 0:
		current_option = len(options_list) - 1
	if current_option > len(options_list) - 1:
		current_option = 0

func move_marker() -> void:
	selected_challenge_marker_sprite.position.y =\
			options_list[current_option].rect_position.y +\
			(options_list[current_option].rect_size.y / 2)

func switch_challenges(boss_id: int) -> void:
	for option in all_options:
		option.hide()
		if option.name != "save_button":
			option.pressed = false
	for challenge in options_by_boss[boss_id]:
		challenge.show()
	options_list = options_by_boss[boss_id]
	current_option = 0
	move_marker()

func _on_one_hit_death_toggled(button_pressed: bool) -> void:
	GameStateManager.set_one_hit_death(button_pressed)

func _on_only_perfect_grabs_toggled(button_pressed: bool) -> void:
	GameStateManager.set_only_perfect_grabs(button_pressed)

func _on_missed_grabs_do_damage_toggled(button_pressed: bool) -> void:
	GameStateManager.set_missed_grabs_do_damage(button_pressed)

func _on_moving_does_damage_toggled(button_pressed: bool) -> void:
	GameStateManager.set_moving_does_damage(button_pressed)

func _on_standing_still_does_damage_toggled(button_pressed: bool) -> void:
	GameStateManager.set_standing_still_does_damage(button_pressed)

func _on_edge_touching_does_damage_toggled(button_pressed: bool) -> void:
	GameStateManager.set_edge_touching_does_damage(button_pressed)

func _on_save_button_pressed() -> void:
	container_node.hide()
	yield(Utils.wait(0.1), "timeout")
	emit_signal("extra_challenges_menu_exit")

func _on_joystick_ui_timer_timeout() -> void:
	can_move_joystick_ui = true
