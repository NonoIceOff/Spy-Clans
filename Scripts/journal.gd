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

@onready var character_list := $CharacterList


func _ready() -> void:
	visible = false
	
	var peoples = Global.current.get("people", [])
	if peoples.is_empty():
		peoples = [{ "full_name": "Nina Garnier", "age": 19, "personality": "perfectionniste et controle freak", "relation_to_player": "ami de longue date", "alive": true }, { "full_name": "Alex Leroy", "age": 19, "personality": "introverti mais attentif aux autres", "relation_to_player": "amie d enfance", "alive": true }, { "full_name": "Emma Martin", "age": 28, "personality": "empathique mais anxieux", "relation_to_player": "partenaire de sport", "alive": true }, { "full_name": "Leo Garnier", "age": 29, "personality": "suspicieux mais protecteur", "relation_to_player": "meilleur ami", "alive": true }, { "full_name": "Yanis Laurent", "age": 25, "personality": "introverti mais attentif aux autres", "relation_to_player": "ami de soiree", "alive": false }, { "full_name": "Sarah Durand", "age": 24, "personality": "sarcastique mais loyal", "relation_to_player": "ami proche", "alive": true }, { "full_name": "Sarah Laurent", "age": 32, "personality": "suspicieux mais protecteur", "relation_to_player": "ami de longue date", "alive": true }, { "full_name": "Sarah Dupont", "age": 29, "personality": "tres optimiste, parfois naive", "relation_to_player": "ami de soiree", "alive": true }, { "full_name": "Sarah Blanc", "age": 19, "personality": "direct et parfois blessant", "relation_to_player": "amie d enfance", "alive": true }]
	print("PEOPLES :", peoples)
	# on reconstruit le tableau des personnages
	characters = []
	if typeof(peoples) == TYPE_ARRAY:
		for p in peoples:
			var name := "Inconnu"
			var personality := "Inconnu"
			if typeof(p) == TYPE_DICTIONARY:
				if p.has("full_name"):
					name = str(p.get("full_name"))
				if p.has("personality"):
					personality = str(p.get("personality"))
			characters.append({"name": name, "personality": personality})
	_initialize_list()
	show_history_dialogues()

func _initialize_list() -> void:
	# créer les boutons sur la liste pour chaque perso
	for i in range(min(characters.size(), 9)):
		print("Création entrée journal pour :", characters[i]["name"])
		var panel := get_node("CharacterList")
		var button = Button.new()
		button.text = characters[i]["name"]
		button.add_theme_font_override("font", load("res://Fonts/PixelifySans-VariableFont_wght.ttf"))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.connect("pressed", Callable(self, "_on_character_button_pressed").bind(i))
		panel.add_child(button)


func _on_character_button_pressed(index: int) -> void:
	# afficher les notes du personnage sélectionné
	print("Personnage sélectionné :", characters[index]["name"])
	var button := character_list.get_child(index)
	get_node("CharacterInfos").visible = true
	get_node("HistoryInfos").visible = false
	print("PANEL :", button)
	if button:
		var text_name := get_node("CharacterInfos/Name") as Label
		text_name.text = characters[index]["name"]
		var text_personality := get_node("CharacterInfos/Personality") as Label
		text_personality.text = "Personnalité : %s" % characters[index]["personality"]
		var text_edit := get_node("CharacterInfos/TextEdit") as TextEdit
		if text_edit:
			text_edit.grab_focus()


func get_all_notes() -> Array[Dictionary]:
	# c'est la que sont stockées les notes
	var notes: Array[Dictionary] = []
	
	for i in range(min(characters.size(), 9)):
		var panel := character_list.get_child(i) as VBoxContainer
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

func show_history_dialogues() -> void:
	# afficher l'historique des dialogues
	var history_panel = get_node("HistoryInfos") as Control
	
	var history_rich_text = history_panel.get_node("RichTextLabel") as RichTextLabel
	
	history_rich_text.clear()
	history_rich_text.text = "[b]Historique des dialogues[/b]\n\n"
	print("Dialogue history :", Global.dialogue_history)
	for entry in Global.dialogue_history:
		var name = entry.get("name", "Inconnu")
		history_rich_text.text += "[u]%s[/u]\n" % name
		var lines = entry.get("lines", [])
		for line in lines:
			var text = line.get("text", "")
			history_rich_text.text += "%s\n" % text
		history_rich_text.text += "\n"


func _on_history_button_pressed() -> void:
	show_history_dialogues()
	get_node("CharacterInfos").visible = !get_node("CharacterInfos").visible
	get_node("HistoryInfos").visible = !get_node("HistoryInfos").visible
