extends Node2D
@export var inimigo_scene: PackedScene   
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

func _ready() -> void:
	get_tree().paused = false #tava dando problema no pause
	player.life_changed.connect(interface.set_lives)
	interface.set_lives(player.life)
	_spawn_inimigos(5)
	
func _spawn_inimigo_at(point: Node2D) -> void: #spawnar 1 inimigo
	var inimigo = inimigo_scene.instantiate()
	add_child(inimigo)
	inimigo.global_position = point.global_position
	inimigos_alive += 1
	inimigo.died.connect(_on_inimigo_died)

func _on_inimigo_died() -> void:  # contar quantos inimigos foram mortos
	if is_waiting:
		return
	inimigos_alive -= 1
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
	#get_tree().change_scene_to_file("")
	
func _spawn_inimigos(amount: int) -> void: 
	for i in amount:
		var point := spawn_points[i % spawn_points.size()]# vai dar problema se tiver mais inimigos que spawn_points
		_spawn_inimigo_at(point)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_menu.pausedespause()
