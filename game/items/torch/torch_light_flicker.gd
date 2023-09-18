extends OmniLight3D


var time_passed = 0.0
@export var timer : Timer

var _tween : Tween

func _ready():
	timer.timeout.connect(restart)

func restart():
	if _tween:
		_tween.kill()

	_tween = get_tree().create_tween()
	_tween.tween_property(self, "omni_attenuation", randf_range(0.2, 0.6) * 2, 1.0)
