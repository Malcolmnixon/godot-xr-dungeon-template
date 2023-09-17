extends OmniLight3D


var time_passed = 0.0
@export var timer : Timer

func _ready():
	timer.timeout.connect(restart)

func restart():
	omni_attenuation = randf_range(0.2, 0.6) * 2
	#omni_range = randf_range(5.0, 2.5) * 2
