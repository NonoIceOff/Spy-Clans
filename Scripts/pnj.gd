extends Node3D

@onready var name_text = get_node("../Name") as Label3D
var hover = false
var name_pnj = ""

var dialogue_lines: Array[Dictionary] = []

@onready var dialogue = get_tree().get_root().get_node("Dialogues") as Node

func initialize_pnj(name: String, lines: Array[Dictionary]) -> void:
	name_pnj = name
	get_node("../Name").text = name_pnj
	dialogue_lines = lines

func _ready() -> void:
	dialogue.dialogue_ended.connect(_on_dialogue_ended)


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
			var player := get_tree().get_root().get_node("Map/Player/CharacterBody3D") as Node
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
