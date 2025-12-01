extends Control

# données de tests
var characters: Array[Dictionary] = [
	{"name": "Jacques Dupont", "personality": "Aigri"},
	{"name": "Marie Leblanc", "personality": "Joyeuse"},
	{"name": "Pierre Martin", "personality": "Mystérieux"},
	{"name": "Sophie Bernard", "personality": "Nerveuse"},
	{"name": "Luc Petit", "personality": "Calme"},
	{"name": "Emma Dubois", "personality": "Méfiante"},
	{"name": "Thomas Laurent", "personality": "Arrogant"},
	{"name": "Julie Simon", "personality": "Gentille"},
	{"name": "Nicolas Moreau", "personality": "Sérieux"}
]

@onready var grid_container := $GridContainer


func _ready() -> void:
	_initialize_journal()


func _initialize_journal() -> void:
	# Initialiser chaque panneau avec les données des personnages
	for i in range(min(characters.size(), 9)):
		var panel := grid_container.get_child(i) as VBoxContainer
		if panel:
			var name_label := panel.get_node("Name") as Label
			var personality_label := panel.get_node("Personnalite") as Label
			
			if name_label:
				name_label.text = characters[i]["name"]
			if personality_label:
				personality_label.text = characters[i]["personality"]


func get_all_notes() -> Array[Dictionary]:
	# c'est la que sont stockées les notes
	var notes: Array[Dictionary] = []
	
	for i in range(min(characters.size(), 9)):
		var panel := grid_container.get_child(i) as VBoxContainer
		if panel:
			var text_edit := panel.get_node("TextEdit") as TextEdit
			if text_edit:
				notes.append({
					"name": characters[i]["name"],
					"personality": characters[i]["personality"],
					"note": text_edit.text
				})
	
	return notes


func print_notes() -> void:
	# on affiche les notes pour les tests
	var notes := get_all_notes()
	print("=== NOTES DU JOURNAL ===")
	for note in notes:
		print("---")
		print("Nom: ", note["name"])
		print("Personnalité: ", note["personality"])
		print("Note: ", note["note"] if note["note"] != "" else "[Aucune note]")
	print("========================")
