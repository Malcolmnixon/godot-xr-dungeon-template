@tool
extends Node3D


# Group for world-data properties
@export_group("World Data")

## This property specifies the unique ID for this door
@export var door_id : String

# Group for world-data properties
@export_group("Configuration")

## ID of the key that unlocks this door
@export var key_id : String

## Door swing
@export var swing := deg_to_rad(80)

## Move duration
@export var duration := 2.0

## Sound to play when opening door
@export var open_sound : AudioStream

## Sound to play when attempting to open when locked
@export var locked_sound : AudioStream

## Sound to play when unlocking
@export var unlock_sound : AudioStream

# Group for world-data properties
@export_group("State")

## Door open state
@export var open := false : set = _set_open

## Door locked state
@export var locked := false : set = _set_locked


# Current tween
var _tween : Tween

# Loading flag
var _loading := false


# Called when the node enters the scene tree for the first time.
func _ready():
	# Set initial value
	$Door.rotation.y = swing if open else 0.0

	# Control door navigation
	$NavigationRegion3D.enabled = open

	# Connect to door events
	$Door.pointer_pressed.connect(_on_door_pointer_pressed)
	$Door/Lock.body_entered.connect(_on_lock_body_entered)


# Get configuration warnings
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Verify door ID is set
	if not door_id:
		warnings.append("Door ID not zet")

	# Verify item is in persistent group
	if not is_in_group("persistent"):
		warnings.append("Doorway not in 'persistent' group")

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
	var state = PersistentWorld.instance.get_value(door_id)
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
		door_id,
		{
			"open" : open,
			"locked" : locked
		})


# Handle door being pressed by player
func _on_door_pointer_pressed() -> void:
	# Check if door is locked
	if not locked:
		# Open or close (plays associated sound)
		open = not open
	elif locked_sound:
		# Play locked sound
		$Door/AudioStreamPlayer3D.stop()
		$Door/AudioStreamPlayer3D.stream = locked_sound
		$Door/AudioStreamPlayer3D.play()


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

	# Unlock the door (plays associated sound)
	locked = false


# Handle change of door open state
func _set_open(p_open : bool) -> void:
	open = p_open
	if is_inside_tree():
		# Control door navigation
		$NavigationRegion3D.enabled = open

		# Pick target
		var target := swing if open else 0.0

		# If loading then update instantly
		if _loading:
			$Door.rotation.y = target
			return

		# Start playing the open sound
		if open_sound:
			$Door/AudioStreamPlayer3D.stop()
			$Door/AudioStreamPlayer3D.stream = open_sound
			$Door/AudioStreamPlayer3D.play()

		# Start swinging the door to the target
		if _tween: _tween.kill()
		_tween = get_tree().create_tween()
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property($Door, "rotation:y", target, duration)


# Handle change of door locked state
func _set_locked(p_locked : bool) -> void:
	locked = p_locked
	if is_inside_tree():
		# Start playing the unlock sound
		if unlock_sound and not _loading:
			$Door/AudioStreamPlayer3D.stop()
			$Door/AudioStreamPlayer3D.stream = unlock_sound
			$Door/AudioStreamPlayer3D.play()
