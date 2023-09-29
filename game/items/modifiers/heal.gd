extends Node


## Health
@export var health : int = 25


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the parent persistent item
	var item : PersistentItem = get_parent()
	if item:
		item.picked_up.connect(_on_picked_up)


func _on_picked_up(_pickable) -> void:
	# Heal player
	GameState.health = min(100, GameState.health + health)
