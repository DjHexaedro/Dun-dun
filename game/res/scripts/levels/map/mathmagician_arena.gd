# Script containing the code related to the arena for THE MATHMAGICIAN boss fight
extends BaseMapArea

signal loaded
signal page_turned

onready var powerup_spawning_zones: Node = $powerup_spawning_zones
onready var arena_light: Light2D = $arena_light
onready var book_sprite: AnimatedSprite = $sprite/book
onready var page_audio: AudioStreamPlayer2D = $page

func _ready():
	emit_signal("loaded")
	GameStateManager.set_camera_focus(true, false)

func get_enemy_positions_list() -> Dictionary:
	return {
		"global": {
			SCREEN_CENTER = global_position,
			TOP_Y =  global_position.y - 432,
			BOTTOM_Y = global_position.y + 432,
			CENTER_Y = global_position.y,
			LEFT_X = global_position.x - 768,
			RIGHT_X = global_position.x + 768,
			CENTER_X = global_position.x,
		},
		"local": {
			SCREEN_CENTER = Vector2(0, 0),
			TOP_Y = -432,
			BOTTOM_Y = 432,
			CENTER_Y = 0,
			LEFT_X = -768,
			RIGHT_X = 768,
			CENTER_X = 0,
		}
	}

func turn_book_page() -> void:
	book_sprite.play()
	page_audio.play()

func get_valid_spawn_points(_player_id: int = 0) -> Array:
	return powerup_spawning_zones.get_children()

func _on_book_frame_changed():
	if book_sprite.get_frame() in [0, 7]:
		book_sprite.stop()
		emit_signal("page_turned")
