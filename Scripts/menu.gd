extends Control

func _on_play_button_pressed() -> void:
	# Quand on clique sur Jouer, on lance d abord la generation du premier jour
	# La scene ne sera changee qu une fois la reponse IA recue
	print("PLAY clique -> generation du premier jour")
	Global.generate_round()
	get_tree().change_scene_to_file("res://Scenes/loading_screen.tscn")
