extends CanvasLayer

var time_left := 600.0  # 10 minutes en secondes

@onready var time_label := $TimeLeft


func _ready() -> void:
	_update_time_display()
	show_history_day()

func show_history_day() -> void:
	# on regarde si on a des infos à afficher
	if Global.current == null:
		return
	
	var killer_name_value = Global.current.get("killer_full_name", "Inconnu")
	var killer_name: String = killer_name_value if killer_name_value != null else "Inconnu"
	var day_index: int = Global.current.get("day_index", 1)

	# on affiche les infos
	var history_day := get_node("StartHistoryDay")
	history_day.text = "Jour %d\nLe meurtrier est %s" % [day_index, killer_name]

	# cinématique de début de journée
	var cinematic_camera := get_node("../CinematicCamera")
	cinematic_camera.position = Vector3(0, 4, 0)
	cinematic_camera.current = true
	
	history_day.visible = true
	history_day.modulate.a = 1.0
	var tween = get_tree().create_tween()
	tween.tween_property(cinematic_camera, "position:y", 10.0, 10.0)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(history_day, "modulate:a", 1.0, 8.0)
	tween2.tween_property(history_day, "modulate:a", 0.0, 1.0)
	
	await tween.finished
	history_day.visible = false
	cinematic_camera.current = false

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


func _update_time_display() -> void:
	var minutes := int(time_left) / 60
	var seconds := int(time_left) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds] + " restantes"


func _on_replay_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")
