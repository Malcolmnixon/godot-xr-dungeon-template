@tool
extends CharacterBody3D


## Skeleton states
enum State {
	IDLE,		## Idle
	STAGGER,	## Staggering from hit
	TRACKING,   ## Tracking target
	SEARCHING,	## Searching for target
	DEAD		## Killed
}


## Movement speed
const MOVE_SPEED := 2.0

## Turn speed
const TURN_SPEED := 2.0

## Field of view
const FIELD_OF_VIEW := deg_to_rad(80)

## Duration of tracking after last seen
const TRACKING_DURATION := 3.0

## Duration of searching after last tracking
const SEARCHING_DURATION := 10.0

## Damage from a hit
const HIT_DAMAGE := 0.1


## Persistent ID
@export var persistent_id : String

## Target body
@export var target_body : PhysicsBody3D

## Target node
@export var target_node : Node3D


# Current state
var _state := State.IDLE

# Remaining state duration
var _duration := 0.0

# Health
var _health := 1.0


# Sight raycast
@onready var _sight : RayCast3D = $Sight

# Animation player for skeleton animations
@onready var _animation : AnimationPlayer = $skeleton/AnimationPlayer

# Navigation player for movement
@onready var _nav_agent : NavigationAgent3D = $NavigationAgent3D


# Called when the node enters the scene tree for the first time.
func _ready():
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	# Play idle until we see the player
	_animation.play("animation_library/Idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta : float) -> void:
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	# Ignore all processing while staggering or dead
	if _state == State.STAGGER or _state == State.DEAD:
		return

	# Test if we can see the target
	var seeing_target := can_see_target()

	# Handle state transitions
	if seeing_target:
		# Detect idle -> tracking
		if _state == State.IDLE:
			_animation.play("animation_library/Walk")
			$VoicePlayer3D.play()
			$FootstepPlayer3D.play()

		# Track visible target
		_state = State.TRACKING
		_duration = TRACKING_DURATION
	elif _state == State.TRACKING:
		# Handle tracking expiration
		_duration -= delta
		if _duration <= 0.0:
			_state = State.SEARCHING
			_duration = SEARCHING_DURATION
	elif _state == State.SEARCHING:
		# Handle searching expiration
		_duration -= delta
		if _duration <= 0.0:
			_state = State.IDLE
			_animation.play("animation_library/Idle")
			$FootstepPlayer3D.stop()

	# Skip if idle or staggering
	if _state == State.IDLE:
		return

	# If tracking then update target
	if _state == State.TRACKING:
		_nav_agent.target_position = target_body.global_position

	# Skip if we can't move to the target
	if _nav_agent.is_navigation_finished() or not _nav_agent.is_target_reachable():
		return

	# Calculate the movement
	var next := _nav_agent.get_next_path_position()
	var forward := (next - global_position).slide(Vector3.UP).normalized()

	# Turn to the navigation direction
	var right := forward.cross(Vector3.UP)
	var new_basis := Basis(right, Vector3.UP, -forward)
	global_transform.basis = global_transform.basis.slerp(
			new_basis, 
			delta * TURN_SPEED).orthonormalized()

	# Move in the direction being faced
	velocity = -global_transform.basis.z * MOVE_SPEED
	move_and_slide()


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


# Get configuration warnings
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Verify persistent ID is set
	if not persistent_id:
		warnings.append("Persistent ID not zet")

	# Verify target body is set
	if not target_body:
		warnings.append("Target body not set")

	# Verify target node is set
	if not target_node:
		warnings.append("Target node not set")

	# Return warnings
	return warnings


# This method loads the item state from [PersistentWorld].
func _load_state() -> void:
	# Restore the state
	var state = PersistentWorld.instance.get_value(persistent_id)
	if not state is Dictionary:
		return

	# Restore the location
	var location = state.get("location")
	if location is Transform3D:
		global_transform = location

	# Restore the health
	_health = state.get("health", 1.0)

	# If the item is dead then kill it
	if state.get("dead", false):
		_state = State.DEAD
		_animation.play("animation_library/Death_back")
		_animation.advance(99.9)


# This method saves the state to [PersistentWorld].
func _save_state() -> void:
	# Save the state information
	var state := {}
	state["location"] = global_transform
	state["health"] = _health
	state["dead"] = _state == State.DEAD
	PersistentWorld.instance.set_value(persistent_id, state)


# Test if we can see the target
func can_see_target() -> bool:
	# Get the sight transform and target position
	var sight_transform := _sight.global_transform
	var target_position := target_node.global_position

	# Calculate the forwards and to-target vectors
	var forwards := -sight_transform.basis.z
	var to_target := target_position - sight_transform.origin
	if forwards.angle_to(to_target.normalized()) > FIELD_OF_VIEW:
		return false

	_sight.target_position = _sight.to_local(target_position)
	_sight.force_raycast_update()
	return _sight.get_collider() == target_body


func _on_hit_area_body_entered(_body):
	# Ignore hit while staggering
	if _state == State.STAGGER:
		return

	# Switch to the hit sound
	$FootstepPlayer3D.stop()
	$HitPlayer3D.play()

	_health -= HIT_DAMAGE
	if _health > 0.0:
		# Trigger the stagger
		_state = State.STAGGER
		_animation.play("animation_library/Hit_01")
	else:
		# Died
		_state = State.DEAD
		_animation.play("animation_library/Death_back")


func _on_animation_finished(anim_name):
	match anim_name:
		"animation_library/Hit_01":
			# Hit finished, back to tracking
			_state = State.TRACKING
			_duration = TRACKING_DURATION
			$FootstepPlayer3D.play()
			_animation.play("animation_library/Walk")

		"animation_library/Death_back":
			# Dead, disable
			process_mode = Node.PROCESS_MODE_DISABLED
