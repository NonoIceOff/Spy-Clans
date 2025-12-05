extends Node

@onready var http = HTTPRequest.new()

var current
var last_round_json = {}
var person_index_by_name: Dictionary = {}
var request_mode: String = "round"   # "round" ou "interrogatoire"
var game_alive = false
var dialogue_history: Array[Dictionary] = []
var dialogues_left = 3
var day_index = 1
var lives = 2

var interrogatoire_state = false

# Système de retry
var max_retries := 3
var current_retry := 0
var retry_delay := 2.0
var pending_request: Dictionary = {}
var use_fallback_model := false

signal round_generated
signal interrogation_generated
signal interrogation_in_generation


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

var player_journal_text: String = ""

func add_journal_line(line: String) -> void:
	player_journal_text += line + "\n"

func get_player_journal_text() -> String:
	return player_journal_text

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
	print("Notes :", p.get("notes", "Aucune note"))

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
	current_retry = 0
	use_fallback_model = false
	
	var model = "gemini-2.5-flash-lite" if not use_fallback_model else "gemini-2.5-flash"
	var url = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s" % [model, ENV.APIKEY]
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

	pending_request = {
		"url": url,
		"headers": headers,
		"body": body
	}
	print("current : ", JSON.stringify(current))

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
		"player_journal": target.get("notes")
	}

	# 🔍 DEBUG COURT
	print("[Interrogatoire] Envoi pour :", name)
	
	# Émettre le signal pour préparer la cinématique
	interrogation_in_generation.emit({"full_name": name})


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


# ---------------------------------------------------------
# REPONSE HTTP
# ---------------------------------------------------------
func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		var error_msg = body.get_string_from_utf8()
		print("Erreur HTTP :", error_msg)
		
		# Retry en cas d'erreur 503 (overload)
		if response_code == 503 and current_retry < max_retries:
			current_retry += 1
			var wait_time = retry_delay * current_retry
			print("Réessai %d/%d dans %.1f secondes..." % [current_retry, max_retries, wait_time])
			await get_tree().create_timer(wait_time).timeout
			
			if pending_request.has("url"):
				http.request(
					pending_request["url"],
					pending_request["headers"],
					HTTPClient.METHOD_POST,
					JSON.stringify(pending_request["body"])
				)
			return
		
		# Fallback vers gemini-2.5-flash après 3 échecs
		if response_code == 503 and not use_fallback_model:
			print("Échec après %d tentatives, basculement vers gemini-2.5-flash..." % max_retries)
			use_fallback_model = true
			current_retry = 0
			
			# Reconstruire l'URL avec le nouveau modèle
			var model = "gemini-2.5-flash"
			var new_url = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s" % [model, ENV.APIKEY]
			pending_request["url"] = new_url
			
			http.request(
				new_url,
				pending_request["headers"],
				HTTPClient.METHOD_POST,
				JSON.stringify(pending_request["body"])
			)
			return
		
		print("Échec définitif après basculement vers le modèle de secours")
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
		
		# Retry si JSON invalide
		if current_retry < max_retries:
			current_retry += 1
			var wait_time = retry_delay * current_retry
			print("JSON invalide, réessai %d/%d dans %.1f secondes..." % [current_retry, max_retries, wait_time])
			await get_tree().create_timer(wait_time).timeout
			
			if pending_request.has("url"):
				http.request(
					pending_request["url"],
					pending_request["headers"],
					HTTPClient.METHOD_POST,
					JSON.stringify(pending_request["body"])
				)
			return
		
		print("Échec définitif : JSON invalide après %d tentatives" % max_retries)
		return

	if request_mode == "round":
		_handle_round_response(parsed)
		emit_signal("round_generated")
	else:
		emit_signal("interrogation_in_generation", parsed)
		_handle_interrogation_response(parsed)


# ---------------------------------------------------------
# TRAITEMENT JOUR
# ---------------------------------------------------------
func _handle_round_response(game_json: Dictionary) -> void:
	var meta = game_json.get("meta", {})
	print("Méta reçue :", meta)

	if meta.has("killer_full_name"):
		current["killer_full_name"] = meta["killer_full_name"]
		print("[ROUND] Coupable pour ce jour :", current["killer_full_name"])
		print("tests ",current)

	if meta.has("new_victim"):
		var victim = meta["new_victim"]
		current["victims"].append(victim)

		var vname = victim.get("full_name", "")
		if person_index_by_name.has(vname):
			current["people"][ person_index_by_name[vname] ]["alive"] = false
		
		print("[ROUND] Nouvelle victime : ", vname, " | Total morts : ", current["victims"].size())
	else:
		var day = current.get("day_index", 1)
		if day >= 2:
			push_error("[ROUND] ERREUR CRITIQUE : Aucune nouvelle victime générée pour le jour ", day, " ! Le jeu nécessite 1 mort par jour à partir du jour 2.")
		else:
			print("[ROUND] Jour 1 : Aucune victime (normal)")

	# Mettre à jour UNIQUEMENT les dialogues et l'histoire du jour
	# NE JAMAIS toucher aux noms, personnalités, âges, relations
	current["day_story"] = game_json.get("day_story", "")
	
	# Mettre à jour les dialogues EN PRÉSERVANT les infos existantes des personnages
	var new_dialogues = game_json.get("campfire_dialogues", [])
	for new_dialogue in new_dialogues:
		var name = new_dialogue.get("full_name", "")
		# Vérifier que ce personnage existe dans notre liste
		if person_index_by_name.has(name):
			var person_index = person_index_by_name[name]
			# On ne met à jour QUE les dialogues, pas les infos du personnage
			# Les infos (age, personality, relation) restent intactes dans current["people"]
			pass
	
	current["campfire_dialogues"] = new_dialogues

	print("[ROUND] Journée générée.")


# ---------------------------------------------------------
# TRAITEMENT INTERROGATOIRE
# ---------------------------------------------------------
func _handle_interrogation_response(interro_json: Dictionary) -> void:
	var interrogation = interro_json["interrogation"]
	current["last_interrogation"] = interrogation

	print("[Interrogatoire] reçu pour :", interrogation.get("full_name"))
	print ("voici le text", interrogation)
	interrogation_generated.emit(interrogation)

func start_new_day() -> void:
	# Incrémenter le jour SANS régénérer les personnages
	current["day_index"] += 1
	
	# Réinitialiser uniquement les variables de gameplay
	Global.game_alive = true
	Global.dialogues_left = 3
	Global.dialogue_history.clear()
	
	# Générer UNIQUEMENT la nouvelle histoire et les nouveaux dialogues
	# Les noms, personnalités, âges et relations restent intacts
	Global.generate_round()


func remove_life() -> void:
	get_tree().get_root().get_node("Map/Sounds").play()
	lives -= 1


func end_game() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game_alive = false
	# cinématique de fin de partie
	var cinematic_camera := get_tree().get_root().get_node("Map/CinematicCamera")
	cinematic_camera.position = Vector3(0, 4, 0)
	cinematic_camera.current = true
	# mettre sur la scène menu
	reset_data()
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")

func reset_data() -> void:
	current = Variable.write_game_state(2)
	_rebuild_person_index()
	dialogue_history.clear()
	dialogues_left = 3
	day_index = 1
	lives = 2
	game_alive = true