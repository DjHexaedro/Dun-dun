# Helper script that contains a number of useful constants to simplify and make
# code clearer.
# Can be accessed from anywhere within the project
extends Node


const BulletSizes: Dictionary = {
	HALF = Vector2(0.05, 0.05),
	THREE_QUARTERS = Vector2(0.075, 0.075),
	STANDARD = Vector2(0.1, 0.1),
	ONE_AND_A_QUARTER = Vector2(0.125, 0.125),
	ONE_AND_A_HALF = Vector2(0.15, 0.15),
	DOUBLE = Vector2(0.2, 0.2),
	TRIPLE = Vector2(0.3, 0.3),
	QUADRUPLE = Vector2(0.4, 0.4),
}

const Colors: Dictionary = {
	LEVEL_COMPLETED = "#00FF00",
}

const Directions: Dictionary = {
	UP = Vector2(0, -1),
	DOWN = Vector2(0, 1),
	LEFT = Vector2(-1, 0),
	RIGHT = Vector2(1, 0),
}

const NodeNames: Dictionary = {
	PLAYER = "player",
}

const SimpleBulletTypes: Dictionary = {
	CIRCULAR = "circular",
	DELAYED = "delayed",
	DELAYED_CIRCULAR = "delayed_circular",
	HEALTH = "health",
	STRAIGHT = "straight",
	SOFT_HOMING = "soft_homing",
}

const ComplexBulletTypes: Dictionary = {
	AIMED_PULSATING = "aimed_pulsating_bullet",
	POWERUP = "powerup_bullet",
	PULSATING = "pulsating_bullet",
	RANDOM_PULSATING = "random_pulsating_bullet",
}

const MinionTypes: Dictionary = {
	WIDE = "wide_shoot",
	AUTOMATIC = "fully_automatic",
}

const OPTIONS_MENU_CONTROLS_TO_LOAD_GROUP: String = "control_to_load"
const STATS_MENU_STATS_TO_LOAD_GROUP: String = "stats_to_load"
const SCREEN_SIZE: Vector2 = Vector2(1920, 1080)

enum Angles {
	DEGREES45 = 45,
	DEGREES90 = 90,
	DEGREES120 = 120,
	DEGREES180 = 180,
	DEGREES270 = 270,
}

enum DifficultyLevels {
	NORMAL,
	HARD,
	HARDEST,
}

enum InputTypes {
	KEYBOARD,
	CONTROLLER,
	ONSCREEN_JOYSTICK,
}

var Positions: Dictionary = {}

func _ready() -> void:
	Positions = {
		OUT_OF_BOUNDS = Vector2(-1000, -1000),
		SCREEN_CENTER = Vector2(SCREEN_SIZE.x / 2, SCREEN_SIZE.y / 2),
		TOP_Y = SCREEN_SIZE.y * 0.1,
		BOTTOM_Y = SCREEN_SIZE.y * 0.9,
		CENTER_Y = SCREEN_SIZE.y / 2,
		LEFT_X = SCREEN_SIZE.x * 0.1,
		RIGHT_X = SCREEN_SIZE.x * 0.9,
		CENTER_X = SCREEN_SIZE.x / 2,
	}
