extends Node3D

var target_pnj_node: Node3D = null
var player_node: Node3D = null
var current_interrogation: Dictionary = {}
var cinematic_camera: Camera3D = null

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

	# On récupère l'index de la personne interrogée depuis les données
	var index = interrogation_data.get("person_index", -1)
	if index == -1:
		push_error("[Interrogatoire] ERREUR : person_index manquant dans interrogation_data")
		return

	# trouver le bon PNJ dans la scène via son person_index
	var pnjs = get_tree().get_nodes_in_group("PNJ")
	target_pnj_node = null
	for pnj in pnjs:
		# On suppose que ton script pnj.gd a bien : var person_index: int
		if pnj.person_index == index:
			# Comme avant : on déplace le parent du node PNJ
			target_pnj_node = pnj.get_parent()
			break

	if target_pnj_node:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		target_pnj_node.position = Vector3(-38, 0, -25)
		player_node.position = Vector3(-40, 0, -25)
		start_interrogatoire_cinematic()
	else:
		print("[Interrogatoire] ERREUR: PNJ non trouvé pour index ", index)



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
	# On coupe la caméra cinématique, on repasse sur la vue normale
	if cinematic_camera:
		cinematic_camera.current = false

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	current_interrogation = interrogation_data
	
	var pnj_name = interrogation_data.get("full_name", "")
	print("Nom du PNJ interrogé :", pnj_name)
	print("[Interrogatoire] Début pour: ", pnj_name)
	print("[Interrogatoire] Données complètes: ", interrogation_data)

	var lines: Array[Dictionary] = []

	# 1) Réaction d'ouverture
	var opening = interrogation_data.get("opening_reaction", "")
	if typeof(opening) == TYPE_STRING and not opening.is_empty():
		lines.append({ "name": pnj_name, "text": opening })

	# 2) Réponses de suspicion
	var susp_array = interrogation_data.get("suspicion_answers", [])
	for s in susp_array:
		if typeof(s) == TYPE_STRING and not s.is_empty():
			lines.append({ "name": pnj_name, "text": s })

	# 3) Répliques supplémentaires (extra)
	var extra_array = interrogation_data.get("extra_answers", [])
	for e in extra_array:
		if typeof(e) == TYPE_STRING and not e.is_empty():
			lines.append({ "name": pnj_name, "text": e })

	# Si jamais l'IA renvoie autre chose que prévu
	if lines.is_empty():
		print("[Interrogatoire] ⚠ Aucune ligne générée, fallback message.")
		lines.append({
			"name": pnj_name,
			"text": "Je n'ai rien de plus à dire."
		})

	print("[Interrogatoire] Lignes utilisées pour le dialogue :", lines)
	Dialogues.start_dialogue(lines, false)


func _on_dialogue_ended() -> void:
	if Global.interrogatoire_state == true:
		Global.interrogatoire_state = false
		print("Affichage du choix final")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		InterrogationUi.show_final_choice()

func _on_pnj_in_jail(person_index: int) -> void:
	print("PNJ envoyé en prison, index:", person_index)
	Global.current["people"][person_index]["in_jail"] = true
	get_tree().get_root().get_node("Map/PNJ"+str(person_index+1)).position = Vector3(-5, 0, 6.5) # position éloignée pour simuler la prison
	end_interrogatoire_scene()

func _on_pnj_released(person_index: int) -> void:
	print("PNJ relâché, index:", person_index)
	Global.current["people"][person_index]["in_jail"] = false
	get_tree().get_root().get_node("Map/PNJ"+str(person_index+1)).position = Global.current["people"][person_index].get("initial_position", Vector3(0,0,0))
	print("Position initiale rétablie à :", Global.current["people"][person_index]["initial_position"], "à la position :", Global.current["people"][person_index]["initial_position"])
	end_interrogatoire_scene()

func detect_if_killer(person_index: int) -> bool:
	var people = Global.current.get("people", [])
	if person_index >= 0 and person_index < people.size():
		return people[person_index].get("is_killer", false)
	return false

func end_interrogatoire_scene() -> void:
	# Fondu au noir avec résultat
	var fade_black = get_tree().get_root().get_node("Map/UI/FadeBlackTransi") as ColorRect
	fade_black.visible = true
	fade_black.modulate.a = 0.0
	print("Détecter si le coupable a été arrêté pour l'affichage du résultat...",detect_if_killer(current_interrogation.get("person_index", -1)))
	fade_black.get_node("ResultDay").text = "☠️ Le coupable a été arrêté !" if detect_if_killer(current_interrogation.get("person_index", -1)) else "Le coupable est toujours en liberté..."

	var tween := create_tween()
	tween.tween_property(fade_black, "modulate:a", 1.0, 1.0)
	await tween.finished
	
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
	
