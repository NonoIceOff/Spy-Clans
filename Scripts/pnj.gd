extends Node3D

@onready var name_text = get_node("../Name") as Label3D
var hover = false
var highlighted = false
var name_pnj = ""
var person_index: int = -1
var alive = true

var dialogue_lines: Array[Dictionary] = []

@onready var dialogue = get_tree().get_root().get_node("Dialogues") as Node

func initialize_pnj(name: String, lines: Array[Dictionary], is_alive: bool = true) -> void:
	name_pnj = name
	get_node("../Name").text = name_pnj
	dialogue_lines = lines
	alive = is_alive
	get_node("Outline").visible = false

func _ready() -> void:
	dialogue.dialogue_ended.connect(_on_dialogue_ended)


func _process(delta: float) -> void:
	name_text.visible = hover or highlighted
	var player = get_tree().get_first_node_in_group("Player")
	if player and alive:
		look_at(player.global_transform.origin, Vector3.UP)
	var distance_to_player = (player.global_transform.origin - global_transform.origin).length()
	get_node("Outline").scale = Vector3.ONE * clamp(distance_to_player / 50.0, 1.05, 1.5)
	get_node("../Name").scale = Vector3.ONE * clamp(distance_to_player / 4, 0.5, 1.5)


func show_name_label() -> void:
	hover = true

func hide_name_label() -> void:
	hover = false

func _input(event) -> void:
	if event is InputEventMouseButton and hover:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			var player := get_tree().get_root().get_node("Map/Player/CharacterBody3D") as Node
			
			if Global.interrogatoire_state or not alive:
				print("Interrogatoire en cours...")
				return

			if Global.dialogues_left <= 0:
				print("--- DEBUG INTERRO ---")
				print("InterrogationUi global:", InterrogationUi)
				if InterrogationUi:
					print("  class:", InterrogationUi.get_class())
					print("  script:", InterrogationUi.get_script())
					print("  has_method start_interrogation_confirm:", InterrogationUi.has_method("start_interrogation_confirm"))
				
				if InterrogationUi and InterrogationUi.has_method("start_interrogation_confirm"):
					print("Appel de start_interrogation_confirm avec index", person_index, "et nom", name_pnj)
					InterrogationUi.start_interrogation_confirm(person_index, name_pnj)
					player.in_cinematic = true
				else:
					print("InterrogationUi introuvable ou méthode 'start_interrogation_confirm' manquante.")
				return



			# Dialogues normaux tant qu'il en reste
			var dialogue := get_tree().get_root().get_node("Dialogues") as Node
			if dialogue.has_method("start_dialogue"):
				print("Starting dialogue with ", name_pnj)
				print("Dialogue lines: ", dialogue_lines)
				dialogue.call("start_dialogue", dialogue_lines)
				player.in_cinematic = true
				var player_camera := player.get_node("Pivot/Camera3D") as Camera3D
				player_camera.fov = 20

func _on_dialogue_ended() -> void:
	print("Dialogue ended")
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.in_cinematic = false	
		var player_camera := player.get_node("Pivot/Camera3D") as Camera3D
		player_camera.fov = 70
