extends Node


## Count of gold coins
@export var gold : int = 10


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the parent persistent item
	var item : PersistentItem = get_parent()
	if item:
		item.picked_up.connect(_on_picked_up)


func _on_picked_up(_pickable) -> void:
	# Add gold to player
	GameState.gold += gold
