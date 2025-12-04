extends Control

var hints = [
	"Astuce : Utilisez le journal (touche J) pour relire les dialogues précédents.",
	"Astuce : Parlez aux PNJ en cliquant droit sur eux.",
	"Astuce : Surveillez le nombre de dialogues restants en haut à droite.",
	"Astuce : Prenez des notes sur les personnages dans le journal.",
	"Astuce : Explorez la carte pour découvrir tous les PNJ.",
	"Astuce : Certains PNJ peuvent mentir, soyez attentif à leurs paroles.",
	"Astuce : Utilisez les informations du journal pour résoudre le mystère.",
]
var hint_change_interval := 4.0 
var time_since_last_hint := 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var current_hint = hints[randi() % hints.size()]
	get_node("Hints").text = current_hint
	get_node("Hints").modulate.a = 1.0

	if not Global.round_generated.is_connected(_on_round_generated):
		Global.round_generated.connect(_on_round_generated)


func _process(delta: float) -> void:
	time_since_last_hint += delta
	if time_since_last_hint >= hint_change_interval:
		change_hint_fade()
		time_since_last_hint = 0.0

func _on_round_generated() -> void:
	Global.game_alive = true

	print("=== ROUND GENERE (recu dans la scene du bouton) ===")

	var killer_name: String = Global.current.get("killer_full_name", "Inconnu")
	print("DEBUG - Le meurtrier est :", killer_name)

	var journal_test := "Je trouve ton comportement etrange par rapport a ce que tu as dit autour du feu."
	#Global.generate_interrogation_for_second(journal_test)

	Global.game_alive = true
	print("on passe à la map")
	get_tree().change_scene_to_file("res://Scenes/map.tscn")

func change_hint_fade() -> void:
	var current_hint = hints[randi() % hints.size()]
	var hint_label = get_node("Hints")
	
	var tween = get_tree().create_tween()
	tween.tween_property(hint_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(Callable(hint_label, "set_text").bind(current_hint))
	tween.tween_property(hint_label, "modulate:a", 1.0, 1.0)
