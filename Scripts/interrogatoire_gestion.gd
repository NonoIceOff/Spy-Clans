extends Node3D

var target_pnj_node: Node3D = null
var player_node: Node3D = null
var current_interrogation: Dictionary = {}
var cinematic_camera: Camera3D = null
var end_state = "liberty"
var pnj_index = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_node = get_tree().get_root().get_node("Map/Player") 
	Global.interrogation_generated.connect(start_interrogatoire)
	Global.interrogation_in_generation.connect(init_pnj_interrogatoire)
	Dialogues.dialogue_ended.connect(_on_dialogue_ended)
	InterrogationUi.connect("pnj_in_jail", _on_pnj_in_jail)
	InterrogationUi.connect("pnj_released", _on_pnj_released)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func init_pnj_interrogatoire(interrogation_data: Dictionary) -> void:
	Global.interrogatoire_state = true
	# trouver le PNJ dans la scène
	var pnjs = get_tree().get_nodes_in_group("PNJ")
	for pnj in pnjs:
		if pnj.name_pnj == interrogation_data.get("full_name", ""):
			target_pnj_node = pnj.get_parent()
			break

	if target_pnj_node:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		target_pnj_node.position = Vector3(-38, 0, -25)
		player_node.position = Vector3(-40, 0, -25)
		start_interrogatoire_cinematic()
	else:
		print("[Interrogatoire] ERREUR: PNJ non trouvé pour ", interrogation_data.get("full_name", ""))




func start_interrogatoire_cinematic() -> void:
	if target_pnj_node == null or player_node == null:
		print("[Interrogatoire] ERREUR: target_pnj_node ou player_node est null.")
		return
	
	cinematic_camera = get_tree().get_root().get_node("Map/CinematicCamera") as Camera3D
	cinematic_camera.current = true
	cinematic_camera.position = Vector3(-39, 4, -30)
	cinematic_camera.look_at(Vector3(-39, 0, -25), Vector3.UP)
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	var pnj_target_position = Vector3(-38, 0, -25)
	var player_target_position = Vector3(-40, 0, -25)
	
	tween.tween_property(target_pnj_node, "position", pnj_target_position, 2.0)
	tween.tween_property(player_node, "position", player_target_position, 2.0)

func start_interrogatoire(interrogation_data: Dictionary) -> void:
	cinematic_camera.current = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	current_interrogation = interrogation_data
	
	# récupérer le nom du PNJ à interroger
	var pnj_name = interrogation_data.get("full_name", "")
	print("Nom du PNJ interrogé :", pnj_name)
	print("[Interrogatoire] Début pour: ", pnj_name)
	print("[Interrogatoire] Questions: ", interrogation_data.get("questions", []))
	
	# convertir les questions en Array[Dictionary] (car on a décidé comme ça)
	var questions_array: Array[Dictionary] = []
	var raw_questions = interrogation_data.get("suspicion_answers", [])
	for q in raw_questions:
		if q is Dictionary:
			questions_array.append({"name": pnj_name, "text": q})
	
	Dialogues.start_dialogue(questions_array, false)

func _on_dialogue_ended() -> void:
	if Global.interrogatoire_state == true:
		Global.interrogatoire_state = false
		print("Affichage du choix final")
		InterrogationUi.show_final_choice()

func _on_pnj_in_jail(person_index: int) -> void:
	print("PNJ envoyé en prison, index:", person_index)
	pnj_index = person_index
	end_state = "jail"
	Global.current["people"][person_index]["in_jail"] = true
	get_tree().get_root().get_node("Map/PNJ"+str(person_index+1)).position = Vector3(-5, 0, 6.5) # position éloignée pour simuler la prison
	end_interrogatoire_scene()
	

func _on_pnj_released(person_index: int) -> void:
	print("PNJ relâché, index:", person_index)
	pnj_index = person_index
	end_state = "liberty"
	print(pnj_index)
	Global.current["people"][person_index]["in_jail"] = false
	get_tree().get_root().get_node("Map/PNJ"+str(person_index+1)).position = Global.current["people"][person_index].get("initial_position", Vector3(0,0,0))
	print("Position initiale rétablie à :", Global.current["people"][person_index]["initial_position"], "à la position :", Global.current["people"][person_index]["initial_position"])
	end_interrogatoire_scene()

func detect_if_killer(person_index: int) -> bool:
	print("[INTERRO] Détection du coupable pour l'index de la personne :", person_index)
	var people = Global.current.get("people", [])
	if Global.current.has("killer_full_name"):
		var killer_name = Global.current["killer_full_name"]
		print("[INTERRO] Coupable pour ce jour :", killer_name)
		var person_name = people[person_index].get("full_name", "")
		print("[INTERRO] Nom de la personne interrogée :", person_name)
		print("[INTERRO] Correspondance des noms :", str(person_name) == str(killer_name))
		return str(person_name) == str(killer_name)
	return false

func end_interrogatoire_scene() -> void:
	# Fondu au noir avec résultat
	var fade_black = get_tree().get_root().get_node("Map/UI/FadeBlackTransi") as ColorRect
	fade_black.visible = true
	fade_black.modulate.a = 0.0
	var if_killer = detect_if_killer(pnj_index)
	print("Coupable ? ", if_killer)
	print("État final :", end_state)

	if if_killer and end_state == "jail":
		fade_black.get_node("ResultDay").text = "☠️ Le coupable a été arrêté !"
		Global.end_game()
	else: # not if_killer and end_state == "liberty"
		fade_black.get_node("ResultDay").text = "Le coupable est toujours en liberté..."
		Global.remove_life()

	var tween := create_tween()
	tween.tween_property(fade_black, "modulate:a", 1.0, 1.0)
	await tween.finished

	if if_killer and end_state == "jail":
		return
	
	# Afficher le résultat pendant 3 secondes
	await get_tree().create_timer(3.0).timeout
	
	# Repositionner pendant le noir
	if cinematic_camera:
		cinematic_camera.current = false
	
	get_tree().get_root().get_node("Map/Player").position = Vector3(4.923, 0, 0)
	
	# Afficher l'écran de chargement
	fade_black.get_node("ResultDay").visible = false
	get_tree().get_root().get_node("Map/UI/LoadingBack").visible = true
	
	# Générer le nouveau jour (pendant le chargement)
	Global.start_new_day()
	
	# Attendre que la génération soit complète (le signal round_generated sera émis)
	await Global.round_generated
	
	# Cacher le chargement et faire le fondu retour
	get_tree().get_root().get_node("Map/UI/LoadingBack").visible = false
	
	var tween2 := create_tween()
	tween2.tween_property(fade_black, "modulate:a", 0.0, 1.0)
	await tween2.finished
	
	fade_black.visible = false
	fade_black.get_node("ResultDay").visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
