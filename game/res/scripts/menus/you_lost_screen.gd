# Functions used by the game over screen
extends CanvasLayer

signal exit_to_map
signal try_again 
signal match_history_shown

const LIFEBAR_X_SCALE: float = 33.8
const MENU_OPTIONS_TEXT: Array = ["Try again", "Exit level"]
const BASE_DMG: int = 15
const BASE_SCORE: int = 5
const INSTEAD_OF_HEALTH_SCORE: int = 15000

onready var lifemarkerscene = preload(
	"res://juegodetriangulos/scenes/level_assets/generic/boss_phase_lifebar_marker.tscn"
)
onready var hitmarkerscene = preload(
	"res://juegodetriangulos/scenes/misc/hit_marker.tscn"
)
onready var tallhitmarkerscene = preload(
	"res://juegodetriangulos/scenes/misc/hit_marker_tall.tscn"
)

onready var bgm: AudioStreamPlayer = $bgm
onready var exit_level: Button = $you_lost_menu/exit_level
onready var try_again: Button = $you_lost_menu/try_again
onready var background: ColorRect = $background
onready var total_score: Label = $total_score
onready var you_lost_message: Label = $you_lost_message
onready var blink_timer: Timer = $blink_timer
onready var unblink_timer: Timer = $unblink_timer
onready var fade_in_tween: Tween = $fade_in_tween
onready var you_lost_menu: VBoxContainer = $you_lost_menu
onready var selected_option_marker_sprite: Sprite = $selected_option_marker
onready var lifebar_container: Control = $lifebar_container
onready var lifebar_decoration: Sprite = $lifebar_container/lifebar_decoration
onready var enemy_lifebar: Sprite = $lifebar_container/lifebar
onready var powerup_data_container: Control = $powerup_data_container

var menu_options: Array = []
var allow_input: bool
var current_option: int = 0
var joystick_ui_timer: Timer = Timer.new()
var can_move_joystick_ui: bool = true
var marker_list: Array = []

# Index 5 stores missed crystals
var crystals_collected_list: Array = [0, 0, 0, 0, 0, 0]

var max_enemy_health: float
var current_enemy_health: float 
var show_match_history_animation: bool = true
var current_score: int = 0
var previous_events: Dictionary = {
	"above": { "at": 999999, "tall": false },
	"below": { "at": 999999, "tall": false },
}
var current_player_health: int = 3
var MIN_DISTANCE_BETWEEN_EVENTS: int


func _ready() -> void:
	allow_input = false
	pause_mode = Node.PAUSE_MODE_PROCESS
	menu_options = [try_again, exit_level]
	fade_in_tween.interpolate_property(
		you_lost_message, "modulate", Color(1, 1, 1, 0),
		Color(1, 1, 1, 1), 3, Tween.TRANS_LINEAR, Tween.EASE_IN
	)
	fade_in_tween.interpolate_property(
		background, "color", Color(0, 0, 0, 0),
		Color(0, 0, 0, 0.75), 3, Tween.TRANS_LINEAR, Tween.EASE_IN
	)
	bgm.play()
	joystick_ui_timer.set_wait_time(0.1)
	joystick_ui_timer.connect("timeout", self, "_on_joystick_ui_timer_timeout")
	add_child(joystick_ui_timer)
	max_enemy_health = (
		EnemyManager.get_total_fight_time()
		if Utils.is_difficulty_hardest() else
		EnemyManager.get_enemy_max_health()
	)
	current_enemy_health = max_enemy_health
	MIN_DISTANCE_BETWEEN_EVENTS = max_enemy_health * 0.05

func _input(event: InputEvent) -> void:
	if allow_input:
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			current_option = 1 if current_option == 0 else 0
		if (
			event.is_action_pressed("ui_up_joystick") or
			event.is_action_pressed("ui_down_joystick")
		) and can_move_joystick_ui:
			current_option = 1 if current_option == 0 else 0
			can_move_joystick_ui = false
			joystick_ui_timer.start()
		set_selected_option_marker_position()
		if event.is_action_pressed("ui_accept"):
			execute_menu_option()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() or event is InputEventScreenTouch or event is InputEventScreenDrag:
		show_match_history_animation = false

