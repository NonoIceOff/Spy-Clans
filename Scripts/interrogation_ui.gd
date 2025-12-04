extends Control

var current_person_index: int = -1
var current_person_name: String = ""

@onready var confirm_panel := $ConfirmPanel
@onready var confirm_label := $ConfirmPanel/Label
@onready var question_panel := $QuestionPanel
@onready var question_label := $QuestionPanel/Label

@onready var button_yes := $ConfirmPanel/ConfirmYes
@onready var button_no := $ConfirmPanel/ConfirmNo
@onready var button_alibi := $QuestionPanel/ButtonAlibi
@onready var button_suspicion := $QuestionPanel/ButtonSuspicion
@onready var button_cancel := $QuestionPanel/ButtonCancel
@onready var question_final := $FinalPanel

signal pnj_in_jail(person_index: int)
signal pnj_released(person_index: int)

@onready var sfx_player := $SfxPlayer

# Paramètres d'animation hover
var hover_scale: Vector2 = Vector2(1.1, 1.1)
var normal_scale: Vector2 = Vector2.ONE
var button_tweens: Dictionary = {} # bouton -> Tween



func _ready() -> void:
	print("InterrogationUi _ready, node name:", name)
	print("Has method start_interrogation_confirm:", has_method("start_interrogation_confirm"))
	
	confirm_panel.visible = false
	question_panel.visible = false

	# Initialiser la scale de tous les boutons et connecter les signaux de hover
	var all_buttons: Array[Button] = [
		button_yes,
		button_no,
		button_alibi,
		button_suspicion,
		button_cancel
	]

	for btn in all_buttons:
		if btn:
			btn.scale = normal_scale
			btn.mouse_entered.connect(_on_button_mouse_enter.bind(btn))
			btn.mouse_exited.connect(_on_button_mouse_exit.bind(btn))


func _play_sfx() -> void:
	if sfx_player:
		sfx_player.play()


func _on_button_mouse_enter(button: Button) -> void:
	# Stop l'ancien tween si besoin
	if button_tweens.has(button):
		var old_tween: Tween = button_tweens[button]
		if is_instance_valid(old_tween):
			old_tween.kill()

	var t := create_tween()
	t.tween_property(button, "scale", hover_scale, 0.1)
	button_tweens[button] = t


func _on_button_mouse_exit(button: Button) -> void:
	if button_tweens.has(button):
		var old_tween: Tween = button_tweens[button]
		if is_instance_valid(old_tween):
			old_tween.kill()

	var t := create_tween()
	t.tween_property(button, "scale", normal_scale, 0.1)
	button_tweens[button] = t


func start_interrogation_confirm(person_index: int, person_name: String) -> void:
	current_person_index = person_index
	current_person_name = person_name
	
	confirm_panel.visible = true
	question_panel.visible = false
	
	confirm_label.text = "Voulez-vous interroger %s ?" % person_name

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_ConfirmYes_pressed() -> void:
	_play_sfx()
	confirm_panel.visible = false
	question_panel.visible = true
	question_label.text = "Que voulez-vous demander à %s ?" % current_person_name


func _on_ConfirmNo_pressed() -> void:
	_play_sfx()
	_close_and_release_player()


func _on_ButtonAlibi_pressed() -> void:
	_play_sfx()
	_send_interrogation_request("alibi")


func _on_ButtonSuspicion_pressed() -> void:
	_play_sfx()
	_send_interrogation_request("suspicion")


func _on_ButtonCancel_pressed() -> void:
	_play_sfx()
	_close_and_release_player()


func _send_interrogation_request(kind: String) -> void:
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

	Global.generate_interrogation_for_person(current_person_index, journal_text)

	_close_and_release_player()


func _close_and_release_player() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	confirm_panel.visible = false
	question_panel.visible = false
	question_final.visible = false

	var player := get_tree().get_root().get_node("Map/Player/CharacterBody3D") as Node
	if player:
		player.in_cinematic = false
		var player_camera := player.get_node("Pivot/Camera3D") as Camera3D
		if player_camera:
			player_camera.fov = 75 # FOV par défaut

	# On rend la souris au mode jeu
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			player_camera.fov = 75 # mets ici ton FOV par défaut


func show_final_choice() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	question_final.visible = true

func _on_button_jail_pressed() -> void:
	print(current_person_index)
	print(current_person_name)
	print("Le joueur a choisi d'envoyer en prison")
	_close_and_release_player()
	emit_signal("pnj_in_jail", current_person_index)


func _on_button_release_pressed() -> void:
	print(current_person_index)
	print(current_person_name)
	print("Le joueur a choisi de relâcher")
	_close_and_release_player()
	emit_signal("pnj_released", current_person_index)
