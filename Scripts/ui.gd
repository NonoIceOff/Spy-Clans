extends CanvasLayer

var time_left := 600.0  # 10 minutes en secondes

@onready var time_label := $TimeLeft


func _ready() -> void:
	_update_time_display()


func _process(delta: float) -> void:
	time_left -= delta
	if time_left < 0:
		time_left = 0
	_update_time_display()


func _update_time_display() -> void:
	var minutes := int(time_left) / 60
	var seconds := int(time_left) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds] + " restantes"
