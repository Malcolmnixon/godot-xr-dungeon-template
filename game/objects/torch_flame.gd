@tool
extends Node3D


var _tween : Tween


func _ready():
	$Timer.timeout.connect(_flicker)
	$Timer.start()


func _flicker() -> void:
	if _tween:
		_tween.kill()

	_tween = get_tree().create_tween()
	_tween.tween_property($OmniLight3D, "omni_attenuation", randf_range(0.3, 0.6) * 2, 0.8)
