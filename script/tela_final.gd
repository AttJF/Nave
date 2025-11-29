extends Control

func _ready() -> void:
	get_tree().paused = false

func _on_continuar_pressed() -> void:
		get_tree().change_scene_to_file("res://scene/main_menu.tscn")
