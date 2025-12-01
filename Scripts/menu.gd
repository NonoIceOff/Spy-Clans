extends Control


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/map.tscn")
	Global.generate_round()
