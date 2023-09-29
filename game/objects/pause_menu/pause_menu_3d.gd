extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	# Subscribe to button events
	var controller := XRHelpers.get_xr_controller(self)
	if controller:
		controller.button_pressed.connect(_on_button_pressed)

	# Initially hide menu
	_show_menu(false)


func _on_button_pressed(p_name : String) -> void:
	if p_name == "menu_button":
		_show_menu(not visible)


func _show_menu(show := true) -> void:
	visible = show
	$PauseMenu.enabled = show
	get_tree().paused = show
	

func _on_save_pressed():
	_show_menu(false)
	GameState.save_game()


func _on_quit_pressed():
	_show_menu(false)
	GameState.quit_game()
