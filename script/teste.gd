extends Node2D

@onready var intro: Label      = $Intro
@onready var interface         = $Interface
@onready var pause_menu        := $CanvasLayer/Pause
@onready var player: Player    = $Player
@onready var boss              = $Boss 
@onready var parallax2 := $ParallaxBackground
var intro_done: bool = false
var inimigos: Array = []

func _ready() -> void:
	# mostra intro e trava tudo
	intro_done = false
	intro.visible = true
	player.life_changed.connect(interface.set_lives)
	interface.set_lives(player.life)
	player.set_physics_process(false)
	inimigos = get_tree().get_nodes_in_group("enemy")
	for i in inimigos:
		if is_instance_valid(i):
			i.set_physics_process(false)
			i.set_process(false)
	if boss != null and boss.has_signal("boss_died"):
		boss.boss_died.connect(_on_boss_died)

func _on_boss_died() -> void:
	Autoload.go_next_level("res://scene/level_final.tscn")
	get_tree().change_scene_to_file("res://scene/tela_venceu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not intro_done:
		intro_done = true
		intro.visible = false
		player.set_physics_process(true)
		for i in inimigos:
			if is_instance_valid(i):
				i.set_physics_process(true)
				i.set_process(true)
	elif event.is_action_pressed("pause"):
		pause_menu.pausedespause()