func show_match_history() -> void:
	var match_history: Array = GameStateManager.get_match_history()

	if Utils.is_difficulty_hardest():
		set_phase_markers_as_timer(EnemyManager.get_timing_list(), max_enemy_health)
		show_history_hardest_mode(match_history)
	else:
		set_phase_markers()
		show_history_normal_hard_mode(match_history)

func show_history_normal_hard_mode(match_history: Array) -> void:
	var place_below: bool = true 

	for entry in match_history:
		place_below = check_entry(entry, place_below)
		if show_match_history_animation:
			yield(get_tree().create_timer(0.5), "timeout")

	emit_signal("match_history_shown")

func show_history_hardest_mode(match_history: Array) -> void:
	var place_below: bool = true 

	for entry in match_history:
		while(current_enemy_health > (max_enemy_health - entry.boss_current_damage)):
			update_enemy_health_as_timer(current_enemy_health, max_enemy_health)
			if show_match_history_animation:
				yield(get_tree().create_timer(0.5), "timeout")
			current_enemy_health -= 1.0
		place_below = check_entry(entry, place_below)
		add_score(pow(10, current_player_health + 1))
		if show_match_history_animation:
			yield(get_tree().create_timer(0.5), "timeout")

	emit_signal("match_history_shown")

func check_entry(entry: Dictionary, place_below: bool) -> bool:
	match entry.event:
		Globals.MatchEvents.PLAYER_HIT:
			add_history_marker(Globals.MatchEvents.PLAYER_HIT, place_below)
			current_player_health -= 1
			return not place_below

		Globals.MatchEvents.PLAYER_HEALED:
			add_history_marker(Globals.MatchEvents.PLAYER_HEALED, place_below)
			current_player_health += 1
			return not place_below

		Globals.MatchEvents.PLAYER_HEAL_AS_SCORE:
			add_history_marker(Globals.MatchEvents.PLAYER_HEAL_AS_SCORE, place_below)
			add_score(INSTEAD_OF_HEALTH_SCORE)
			return not place_below

		Globals.MatchEvents.PLAYER_DEATH:
			add_history_marker("%s%s" % [
				Globals.MatchEvents.PLAYER_DEATH, entry.additional_info
			], place_below)
			return not place_below

		Globals.MatchEvents.PLAYER_REVIVE:
			add_history_marker("%s%s" % [
				Globals.MatchEvents.PLAYER_REVIVE, entry.additional_info
			], place_below)
			return not place_below

		Globals.MatchEvents.CRYSTAL_GRABBED:
			crystals_collected_list[entry.additional_info - 1] += 1
			powerup_data_container.get_node(
				"%s/qty" % (entry.additional_info - 1)
			).text = "x%s" % crystals_collected_list[entry.additional_info - 1]
			update_enemy_health(BASE_DMG * clamp(entry.additional_info, 1, 5))
			add_score(pow(
				BASE_SCORE * entry.additional_info, 2
			) * GameStateManager.get_score_multiplier())
			return place_below

		Globals.MatchEvents.CRYSTAL_MISSED:
			crystals_collected_list[5] += 1
			powerup_data_container.get_node(
				"missed/qty"
			).text = "x%s" % crystals_collected_list[5]
			return place_below

		Globals.MatchEvents.BOSS_DEFEATED:
			return place_below
	
	return place_below

func add_history_marker(marker_type: String, is_below: bool = true) -> void:
	var previous_event: Dictionary = previous_events[
		"below" if is_below else "above" 
	]
	var needs_tall: bool = (
		(previous_event["at"] - current_enemy_health) < MIN_DISTANCE_BETWEEN_EVENTS
		and not previous_event["tall"]
	)
	var historymarker: Node2D = (
		tallhitmarkerscene.instance() if needs_tall else hitmarkerscene.instance()
	)
	add_child(historymarker)
	historymarker.get_node(marker_type).show()
	historymarker.get_node("arrow_up" if is_below else "arrow_down").show()
	historymarker.global_position = Vector2(
		enemy_lifebar.global_position.x + (
			enemy_lifebar.texture.get_width() * LIFEBAR_X_SCALE *
			(current_enemy_health / max_enemy_health)
		),
		enemy_lifebar.global_position.y + (
			(155 if is_below else -115)
			if needs_tall else
			(100 if is_below else -60)
		)
	)
	previous_events["below" if is_below else "above"]["at"] = current_enemy_health
	previous_events["below" if is_below else "above"]["tall"] = needs_tall 


