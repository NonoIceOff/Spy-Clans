extends ColorRect

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


func _process(delta: float) -> void:
	time_since_last_hint += delta
	if time_since_last_hint >= hint_change_interval:
		change_hint_fade()
		time_since_last_hint = 0.0

func change_hint_fade() -> void:
	var current_hint = hints[randi() % hints.size()]
	var hint_label = get_node("Hints")
	
	var tween = get_tree().create_tween()
	tween.tween_property(hint_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(Callable(hint_label, "set_text").bind(current_hint))
	tween.tween_property(hint_label, "modulate:a", 1.0, 1.0)
