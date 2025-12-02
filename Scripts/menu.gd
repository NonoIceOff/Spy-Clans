extends Control

func _ready() -> void:
	# On se connecte au signal envoye par Global quand la generation est terminee
	if not Global.round_generated.is_connected(_on_round_generated):
		Global.round_generated.connect(_on_round_generated)


func _on_play_button_pressed() -> void:
	# Quand on clique sur Jouer, on lance d abord la generation du premier jour
	# La scene ne sera changee qu une fois la reponse IA recue
	print("PLAY clique -> generation du premier jour")
	Global.generate_round()
	


func _on_round_generated() -> void:
	# Cette fonction est appelee quand Global a fini de generer le round
	print("=== ROUND GENERE (recu dans la scene du bouton) ===")

	# 1) Recuperer le tueur (debug, pour toi dev)
	var killer_name: String = Global.current.get("killer_full_name", "Inconnu")
	print("DEBUG - Le meurtrier est :", killer_name)

	# 2) Exemple : lancer un interrogatoire de la 2e personne (index 1)
	# Tu pourras plus tard appeler ca depuis un autre endroit ou avec un vrai journal du joueur
	var journal_test := "Je trouve ton comportement etrange par rapport a ce que tu as dit autour du feu."
	Global.generate_interrogation_for_second(journal_test)

	# 3) Une fois que le round est pret, on peut changer de scene vers la map
	get_tree().change_scene_to_file("res://Scenes/map.tscn")
