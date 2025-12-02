extends Node3D

@onready var name_text = get_node("../Name") as Label3D
var hover = false
var name_pnj = ""

var dialogue_lines: Array[Dictionary] = []


func _ready() -> void:
	name_pnj = "PNJ Inconnu"
	get_node("../Name").text = name_pnj
	dialogue_lines = [
		{"name": name_pnj, "text": "Bonjour, que puis-je faire pour vous ?"},
		{"name": name_pnj, "text": "Je suis ici pour vous aider."},
		{"name": name_pnj, "text": "N'hésitez pas à me poser des questions."}
	]


func _process(delta: float) -> void:
	name_text.visible = hover


func show_name_label() -> void:
	hover = true

func hide_name_label() -> void:
	hover = false

# détecter clic droit, ouvrir dialogue
func _input(event) -> void:
	if event is InputEventMouseButton and hover:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			var dialogue := get_tree().get_root().get_node("Dialogues") as Node
			if dialogue.has_method("start_dialogue"):
				dialogue.call("start_dialogue", dialogue_lines)
