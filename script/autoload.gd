extends Node

var completed_levels: Array[String] = []
var last_level_scene: String = ""
var next_level: String = ""

func save_level() -> void:# salvar qual foi o ultimo level que o player estava
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	var path := current_scene.scene_file_path 
	if path == "":
		return
	if path not in completed_levels:
		completed_levels.append(path)
	last_level_scene = path
	
func go_next_level(proximo_level_path: String) -> void:
	next_level = proximo_level_path #salvar qual level é o proximo, eu uso no menu de vitoria
	
