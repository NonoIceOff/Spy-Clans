extends Node

# Nombre de personnes autour du feu (hors joueur)
const PEOPLE_COUNT = 9

# Listes pour les noms et personalites
const FIRST_NAMES = [
	"Alex", "Lucie", "Thomas", "Nina", "Yanis",
	"Chloe", "Jules", "Emma", "Maxime", "Sarah",
	"Louis", "Camille", "Leo", "Maya", "Rayan"
]

const LAST_NAMES = [
	"Martin", "Bernard", "Leroy", "Dupont", "Moreau",
	"Robert", "Garnier", "Laurent", "Renault", "Durand",
	"Petit", "Rousseau", "Blanc", "Perrot", "Lambert"
]

const PERSONALITY_TEMPLATES = [
	"sarcastique mais loyal",
	"tres observateur et plutot silencieux",
	"blagueur mais parfois lourd",
	"empathique mais anxieux",
	"calme et tres rationnel",
	"energetique et impulsif",
	"introverti mais attentif aux autres",
	"sociable mais secret",
	"suspicieux mais protecteur",
	"detendu en apparence mais nerveux",
	"direct et parfois blessant",
	"tres optimiste, parfois naive",
	"perfectionniste et controle freak"
]

const RELATION_TEMPLATES = [
	"meilleur ami",
	"amie d enfance",
	"collegue de fac",
	"ami proche",
	"ami d amis",
	"cousine",
	"cousin",
	"ami de longue date",
	"partenaire de sport",
	"ami de soiree"
]


func _ready():
	randomize()


# ---------------------------------------------------------
# Cree un game_state pour un jour donne
# ---------------------------------------------------------
func write_game_state(day_index: int, player_notes_summary: String = "", camp_location: String = "foret de montagne pres d un lac") -> Dictionary:
	var people: Array = []
	var used_full_names: Array = []

	for i in range(PEOPLE_COUNT):
		var person = _generate_random_person(used_full_names)
		used_full_names.append(person["full_name"])
		people.append(person)

	var game_state = {
		"day_index": day_index,
		"killer_full_name": null,
		"people": people,
		"victims": [],
		"eliminations": [],
		"player_notes_summary": player_notes_summary,
		"camp_location": camp_location
	}

	return game_state


# ---------------------------------------------------------
# Genere une personne aleatoire (compatible Godot 4.5)
# ---------------------------------------------------------
func _generate_random_person(used_full_names: Array) -> Dictionary:
	var full_name = ""

	while true:
		var first = FIRST_NAMES[randi() % FIRST_NAMES.size()]
		var last = LAST_NAMES[randi() % LAST_NAMES.size()]
		full_name = "%s %s" % [first, last]
		if not used_full_names.has(full_name):
			break

	# Age majeur entre 18 et 35
	var age = int(randf_range(18, 35))

	var personality = PERSONALITY_TEMPLATES[randi() % PERSONALITY_TEMPLATES.size()]
	var relation = RELATION_TEMPLATES[randi() % RELATION_TEMPLATES.size()]

	return {
		"full_name": full_name,
		"age": age,
		"personality": personality,
		"relation_to_player": relation,
		"alive": true
	}


# ---------------------------------------------------------
# Declarer une victime
# ---------------------------------------------------------
func mark_victim(game_state: Dictionary, full_name: String, day_index: int) -> void:
	for person in game_state["people"]:
		if person["full_name"] == full_name:
			person["alive"] = false
			break

	game_state["victims"].append({
		"full_name": full_name,
		"day_index": day_index
	})


# ---------------------------------------------------------
# Eliminer quelqu'un (accuse par le joueur)
# ---------------------------------------------------------
func eliminate_person(game_state: Dictionary, full_name: String, day_index: int, was_killer: bool) -> void:
	for person in game_state["people"]:
		if person["full_name"] == full_name:
			person["alive"] = false
			break

	game_state["eliminations"].append({
		"full_name": full_name,
		"day_index": day_index,
		"was_killer": was_killer
	})
