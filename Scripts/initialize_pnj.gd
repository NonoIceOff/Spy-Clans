extends Node3D

func _ready() -> void:
	# récupérer les infos des personnages depuis Global
	var peoples = Global.current.get("people", [])
	var campfire_dialogues = Global.current.get("campfire_dialogues", [])
	
	# récupérer tous les nodes PNJ via leur groupe
	var pnjs := get_tree().get_nodes_in_group("PNJ")
	print("PNJS INITIALISÉS :", pnjs.size())
	for index in range(pnjs.size()):
		var pnj = pnjs[index]
		
		if pnj.has_method("initialize_pnj"):
			var name_pnj := "PNJ Inconnu"
			var dialogue_lines: Array[Dictionary] = []
			var is_alive := true
			
			# on récupère le nom et le statut
			if index < peoples.size():
				name_pnj = peoples[index].get("full_name", "PNJ Inconnu")
				is_alive = peoples[index].get("alive", true)
				
				# Afficher le prénom sur la pancarte
				get_node("../seatNode0"+str(index+1)+"/Sign").visible = true
				var sign_label = get_node("../seatNode0"+str(index+1)+"/Sign/Label3D")
				sign_label.text = name_pnj
				
				# Si mort, ajouter le crâne et changer la couleur
				if not is_alive:
					sign_label.text += "\n☠️"
					sign_label.modulate = Color(1, 0, 0, 1.0)
			# on recherche le dialogue correspondant
			for dialogue_entry in campfire_dialogues:
				if dialogue_entry.get("full_name", "") == name_pnj:
					var lines_raw = dialogue_entry.get("lines", [])
					for line in lines_raw:
						if typeof(line) == TYPE_STRING:
							dialogue_lines.append({"name": name_pnj, "text": line})
						elif typeof(line) == TYPE_DICTIONARY:
							dialogue_lines.append(line)
					break
			
			# si pas de dialogue, en créer par défaut (n'arrive normalement pas)
			if dialogue_lines.is_empty():
				dialogue_lines = [
					{"name": name_pnj, "text": "Bonjour."},
					{"name": name_pnj, "text": "Que puis-je faire pour vous ?"}
				]

			pnj.person_index = index
			pnj.initialize_pnj(name_pnj, dialogue_lines, is_alive)
			
			# Sauvegarder la position initiale
			if not Global.current["people"][index].has("initial_position"):
				Global.current["people"][index]["initial_position"] = pnj.get_node("../").position

			# Si le PNJ est mort, le transformer en cadavre
			if not is_alive:
				print("PNJ ", name_pnj, " est mort, transformation en cadavre.")
				pnj.get_node("../").rotation.x = -80.0
				pnj.get_node("../").position.y = 0.5

func update_signs() -> void:
	# Fonction pour mettre à jour toutes les pancartes
	var peoples = Global.current.get("people", [])
	var pnjs := get_tree().get_nodes_in_group("PNJ")
	
	for index in range(min(pnjs.size(), peoples.size())):
		var name_pnj = peoples[index].get("full_name", "PNJ Inconnu")
		var is_alive = peoples[index].get("alive", true)
		var pnj = pnjs[index]
		
		var sign_label = get_node("../seatNode0"+str(index+1)+"/Sign/Label3D")
		sign_label.text = name_pnj
		
		if not is_alive:
			sign_label.text += "\n☠️"
			sign_label.modulate = Color(1, 0, 0, 1.0)
			
			# Transformer en cadavre si pas déjà fait
			if pnj.get_node("../").rotation.x > -70.0:
				pnj.get_node("../").rotation.x = -80.0
				pnj.get_node("../").position.y = 0.5
		else:
			sign_label.modulate = Color(1, 1, 1, 1.0)

func _process(delta: float) -> void:
	pass
