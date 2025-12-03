extends Control

signal dialogue_started
signal dialogue_ended

var dialogue_lines: Array[Dictionary] = []
var current_line: int = 0
var is_active: bool = false
var consumme_dpoints = true

@onready var text_label := $Text
@onready var name_label := $Name


func _ready() -> void:
	visible = false
	#await get_tree().create_timer(1.0).timeout

	# petit exemple pour pouvoir ensuite intégrer
	#start_dialogue([
	#	{"name": "Chef", "text": "Bienvenue, agent."},
	#	{"name": "Chef", "text": "Votre mission : infiltrer la base ennemie."},
	#	{"name": "Chef", "text": "Vous avez 10 minutes pour récupérer les documents."},
	#	{"name": "Chef", "text": "Restez discret et bonne chance !"}
	#])


func start_dialogue(lines: Array[Dictionary], consumme_dpoints_val = true) -> void:
	dialogue_lines = lines.duplicate()
	current_line = 0
	consumme_dpoints = consumme_dpoints_val
	is_active = true
	visible = true
	_show_current_line()
	dialogue_started.emit()
	# sauvegarde le dialogue pour pouvoir le relire dans le journal
	Global.dialogue_history.append({
		"name": lines[0].get("name", "Inconnu") if lines.size() > 0 else "Inconnu",
		"lines": dialogue_lines
	})


func next_line() -> void:
	if not is_active:
		return
	
	current_line += 1
	if current_line >= dialogue_lines.size():
		end_dialogue()
	else:
		_show_current_line()

func end_dialogue() -> void:
	is_active = false
	visible = false
	dialogue_lines = []
	current_line = 0
	dialogue_ended.emit()
	if consumme_dpoints:
		Global.dialogues_left -= 1
	var cinematic_camera = get_tree().get_root().get_node("Map/CinematicCamera")
	cinematic_camera.current = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	consumme_dpoints = true


func _show_current_line() -> void:
	if current_line < dialogue_lines.size():
		var line: Dictionary = dialogue_lines[current_line]
		name_label.text = line.get("name", "")
		text_label.text = line.get("text", "")


func _input(event: InputEvent) -> void:
	if not is_active:
		return
	
	# suite avec avec Espace/Entrée
	if event.is_action_pressed("ui_accept"):
		next_line()
	
	# suite avec clic gauche
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		next_line()
