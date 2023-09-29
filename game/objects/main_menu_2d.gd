extends Control


# Selected slot
var _selected_slot := "slot1"


# Mapping of controls by game-slot
@onready var controls := {
	"slot1" : {
		"date" : %GameSlot1/Items/Date,
		"play_time" : %GameSlot1/Items/PlayTime,
		"load" : %GameSlot1/Items/Buttons/Load
	},
	"slot2" : {
		"date" : %GameSlot2/Items/Date,
		"play_time" : %GameSlot2/Items/PlayTime,
		"load" : %GameSlot2/Items/Buttons/Load
	},
	"slot3" : {
		"date" : %GameSlot3/Items/Date,
		"play_time" : %GameSlot3/Items/PlayTime,
		"load" : %GameSlot3/Items/Buttons/Load
	}
}


func _ready():
	_load_game_slot("slot1")
	_load_game_slot("slot2")
	_load_game_slot("slot3")


func _load_game_slot(slot : String) -> void:
	# Load the summary
	var data = GameState.load_summary(slot)
	if not data:
		return

	# Update the UI
	controls[slot].date.text = data.date
	controls[slot].play_time.text = "%.f seconds" % data.play_time
	controls[slot].load.disabled = false


func _on_overwrite_yes_pressed():
	# Start a new game in the slot
	GameState.game_slot = _selected_slot
	GameState.new_game()


func _on_overwrite_no_pressed():
	# Switch back to the slot-selection screen
	%Tabs.current_tab = 0


func _on_slot_new_pressed(slot : String) -> void:
	# Test if the slot has a game
	if not controls[slot].load.disabled:
		# Ask the user if they want to overwrite the game
		_selected_slot = slot
		%Tabs.current_tab = 1
	else:
		# Start a new game in the slot
		GameState.game_slot = slot
		GameState.new_game()


func _on_slot_load_pressed(slot : String) -> void:
	# Load the game from the slot
	GameState.game_slot = slot
	GameState.load_game()


func _on_quit_pressed():
	get_tree().quit()