func set_phase_markers() -> void:
	for marker in marker_list:
		marker.queue_free()
	marker_list = []
	lifebar_container.get_node("boss_name").text = EnemyManager.get_enemy_name()
	var n_of_phases: int = EnemyManager.get_enemy_n_of_phases()
	var position_increment: float = lifebar_decoration.texture.get_size().x / n_of_phases
	for i in range(1, n_of_phases):
		var new_marker: Node = lifemarkerscene.instance()
		lifebar_decoration.add_child(new_marker)
		new_marker.position = Vector2(
			(i * position_increment) - 50, lifebar_decoration.texture.get_size().y / 2
		)
		marker_list.append(new_marker)

func set_phase_markers_as_timer(timing_list: Array, total_time: float) -> void:
	for marker in marker_list:
		marker.queue_free()
	marker_list = []
	var lifebar_decoration_length: float = lifebar_decoration.texture.get_size().x
	var lifebar_decoration_heigth: float = lifebar_decoration.texture.get_size().y
	for timing in timing_list:
		var new_marker: Node = lifemarkerscene.instance()
		var new_marker_x_position: float = lifebar_decoration_length * (1 - (timing / total_time))
		lifebar_decoration.add_child(new_marker)
		new_marker.position = Vector2(new_marker_x_position, lifebar_decoration_heigth / 2)
		marker_list.append(new_marker)

func update_enemy_health(damage_received: int) -> void:
	current_enemy_health -= damage_received
	var scale: float = LIFEBAR_X_SCALE * (current_enemy_health / max_enemy_health)
	enemy_lifebar.scale.x = scale

func update_enemy_health_as_timer(time_left: float, total_time: float) -> void:
	var scale_modifier: float = time_left / total_time
	var scale: float = LIFEBAR_X_SCALE * scale_modifier
	enemy_lifebar.scale.x = scale

func show_all_options() -> void:
	var i = 0
	while i < menu_options.size():
		menu_options[i].set_text(MENU_OPTIONS_TEXT[i])
		i += 1

func set_selected_option_marker_position() -> void:
	selected_option_marker_sprite.global_position = Vector2(
		menu_options[current_option].rect_global_position.x -
			(menu_options[current_option].rect_size.x / 2),
		menu_options[current_option].rect_global_position.y +
			(menu_options[current_option].rect_size.y / 2)
	)

func add_score(score_to_add: int) -> void:
	current_score += score_to_add
	total_score.text = "Your score: %s" % current_score

func execute_menu_option() -> void:
	if current_option == 0:
		_on_try_again_pressed()
	elif current_option == 1:
		_on_exit_level_pressed()

func show_you_lost_screen() -> void:
	you_lost_message.show()
	background.rect_size = Globals.SCREEN_SIZE
	background.show()
	Utils.show_mouse_if_necessary()
	fade_in_tween.start()

func hide_you_lost_screen() -> void:
	you_lost_message.hide()
	background.hide()
	you_lost_menu.hide()
	total_score.hide()
	Utils.hide_mouse_if_necessary()
	get_tree().paused = false
	queue_free()

func pause_game() -> void:
	get_tree().paused = true 

func _on_try_again_pressed() -> void:
	hide_you_lost_screen()
	emit_signal("try_again")

func _on_exit_level_pressed() -> void:
	hide_you_lost_screen()
	# emit_signal("exit_to_map")
	GameStateManager.exit_to_map()

func _on_fade_in_tween_all_completed() -> void:
	lifebar_container.show()
	if GameStateManager.get_difficulty_level() != Globals.DifficultyLevels.HARDEST:
		powerup_data_container.show()
	show_match_history()
	if show_match_history_animation:
		yield(self, "match_history_shown")
	allow_input = true
	you_lost_menu.show()
	set_selected_option_marker_position()
	selected_option_marker_sprite.show()

func _on_try_again_mouse_entered() -> void:
	current_option = 0

func _on_exit_level_mouse_entered() -> void:
	current_option = 1

func _on_joystick_ui_timer_timeout() -> void:
	can_move_joystick_ui = true
