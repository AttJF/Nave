extends Node2D

@export var inimigo_scene: PackedScene

func _ready() -> void:
	spawn_inimigo(Vector2(600, 300))
	spawn_inimigo(Vector2(700, 200))

func spawn_inimigo(pos: Vector2) -> void:
	if inimigo_scene:
		var inimigo := inimigo_scene.instantiate()
		inimigo.global_position = pos
		inimigo.player_path = get_node("Player").get_path()
		add_child(inimigo)
