extends CanvasLayer

var time_left := 600.0  # 10 minutes en secondes
var is_typing := false
var typing_speed := 0.02  # secondes entre chaque caractère

@onready var time_label := $TimeLeft
@onready var dialogues_left_label := $DialoguesLeft



func _ready() -> void:
	_update_time_display()
	show_history_day()

func show_history_day() -> void:
	
	# on regarde si on a des infos à afficher
	if Global.current == null:
		return

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var history_value = Global.current.get("day_story", "Inconnu")
	var history: String = history_value if history_value != null else "Inconnu"
	var day_index: int = Global.current.get("day_index", 1)

	# on affiche les infos
	var history_day := get_node("StartHistoryDay")
	var history_day_back := get_node("HistoryDayBack")
	var history_day_skip_button := get_node("HistorySkipButton")
	var full_text := "Jour %d\n%s" % [day_index, history]

	# cinématique de début de journée
	var cinematic_camera := get_node("../CinematicCamera")
	cinematic_camera.position = Vector3(0, 4, 0)
	cinematic_camera.current = true
	
	history_day.visible = true
	history_day_back.visible = true
	history_day_skip_button.visible = true
	history_day_back.modulate.a = 1.0
	history_day.modulate.a = 1.0
	history_day_skip_button.modulate.a = 0.0
	history_day.text = ""
	
	var total_duration := 30.0
	var typing_duration := full_text.length() * typing_speed
	var fade_duration := 1.0
	var wait_before_fade := 2.0
	
	# on gère le temps minimum pour que tout rentre
	var min_camera_time := typing_duration + wait_before_fade + fade_duration
	if min_camera_time > total_duration:
		total_duration = min_camera_time
	
	# la caméra va en haut
	var tween = get_tree().create_tween()
	tween.tween_property(cinematic_camera, "position:y", 10.0, total_duration)
	
	
	# on affiche le bouton après un moment
	var tweenbut = get_tree().create_tween()
	tweenbut.tween_property(history_day_skip_button, "modulate:a", 0, 1)
	tweenbut.tween_property(history_day_skip_button, "modulate:a", 1, 2)
	
	# on affiche les lettres une par une
	is_typing = true
	for i in range(full_text.length()):
		if not is_typing:
			break
		history_day.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(typing_speed).timeout
	is_typing = false
	history_day.text = full_text
	
	# on attend un peu puis fondu
	await get_tree().create_timer(wait_before_fade).timeout
	var tween2 = get_tree().create_tween()
	tween2.tween_property(history_day, "modulate:a", 0.0, fade_duration)
	tween2.tween_property(history_day_back, "modulate:a", 0.0, fade_duration)
	tween2.tween_property(history_day_skip_button, "modulate:a", 0.0, fade_duration)
	
	await tween.finished
	history_day.visible = false
	history_day_back.visible = false
	history_day_skip_button.visible = false
	cinematic_camera.current = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	time_left -= delta
	if time_left < 0 and Global.game_alive:
		time_left = 0
		Global.game_alive = false
		var fade = get_node("FadeBlack")
		fade.visible = true
		fade.self_modulate.a = 0

		var replay_button = get_node("FadeBlack/ReplayButton")
		replay_button.visible = true
		replay_button.self_modulate.a = 0

		# petit fondu au noir
		var tween = get_tree().create_tween()
		tween.tween_property(fade, "self_modulate:a", 1.0, 1.0)
		# juste après, afficher le bouton rejouer
		tween.tween_property(replay_button, "self_modulate:a", 1.0, 1.0).set_delay(1.0)

		get_node("FadeBlack/DeadText").text = "Temps écoulé !\nLe maire est mort."
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_time_display()

	if Input.is_action_just_pressed("ui_j"):
		# ouvrir ou fermer le journal, en faisant attention au curseur de souris
		var journal = get_node("Journal")
		journal.show_history_dialogues()
		var new_visible = not journal.visible
		journal.visible = new_visible
		if new_visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _update_time_display() -> void:
	var minutes := int(time_left) / 60
	var seconds := int(time_left) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds] + " restantes"

	dialogues_left_label.text = "Dialogues restants : %d" % Global.dialogues_left




func _on_replay_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")


func _on_history_skip_button_pressed() -> void:
	var history_day := get_node("StartHistoryDay")
	var history_day_back := get_node("HistoryDayBack")
	var history_day_skip_button := get_node("HistorySkipButton")
	
	var cinematic_camera := get_node("../CinematicCamera")

	history_day.visible = false
	history_day_back.visible = false
	history_day_skip_button.visible = false
	cinematic_camera.current = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
