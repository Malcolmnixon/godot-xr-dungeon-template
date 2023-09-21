@tool
extends PersistentItem


## Count of gold coins
@export var gold : int = 10


# Called when the node enters the scene tree for the first time.
func _ready():
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	picked_up.connect(_on_picked_up)
	$AudioStreamPlayer.finished.connect(_on_audio_finished)


## Call to enable access to a "locked" stack of gold
func enable_access(p_enable := true) -> void:
	enabled = p_enable



func _on_picked_up(_pickable) -> void:
	$AudioStreamPlayer.play()


func _on_audio_finished() -> void:
	GameState.gold += gold
	drop_and_free()
