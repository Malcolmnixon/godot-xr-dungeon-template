@tool
extends Node3D


## Signal emitted when chest is opened
signal opened

## Signal emitted when chest is closed
signal closed


# Group for world-data properties
@export_group("World Data")

## This property specifies the unique persistent-ID for this chest
@export var persistent_id : String

# Group for world-data properties
@export_group("Configuration")

## Chest swing
@export var swing := deg_to_rad(-120)

## ID of the key that unlocks this chest
@export var key_id : String

## Move duration
@export var duration := 2.0

## Sound to play when opening chest
@export var open_sound : AudioStream

## Sound to play when attempting to chest when locked
@export var locked_sound : AudioStream

## Sound to play when unlocking
@export var unlock_sound : AudioStream

# Group for world-data properties
@export_group("State")

## Chest open state
@export var open := false : set = _set_open

## Chest locked state
@export var locked := false : set = _set_locked

# Group for world-data properties
@export_group("Holding")

# Items being held by chest
@export var holding : Array[PersistentItem] = []


# Current tween
var _tween : Tween

# Loading flag
var _loading := false


# Called when the node enters the scene tree for the first time.
func _ready():
	# Set initial value
	$Lid.rotation.x = swing if open else 0.0

	# Connect to lid events
	$Lid.pointer_pressed.connect(_on_lid_pointer_pressed)
	$Lid/Lock.body_entered.connect(_on_lock_body_entered)


# Get configuration warnings
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Verify chest ID is set
	if not persistent_id:
		warnings.append("Persistent ID not zet")

	# Verify item is in persistent group
	if not is_in_group("persistent"):
		warnings.append("Chest not in 'persistent' group")

	# Return warnings
	return warnings


# Handle notifications
func _notification(what : int) -> void:
	# Ignore notifications on freeing objects
	if is_queued_for_deletion():
		return

	match what:
		Persistent.NOTIFICATION_LOAD_STATE:
			_load_state()

		Persistent.NOTIFICATION_SAVE_STATE:
			_save_state()


func _load_state() -> void:
	# Restore the item state
	var state = PersistentWorld.instance.get_value(persistent_id)
	if not state is Dictionary:
		return

	# Restore the state fields
	_loading = true
	open = state["open"]
	locked = state["locked"]
	_loading = false


func _save_state() -> void:
	# Save the door state
	PersistentWorld.instance.set_value(
		persistent_id,
		{
			"open" : open,
			"locked" : locked
		})


# Handle lid being pressed by player
func _on_lid_pointer_pressed() -> void:
	# Check if chest is locked
	if not locked:
		# Open or close (plays associated sound)
		open = not open
	elif locked_sound:
		# Play locked sound
		$Lid/AudioStreamPlayer3D.stop()
		$Lid/AudioStreamPlayer3D.stream = locked_sound
		$Lid/AudioStreamPlayer3D.play()


# Handle body entering unlock area
func _on_lock_body_entered(body : PhysicsBody3D) -> void:
	# Skip if not locked
	if not locked:
		return

	# Skip if item is not a PersistentItem
	var item := body as PersistentItem
	if not item:
		return

	# Skip if the item isn't our key
	if item.item_id != key_id:
		return

	# Unlock the chest (plays associated sound)
	locked = false


# Handle change of chest open state
func _set_open(p_open : bool) -> void:
	open = p_open
	if is_inside_tree():
		# Pick target
		var target := swing if p_open else 0.0

		# Fire opened signal
		if p_open:
			opened.emit()
		else:
			closed.emit()

		for h in holding:
			h.enabled = p_open

		# If loading then update instantly
		if _loading:
			$Lid.rotation.x = target
			return

		# Start playing the open sound
		if open_sound:
			$Lid/AudioStreamPlayer3D.stop()
			$Lid/AudioStreamPlayer3D.stream = open_sound
			$Lid/AudioStreamPlayer3D.play()

		# Start swinging the chest to the target
		if _tween: _tween.kill()
		_tween = get_tree().create_tween()
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property($Lid, "rotation:x", target, duration)


# Handle change of chest locked state
func _set_locked(p_locked : bool) -> void:
	locked = p_locked
	if is_inside_tree():
		# Start playing the unlock sound
		if unlock_sound and not _loading:
			$Lid/AudioStreamPlayer3D.stop()
			$Lid/AudioStreamPlayer3D.stream = unlock_sound
			$Lid/AudioStreamPlayer3D.play()
