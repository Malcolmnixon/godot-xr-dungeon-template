@tool
extends Node3D


var _tween : Tween

var _averager := XRToolsVelocityAveragerLinear.new(50)


func _ready():
	$Timer.timeout.connect(_flicker)
	$Timer.start()


func _process(delta : float):
	_averager.add_transform(delta, global_transform)


func _flicker() -> void:
	if _tween:
		_tween.kill()

	var velocity := _averager.velocity().length()
	var magnitude : float = max(0.1, 1.0 - velocity / 3.0)

	_tween = get_tree().create_tween()
	#_tween.tween_property($OmniLight3D, "omni_attenuation", randf_range(0.6, 1.2) / magnitude, 0.8)
	_tween.tween_property($OmniLight3D, "light_energy", randf_range(0.5, 1.5) * magnitude, 0.5)
