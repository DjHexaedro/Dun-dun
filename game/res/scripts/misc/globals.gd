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

const LevelCodes: Dictionary = {
	GENERIC = "generic",
	CHESSBOARD = "1",
}

const SimpleBulletTypes: Dictionary = {
	CIRCULAR = "circular",
	DELAYED = "delayed",
	DELAYED_CIRCULAR = "delayed_circular",
	HEALTH = "health",
	STRAIGHT = "straight",
	SOFT_HOMING = "soft_homing",
	PAWN = "pawn",
	ROOK = "rook",
	BISHOP = "bishop",
	QUEEN = "queen",
}

const ComplexBulletTypes: Dictionary = {
	AIMED_PULSATING = "aimed_pulsating",
	POWERUP = "powerup",
	PULSATING = "pulsating",
	RANDOM_PULSATING = "random_pulsating",
}

const MinionTypes: Dictionary = {
	WIDE = "wide_shoot",
	AUTOMATIC = "fully_automatic",
}

const MatchEvents: Dictionary = {
	PLAYER_HIT = "player_hit",
	PLAYER_HEALED = "player_healed",
	PLAYER_HEAL_AS_SCORE = "player_heal_as_score",
	PLAYER_DEATH = "player_death",
	PLAYER_REVIVE = "player_revive",
	CRYSTAL_GRABBED = "crystal_grabbed",
	CRYSTAL_MISSED = "crystal_missed",
	BOSS_DEFEATED = "boss_defeated",
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

enum PlayerIDs {
	PLAYER_ONE,
	PLAYER_TWO,
}

const OUT_OF_BOUNDS_POSITION: Vector2 = Vector2(-999999, -999999)

var Positions: Dictionary = {
	SCREEN_CENTER = Vector2(0, 0),
	TOP_Y = -432,
	BOTTOM_Y = 432,
	CENTER_Y = 0,
	LEFT_X = -768,
	RIGHT_X = 768,
	CENTER_X = 0,
}
