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
			
			# on récupère le nom
			if index < peoples.size():
				name_pnj = peoples[index].get("full_name", "PNJ Inconnu")
			
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
			
			pnj.initialize_pnj(name_pnj, dialogue_lines)

			if Global.current["victims"][0]["full_name"] == name_pnj:
				print("PNJ ", name_pnj, " est une victime, il se transforme en cadavre.")
				pnj.get_node("../").rotation.x = -80.0
				pnj.get_node("../").position = Vector3(0, 0.5, 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
