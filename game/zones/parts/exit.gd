extends Node3D


func _on_audio_stream_player_finished():
	GameState.quit_game()
