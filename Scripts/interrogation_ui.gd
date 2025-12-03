extends Control

var current_person_index: int = -1
var current_person_name: String = ""

@onready var confirm_panel := $ConfirmPanel
@onready var confirm_label := $ConfirmPanel/Label
@onready var question_panel := $QuestionPanel
@onready var question_label := $QuestionPanel/Label
@onready var button_alibi := $QuestionPanel/ButtonAlibi
@onready var button_suspicion := $QuestionPanel/ButtonSuspicion
@onready var button_cancel := $QuestionPanel/ButtonCancel

func _ready() -> void:
	print("InterrogationUi _ready, node name:", name)
	print("Has method start_interrogation_confirm:", has_method("start_interrogation_confirm"))
	
	
	confirm_panel.visible = false
	question_panel.visible = false


func start_interrogation_confirm(person_index: int, person_name: String) -> void:
	current_person_index = person_index
	current_person_name = person_name
	
	confirm_panel.visible = true
	question_panel.visible = false
	
	confirm_label.text = "Voulez-vous interroger %s ?" % person_name

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func _on_ConfirmYes_pressed() -> void:
	confirm_panel.visible = false
	question_panel.visible = true
	question_label.text = "Que voulez-vous demander à %s ?" % current_person_name
	
	
	
func _on_ConfirmNo_pressed() -> void:
	_close_and_release_player()

func _on_ButtonAlibi_pressed() -> void:
	_send_interrogation_request("alibi")

func _on_ButtonSuspicion_pressed() -> void:
	_send_interrogation_request("suspicion")

func _on_ButtonCancel_pressed() -> void:
	_close_and_release_player()

func _send_interrogation_request(kind: String) -> void:
	# Exemple simple de "journal"
	var question_text := ""
	if kind == "alibi":
		question_text = "Que faisais-tu au moment du drame ?"
	elif kind == "suspicion":
		question_text = "Qui soupçonnes-tu ?"

	# On log dans le "journal" global (à adapter à ton système réel)
	if Global.has_method("add_journal_line"):
		Global.add_journal_line("[%s] Interrogation de %s : %s" % [
			Time.get_time_string_from_system(),
			current_person_name,
			question_text
		])

	# Récupère le journal du joueur (texte complet) pour le donner à l'IA
	var journal_text := ""
	if Global.has_method("get_player_journal_text"):
		journal_text = Global.get_player_journal_text()
	print("Là j'envoie à l'ia avec", current_person_index, journal_text)
	# Appel à ton système d'interrogatoire
	Global.generate_interrogation_for_person(current_person_index, journal_text)

	_close_and_release_player()

func _close_and_release_player() -> void:
	confirm_panel.visible = false
	question_panel.visible = false
	
	var player := get_tree().get_root().get_node("Map/Player/CharacterBody3D") as Node
	if player:
		player.in_cinematic = false
		var player_camera := player.get_node("Pivot/Camera3D") as Camera3D
		if player_camera:
			player_camera.fov = 75 # mets ici ton FOV par défaut
