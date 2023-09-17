extends CenterContainer


func _on_start_button_pressed():
	GameState.new_game(GameState.GameDifficulty.GAME_NORMAL)
