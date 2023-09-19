extends CharacterBody3D


## Skeleton states
enum State {
	IDLE,		## Idle
	CHASING		## Chasing target
}


## Movement speed
const MOVE_SPEED := 2.0

## Turn speed
const TURN_SPEED := 3.0

## Field of view
const FIELD_OF_VIEW := deg_to_rad(80)

## Memory duration
const MEMORY := 10.0


## Target node
@export var target_node : Node3D


# Current state
var _state := State.IDLE

# Remaining memory time
var _memory := 0.0


# Sight raycast
@onready var _sight : RayCast3D = $Sight

# Animation player for skeleton animations
@onready var _animation : AnimationPlayer = $skeleton/AnimationPlayer

# Navigation player for movement
@onready var _nav_agent : NavigationAgent3D = $NavigationAgent3D


# Called when the node enters the scene tree for the first time.
func _ready():
	# Play idle until we see the player
	_animation.play("animation_library/Idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta : float) -> void:
	# Test if we can see the target
	var seeing_target := can_see_target()

	# Handle state transitions
	if seeing_target:
		# Detect start of chase
		if _state == State.IDLE:
			# Start the chase
			_state = State.CHASING
			_animation.play("animation_library/Walk")
			$VoicePlayer3D.play()
			$FootstepPlayer3D.play()

		# Refresh our memory
		_memory = MEMORY

		# Lock in the target location
		_nav_agent.target_position = target_node.global_position
	elif _state == State.CHASING:
		# Handle memory decay
		_memory -= delta
		if _memory < 0.0:
			_state = State.IDLE
			_animation.play("animation_library/Idle")
			$FootstepPlayer3D.stop()

	# Skip moving if idle
	if _state == State.IDLE:
		return

	# Skip if we can't move to the target
	if _nav_agent.is_navigation_finished() or not _nav_agent.is_target_reachable():
		return

	# Calculate the movement
	var next := _nav_agent.get_next_path_position()
	var forward := (next - global_position).slide(Vector3.UP).normalized()

	# Turn to face the target
	var right := forward.cross(Vector3.UP)
	var new_basis := Basis(right, Vector3.UP, -forward)
	global_transform.basis = global_transform.basis.slerp(
			new_basis, 
			delta * TURN_SPEED).orthonormalized()

	# Move towards the target
	velocity = forward * MOVE_SPEED
	move_and_slide()


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
	return _sight.get_collider() == target_node
