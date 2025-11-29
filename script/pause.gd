extends Control

@onready var botao_continuar: Button = $Panel/VBoxContainer/Continuar
@onready var botao_sair: Button = $Panel/VBoxContainer/Sair

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	botao_continuar.pressed.connect(_on_continuar_pressed)
	botao_sair.pressed.connect(_on_sair_pressed)

func abrir() -> void:
	visible = true
	get_tree().paused = true

func fechar() -> void:
	visible = false#visibilidade
	get_tree().paused = false

func pausedespause() -> void:
	if visible:
		fechar()
	else:
		abrir()
		
func _on_continuar_pressed() -> void:
	fechar()  # so volta

func _on_sair_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn") #volta para o menu do inicio
