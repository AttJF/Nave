extends Node2D

@export var inimigo_mae_scene: PackedScene  
@export var inimigo_scene: PackedScene   
@export var vento_scene: PackedScene   

@onready var intro: Label = $Intro
@onready var interface   = $Interface
@onready var pause_menu := $CanvasLayer/Pause
@onready var player = $Player
@onready var parallax := $ParallaxBackground
@onready var spawn_points: Array[Node2D] = [ #pontos de spawn, usa marker 
	$SpawnCluster/Spawn1,
	$SpawnCluster/Spawn2,
	$SpawnCluster/Spawn3,
	$SpawnCluster/Spawn4,
	$SpawnCluster/Spawn5,
]

var inimigos_alive: int = 0
var wave_now:int = 0
var is_waiting: bool = false  #controlador para ajudar com as "animações"
var intro_done: bool = false #controlador para a breve intro da fase
var inimigos: Array = []

func _ready() -> void:
	get_tree().paused = false #tava dando problema no pause
	player.life_changed.connect(interface.set_lives)
	interface.set_lives(player.life)
	intro.visible = true
	player.set_physics_process(false)#trava tudo para a intro
	parallax.set_process(false)
	for i in inimigos:
		i.set_physics_process(false)
		i.set_process(false)

func _start_phase() -> void:
	_spawn_inimigos(5)
	_spawn_vento_at(spawn_points[1])
	_spawn_inimigo_mae_at(spawn_points[1])

func _spawn_inimigo_at(point: Node2D) -> void: #spawnar 1 inimigo
	var inimigo = inimigo_scene.instantiate()
	add_child(inimigo)
	inimigo.global_position = point.global_position
	inimigos_alive += 1
	inimigo.died.connect(Callable(self, "_on_inimigo_died").bind(inimigo))
	inimigos.append(inimigo)
	if not intro_done:
		inimigo.set_physics_process(false)
		inimigo.set_process(false)

func _spawn_inimigo_mae_at(point: Node2D) -> void: #spawnar 1 inimigo
	var inimigo = inimigo_mae_scene.instantiate()
	add_child(inimigo)
	inimigo.global_position = point.global_position
	inimigos_alive += 1
	inimigo.died.connect(Callable(self, "_on_inimigo_died").bind(inimigo))
	inimigos.append(inimigo)
	if not intro_done:
		inimigo.set_physics_process(false)
		inimigo.set_process(false)

func _spawn_vento_at(point: Node2D) -> void: #spawnar 1 inimigo
	var vento = vento_scene.instantiate()
	add_child(vento)
	vento.global_position = point.global_position
	vento.ended.connect(Callable(self, "_spawn_vento_at").bind(spawn_points[1]))

func _on_inimigo_died(inimigo: Node) -> void:  # contar quantos inimigos foram mortos
	if is_waiting:
		return
	inimigos_alive -= 1
	inimigos.erase(inimigo)
	if is_instance_valid(inimigo):
		inimigo.queue_free()
	if inimigos_alive <= 0:
		await _bring_wave(3,5)
		
func _bring_wave(w:int, s:int) -> void: # numero de waves e numero inimigos por wave
	is_waiting = true
	wave_now += 1
	if wave_now > w:
		print("fim")
		await _transition_phase()
		return
	parallax.boost_speed(20.0, 3.0) 
	await get_tree().create_timer(3.0).timeout
	is_waiting = false
	_spawn_inimigos(s)

func _transition_phase() -> void: #animação  fim de nivel
	for i in range(3):
		parallax.boost_speed(100.0, 3.0)
		await get_tree().create_timer(1.0).timeout
	Autoload.go_next_level("res://scene/level_2.tscn")
	get_tree().change_scene_to_file("res://scene/tela_venceu.tscn")
	
func _spawn_inimigos(amount: int) -> void: 
	for i in amount:
		var point := spawn_points[i % spawn_points.size()]# vai dar problema se tiver mais inimigos que spawn_points
		_spawn_inimigo_at(point)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not intro_done:
		intro_done = true
		intro.visible = false
		player.set_physics_process(true)#trava player
		parallax.set_process(true)#trava parallax
		for i in inimigos:#trava inimigos 
			if is_instance_valid(i):
				i.set_physics_process(true)
				i.set_process(true)
		_start_phase()
	elif event.is_action_pressed("pause"):
		pause_menu.pausedespause()
