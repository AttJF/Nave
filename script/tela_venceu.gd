extends Control

func _ready() -> void:
	get_tree().paused = false

func _on_continuar_pressed() -> void:
	if Autoload.next_level != "":
		get_tree().change_scene_to_file(Autoload.next_level)
	else:
		get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func _on_sair_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
