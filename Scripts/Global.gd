extends Node

@onready var http = HTTPRequest.new()

var current
var last_round_json = {}
var person_index_by_name: Dictionary = {}
var request_mode: String = "round"   # "round" ou "interrogatoire"

signal round_generated


func _ready():
	add_child(http)
	http.request_completed.connect(_on_request_completed)
	current = Variable.write_game_state(2)
	_rebuild_person_index()


# ---------------------------------------------------------
# BUILD DICTIONNAIRE { nom -> index }
# ---------------------------------------------------------
func _rebuild_person_index() -> void:
	person_index_by_name.clear()
	if current == null or not current.has("people"):
		return

	for i in current["people"].size():
		var name: String = current["people"][i].get("full_name", "")
		if name != "":
			person_index_by_name[name] = i


# ---------------------------------------------------------
# DEBUG : Voir les données d'un personnage
# ---------------------------------------------------------
func debug_person_data(person_index: int) -> void:
	if not current.has("people"):
		print("No people in current.")
		return

	if person_index < 0 or person_index >= current["people"].size():
		print("Index hors limites.")
		return

	var p = current["people"][person_index]

	print("=== DEBUG PERSON ===")
	print("Nom :", p.get("full_name"))
	print("Age :", p.get("age"))
	print("Personnalité :", p.get("personality"))
	print("Relation :", p.get("relation_to_player"))
	print("Alive :", p.get("alive"))

	if current.has("campfire_dialogues"):
		for entry in current["campfire_dialogues"]:
			if entry.get("full_name", "") == p.get("full_name", ""):
				print("État au feu :", entry.get("emotional_state"))
				print("Lignes :", entry.get("lines"))
				break


# ---------------------------------------------------------
# GENERATION JOUR
# ---------------------------------------------------------
func generate_round():
	request_mode = "round"
	
	var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key="+ENV.APIKEY
	var headers = ["Content-Type: application/json"]

	print("Génération du jour...")

	var body = {
		"generationConfig": {
			"temperature": 0.5,
			"topP": 0.8,
			"topK": 40
		},
		"contents": [
			{
				"role": "user",
				"parts": [
					{ "text": Prompt.Generate + "\n\nGAME_STATE_JSON:\n" + JSON.stringify(current) }
				]
			}
		]
	}

	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))


# ---------------------------------------------------------
# GENERER INTERROGATOIRE POUR PERSO
# ---------------------------------------------------------
func generate_interrogation_for_person(person_index: int, player_journal: String) -> void:
	if not current.has("people"):
		push_error("No people in current")
		return

	var people = current["people"]
	if person_index < 0 or person_index >= people.size():
		push_error("Invalid index")
		return

	request_mode = "interrogation"

	var target = people[person_index]
	var name = target["full_name"]

	# Dialogue du feu
	var campfire_for_person = {"emotional_state": "", "lines": []}
	if current.has("campfire_dialogues"):
		for entry in current["campfire_dialogues"]:
			if entry.get("full_name", "") == name:
				campfire_for_person = {
					"emotional_state": entry.get("emotional_state", ""),
					"lines": entry.get("lines", [])
				}
				break

	var is_killer = (current.get("killer_full_name", "") == name)

	var interrogation_input = {
		"day_index": current.get("day_index"),
		"target_person": {
			"full_name": name,
			"age": target.get("age"),
			"personality": target.get("personality"),
			"relation_to_player": target.get("relation_to_player"),
			"is_killer": is_killer
		},
		"day_story": current.get("day_story", ""),
		"campfire_dialogue_for_person": campfire_for_person,
		"victims": current.get("victims", []),
		"eliminations": current.get("eliminations", []),
		"player_journal": player_journal
	}

	# 🔍 DEBUG COURT
	print("[Interrogatoire] Envoi pour :", name)

	var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key="+ENV.APIKEY
	var headers = ["Content-Type: application/json"]

	var user_text = Prompt.SYSTEM_PROMPT_INTERROGATION + "\n\nINTERROGATION_INPUT_JSON:\n" + JSON.stringify(interrogation_input)

	var body = {
		"generationConfig": {
			"temperature": 0.6,
			"topP": 0.9,
			"topK": 40
		},
		"contents": [
			{
				"role": "user",
				"parts": [ { "text": user_text } ]
			}
		]
	}

	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))


func generate_interrogation_for_second(player_journal: String) -> void:
	generate_interrogation_for_person(1, player_journal)


# ---------------------------------------------------------
# REPONSE HTTP
# ---------------------------------------------------------
func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("Erreur HTTP :", body.get_string_from_utf8())
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null:
		print("Réponse IA illisible")
		return

	var text: String = data["candidates"][0]["content"]["parts"][0]["text"]
	text = text.strip_edges()

	if text.begins_with("```"):
		var first = text.find("\n")
		var last = text.rfind("```")
		text = text.substr(first + 1, last - first - 1).strip_edges()

	var parsed = JSON.parse_string(text)
	if parsed == null:
		print("JSON renvoyé incorrect :", text)
		return

	if request_mode == "round":
		_handle_round_response(parsed)
		emit_signal("round_generated")
	else:
		_handle_interrogation_response(parsed)


# ---------------------------------------------------------
# TRAITEMENT JOUR
# ---------------------------------------------------------
func _handle_round_response(game_json: Dictionary) -> void:
	var meta = game_json.get("meta", {})

	if meta.has("killer_full_name"):
		current["killer_full_name"] = meta["killer_full_name"]

	if meta.has("new_victim"):
		var victim = meta["new_victim"]
		current["victims"].append(victim)

		var vname = victim.get("full_name", "")
		if person_index_by_name.has(vname):
			current["people"][ person_index_by_name[vname] ]["alive"] = false

	current["day_story"] = game_json.get("day_story", "")
	current["campfire_dialogues"] = game_json.get("campfire_dialogues", [])

	print("[ROUND] Journée générée.")


# ---------------------------------------------------------
# TRAITEMENT INTERROGATOIRE
# ---------------------------------------------------------
func _handle_interrogation_response(interro_json: Dictionary) -> void:
	var interrogation = interro_json["interrogation"]
	current["last_interrogation"] = interrogation

	print("[Interrogatoire] reçu pour :", interrogation.get("full_name"))
