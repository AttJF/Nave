extends Node2D

@export var survival_time: float = 60.0 # tempo que o jogador precisa sobreviverne  
@export var inimigo_scene: PackedScene   
@export var vento_scene: PackedScene   
@onready var intro: Label = $Intro
@onready var interface   = $Interface
@onready var pause_menu := $CanvasLayer/Pause
@onready var parallax2 := $ParallaxBackground
@onready var player = $Player
@onready var spawn_points: Array[Node2D] = [ #pontos de spawn, usa marker 
	$SpawnCluster/Spawn1,
	$SpawnCluster/Spawn2,
	$SpawnCluster/Spawn3,
	$SpawnCluster/Spawn4,
	$SpawnCluster/Spawn5,
]

var time_left: float = 0.0
var inimigos_alive: int = 0
var wave_now:int = 0
var is_waiting: bool = false      # controlador para ajudar com as "animações"
var intro_done: bool = false      # controlador para a breve intro da fase
var inimigos: Array = []          # para controle de quantidade / waves

func _ready() -> void:
	intro_done = false
	intro.visible = true
	player.life_changed.connect(interface.set_lives)
	interface.set_lives(player.life)
	player.set_physics_process(false)
	_spawn_inimigos(3)
	_spawn_vento_at(spawn_points[1])
	get_tree().call_group("enemy", "set_physics_process", false)#travar usando o grupo enemy
	get_tree().call_group("enemy", "set_process", false)
	time_left = survival_time
	interface.set_timer(time_left)

func _process(delta: float) -> void:
	if not intro_done: # trava o jogo na intro
		return
	if get_tree().paused:
		return
	if time_left > 0.0:
		time_left -= delta
		if time_left <= 0.0:
			_transition_phase()
	interface.set_timer(time_left)

func _transition_phase() -> void: # animação fim de nivel
	get_tree().change_scene_to_file("res://scene/tela_final.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not intro_done:
		intro_done = true
		intro.visible = false
		player.set_physics_process(true)
		get_tree().call_group("enemy", "set_physics_process", true)
		get_tree().call_group("enemy", "set_process", true)
	elif event.is_action_pressed("pause"):
		pause_menu.pausedespause()

func _spawn_inimigos(amount: int) -> void: 
	for i in range(amount): # range() aqui
		var point := spawn_points[i % spawn_points.size()] # ainda cicla spawn points
		_spawn_inimigo_at(point)

func _spawn_inimigo_at(point: Node2D) -> void: # spawnar 1 inimigo
	var inimigo = inimigo_scene.instantiate()
	add_child(inimigo)
	inimigo.global_position = point.global_position
	inimigo.add_to_group("enemy")
	inimigos_alive += 1
	inimigo.died.connect(Callable(self, "_on_inimigo_died").bind(inimigo))
	inimigos.append(inimigo)
	if not intro_done:
		inimigo.set_physics_process(false)
		inimigo.set_process(false)

func _spawn_vento_at(point: Node2D) -> void:
	var vento = vento_scene.instantiate()
	add_child(vento)
	vento.global_position = point.global_position
	vento.ended.connect(Callable(self, "_spawn_vento_at").bind(spawn_points[1]))

func _bring_wave() -> void: # numero de waves e numero inimigos por wave
	is_waiting = true
	await get_tree().create_timer(3.0).timeout
	is_waiting = false
	_spawn_inimigos(3)
	
func _on_inimigo_died(inimigo: Node) -> void:  # contar quantos inimigos foram mortos
	if is_waiting:
		return
	inimigos_alive -= 1
	inimigos.erase(inimigo)
	if is_instance_valid(inimigo):
		inimigo.queue_free()
	if inimigos_alive <= 0:
		await _bring_wave()
