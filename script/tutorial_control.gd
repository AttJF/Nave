extends Node2D

enum TutorialState { INTRO, POINTS, INIMIGO,FIM }#maquina de estado que so vai de um estado ao proximo,sem volta
@onready var dialog_label: Label = $Texto
@onready var interface   = $Interface
@onready var player = $Player
@onready var pause_menu := $CanvasLayer/Pause
@onready var points_parent: Node2D = $ClusterLocal
@onready var inimigo_spawn: Marker2D = $SpawInimigo
@onready var points_sprites: Node2D = $ClusterPowerup
@export var inimigo_scene: PackedScene

var state: TutorialState = TutorialState.INTRO
var points_total: int = 0
var points_collected: int = 0
var enemy_instance: Node = null

func _ready() -> void:
	get_tree().paused = false 
	_setup_powerups() #esconde os sprites
	player.life_changed.connect(interface.set_lives)#mostra as vidas
	interface.set_lives(player.life)
	points_total = points_parent.get_child_count()#contar se passou pelos 4 pontos
	for p in points_parent.get_children():
		if p.has_signal("point_reach"):
			p.connect("point_reach", Callable(self, "_on_point_reached"))
	_show_intro()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("enter_pressed"):#foi mapeado no project
		if state == TutorialState.INTRO:
			_points_phase()
		elif state == TutorialState.FIM:
			_finish()

func _show_intro() -> void:
	state = TutorialState.INTRO
	dialog_label.text = "Bem-vindo ao jogo barão cromado!\nUse WASD para se mover.\nUse o botão espaço para atirar."

func _points_phase() -> void:
	state = TutorialState.POINTS
	dialog_label.text = "Vamos testar sua pilotagem\nAnde até os 4 pontos."

func _start_enemy_phase() -> void:
	state = TutorialState.INIMIGO
	dialog_label.text = "Vamos testar sua aptidão em combate, derrote o inimigo.\n Voce perde vidas ao ser atingido, elas estão mostradas no canto superior esquerdo\n se suas vidas chegarem a zero você perde"
	enemy_instance = inimigo_scene.instantiate()
	add_child(enemy_instance)#add inimigo
	enemy_instance.global_position = inimigo_spawn.global_position
	if enemy_instance.has_signal("died"):#chamando o proximo estado atravas do sinal de que o inimigo morreu
		enemy_instance.connect("died", Callable(self, "_on_enemy_died"))

func _on_point_reached() -> void:
	points_collected += 1
	if points_collected >= points_total:
		_start_enemy_phase()

func _on_enemy_died() -> void:
	_start_powerup_phase()

func _finish() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func _setup_powerups() -> void:
	for p in points_sprites.get_children():
		_powerup_active(p, false)
		
func _powerup_active(powerup: Node2D, active: bool) -> void: #mesma logica do disk
	if powerup == null:
		return
	powerup.visible = active
	if powerup is Area2D:
		var area := powerup as Area2D
		area.set_deferred("monitoring", active)
		area.set_deferred("monitorable", active)
		var shape := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape:
			shape.set_deferred("disabled", not active)

func _start_powerup_phase() -> void:
	state = TutorialState.FIM
	dialog_label.text = "Inimigos ao serem eliminados deixam recursos que podem ser usados pelo jogador, eles fornecem diferentes vantagem ao serem adquiridos.\n Pressione Enter para voltar ao menu Inicial"
	for p in points_sprites.get_children():
		_powerup_active(p, true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_menu.pausedespause()
