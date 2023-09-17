@tool
extends AnimatableBody3D


## Door swing
@export var swing := deg_to_rad(80)

## Door open state
@export var open := false : set = set_open

## Current tween
var _tween : Tween


func _ready():
	# Set initial value
	rotation.y = swing if open else 0.0


# Handle pointer events
func pointer_event(event : XRToolsPointerEvent) -> void:
	# When pressed, randomize the color
	if event.event_type == XRToolsPointerEvent.Type.PRESSED:
		open = not open


# Handle change of door open state
func set_open(p_open : bool) -> void:
	open = p_open
	if is_inside_tree():
		if _tween:
			_tween.kill()

		$AudioStreamPlayer3D.play()

		var target := swing if open else 0.0
		_tween = get_tree().create_tween()
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(self, "rotation:y", target, 2.0)
