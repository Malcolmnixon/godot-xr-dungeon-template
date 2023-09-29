extends PersistentWorld


## Game State Singleton
##
## This auto-load class can be used to hold game state information between
## levels. This class can be accessed from any script using its global
## GameState name.
##
## The [GameStaging] script populates the staging and current_zone fields
## of this script in response to scene switching.


## Game difficulty options
enum GameDifficulty {
	GAME_EASY,
	GAME_NORMAL,
	GAME_HARD,
	GAME_MAX
}


## Signal emitted when the players health changes
signal health_changed(value)

## Signal emitted when the players gold changes
signal gold_changed(value)


@export_group("Game Settings")

## This property sets the starting zone for the game
@export var starting_zone : PersistentZoneInfo

## Current game slot
@export var game_slot := "slot1"

## This property sets the difficulty of the game.
@export var game_difficulty : GameDifficulty = GameDifficulty.GAME_NORMAL:
	set = _set_game_difficulty

## Player health
@export var health : int = 100 : set = _set_health

## Player gold
@export var gold : int = 0 : set = _set_gold

## Game play time
@export var play_time : float = 0.0


## Current zone (when playing game)
var current_zone : PersistentZone


func _ready():
	# Use this game state as the global world state
	instance = self


func _process(delta : float):
	if not get_tree().paused:
		play_time += delta


## This method starts a new game.
func new_game(difficulty := GameDifficulty.GAME_NORMAL) -> bool:
	# Clear game data and start with requested difficulty level
	clear_all()
	game_difficulty = difficulty

	# Load the initial world state (starting zone)
	return load_world_state()


## This method loads a game from the specified save-game.
func load_game() -> bool:
	# Read data from the save-game file
	if not load_file(game_slot):
		return false

	# Load the world state from the data
	return load_world_state()


## This method saves the current game-state to memory then quits to the main
## menu. It's possible to restore the previous game state by calling 
## [method load_world_state].
func quit_game() -> bool:
	# Save the world state to memory in case we want to resume
	if not save_world_state():
		return false

	# Exit to the main menu
	current_zone.exit_to_main_menu()
	return true


## This method auto-saves the current game state to disk.
func save_game() -> bool:
	# Save the world state
	if not save_world_state():
		return false

	# Construct summary
	var date := Time.get_datetime_dict_from_system()
	var summary := {
		"date" : "%d / %d / %d" % [ date.year, date.month, date.day ],
		"score" : gold,
		"play_time" : play_time
	}

	# Save the game
	return save_file(game_slot, summary)


## This method saves the world-state to the [PersistentWorld] system.
func save_world_state() -> bool:
	# Fail if not in a zone
	if not PersistentStaging.instance or not current_zone:
		return false

	# Fail if no player body
	var body := XRToolsPlayerBody.find_instance(current_zone)
	if not body:
		return false

	# Save the current zone-state, difficulty, and spawn-info
	current_zone.save_world_state()
	set_value("current_zone_id", current_zone.zone_info.zone_id)
	set_value("current_location", body.global_transform)
	set_value("health", health)
	set_value("gold", gold)
	set_value("play_time", play_time)
	return true


## This method restores the world-state from the [PersistentWorld] system.
func load_world_state() -> bool:
	# Fail if no staging
	if not PersistentStaging.instance:
		return false

	# Get the zone ID
	var zone_id = get_value("current_zone_id")
	if not zone_id is String:
		# Default to the starting zone
		zone_id = starting_zone.zone_id

	# Get the location
	var location = get_value("current_location")
	if not location is Transform3D:
		# Default to null (spawn location in level)
		location = null

	# Restore the game data
	game_difficulty = get_value("game_difficulty")
	health = get_value("health", 100)
	gold = get_value("gold", 0)
	play_time = get_value("play_time", 0.0)

	# Get the zone
	var zone := zone_database.get_zone(zone_id)
	if not zone:
		return false

	# Start transition to scene
	PersistentStaging.instance.load_scene(zone.instance_scene, location)
	return true


# Handle changing the game difficulty
func _set_game_difficulty(p_game_difficulty : GameDifficulty) -> void:
	if p_game_difficulty < 0 or p_game_difficulty >= GameDifficulty.GAME_MAX:
		push_warning("Difficulty %d is out of bounds" % [ p_game_difficulty ])
		return

	game_difficulty = p_game_difficulty
	set_value("game_difficulty", game_difficulty)


func _set_health(p_health : int) -> void:
	health = clamp(p_health, 0, 100)
	health_changed.emit(health)


func _set_gold(p_gold : int) -> void:
	gold = clamp(p_gold, 0, 99999)
	gold_changed.emit(gold)
