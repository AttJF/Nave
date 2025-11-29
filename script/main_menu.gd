extends Control

const CENA_FASE := "res://scene/level_1.tscn"   #sempre vai começar na cena 1, não tem sistema de salvar no jogo 

func _ready() -> void:
	get_tree().paused = false

func _on_jogar_pressed() -> void:
	get_tree().change_scene_to_file(CENA_FASE)

func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/node_2d.tscn")#caminho tutorial

func _on_sair_pressed() -> void:
	get_tree().quit()
