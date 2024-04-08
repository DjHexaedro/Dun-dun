extends Node2D

class_name BaseRevivePlayerHeart

onready var decay_timer_timer: Timer = $decay_timer

const BASE_PLAYER_PICKUP_DISTANCE: float = 3000.0
const VERTICAL_INCREMENT: Vector2 = Vector2(0, -20)

var player_pickup_distance: float = BASE_PLAYER_PICKUP_DISTANCE
var player_id_to_revive: int
var chosen_spawn_point: Position2D

func _ready() -> void:
	global_position = Globals.OUT_OF_BOUNDS_POSITION

func _process(_delta: float) -> void:
	for player in PlayerManager.get_player_list():
		if player.alive and global_position.distance_squared_to(
			PlayerManager.get_player_position(player.player_id)
		) < player_pickup_distance:
			_on_revive_heart_grabbed()

func spawn(player: Node) -> void:
	var valid_spawn_points: Array = ArenaManager.get_valid_spawn_points(
		player.player_id
	)
	chosen_spawn_point = valid_spawn_points[randi()%len(valid_spawn_points)]
	chosen_spawn_point.being_used = true
	global_position = chosen_spawn_point.global_position
	player_id_to_revive = player.player_id
	decay_timer_timer.start()

func _on_revive_heart_grabbed() -> void:
	chosen_spawn_point.being_used = false
	PowerupManager.restore_dead_player_collected_crystals(player_id_to_revive)
	PlayerManager.revive_player(player_id_to_revive)
	queue_free()

func _on_decay_timer_timeout() -> void:
	chosen_spawn_point.being_used = false
	queue_free()

