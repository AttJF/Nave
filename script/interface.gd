extends CanvasLayer

@onready var lives_label    = $MarginContainer/VBoxContainer/Lives
@onready var time_label    = $MarginContainer/VBoxContainer/Tempo
func set_lives(value: int) -> void:
	lives_label.text = "Vidas: %d" % value
func set_timer(time_left: float) -> void:
	var t := int(max(time_left, 0))

	var seconds := t % 60
	
	time_label.text = "Tempo restante : %02d segundos" % seconds
