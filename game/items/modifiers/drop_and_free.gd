class_name DropAndFree
extends Node


## Audio to play
@export var audio : AudioStreamPlayer


# Persistent item
var _item : PersistentItem


# Called when the node enters the scene tree for the first time.
func _ready():
	# Subscribe to picked up
	_item = get_parent()
	if _item:
		_item.picked_up.connect(_on_picked_up)

	# Subscribe to audio finished
	if audio:
		audio.finished.connect(_on_audio_finished)


func _on_picked_up(_pickable) -> void:
	# Play audio if configured
	if audio:
		audio.play()
		return

	# Drop and free item
	_item.drop_and_free()


func _on_audio_finished() -> void:
	# Drop and free item
	_item.drop_and_free()
