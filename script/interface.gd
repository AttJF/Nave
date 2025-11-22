# ui/HUD.gd
extends CanvasLayer

@onready var lives_label    = $MarginContainer/VBoxContainer/Lives

func set_lives(value: int) -> void:
	lives_label.text = "Vidas: %d" % value
