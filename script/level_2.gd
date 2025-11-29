extends Node2D

@export var inimigo_mae_scene: PackedScene  
@export var inimigo_scene: PackedScene   
@export var vento_scene: PackedScene   

@onready var intro: Label = $Intro
@onready var interface   = $Interface
@onready var pause_menu := $CanvasLayer/Pause
@onready var player = $Player
@onready var parallax := $ParallaxBackground
@onready var spawn_points: Array[Node2D] = [ 
	$SpawnCluster/Spawn1,
	$SpawnCluster/Spawn2,
	$SpawnCluster/Spawn3,
	$SpawnCluster/Spawn4,
	$SpawnCluster/Spawn5,
]

@onready var disk_parent: Node2D = $DiskCluster
@onready var third_disk: Area2D = $DiskCluster/Disk3
var disks_collected: int = 0#controle de quantos disk foram coletados
var is_waiting: bool = false
var intro_done: bool = false #controle para mostrar o labe de objetivos
var inimigos: Array = []

func _ready() -> void:
	_setup_disks()
	intro.visible = true #trava tudo para a intro
	player.life_changed.connect(interface.set_lives)
	interface.set_lives(player.life)
	player.set_physics_process(false)
	parallax.set_process(false)
	inimigos = get_tree().get_nodes_in_group("enemy")
	for i in inimigos:
		i.set_physics_process(false)
		i.set_process(false)

func _spawn_vento_at(point: Node2D) -> void:# criar vento, ele sempre chama a si mesmo no final de cada intancia de vento
	var vento = vento_scene.instantiate()
	add_child(vento)
	vento.global_position = point.global_position
	vento.ended.connect(Callable(self, "_spawn_vento_at").bind(point))

func _setup_disks() -> void:
	for d in disk_parent.get_children():
		if d.has_signal("point_reach"):
			d.connect("point_reach", Callable(self, "_on_disk_reached"))#quando receber o sinal chama a função
	_disk_active(third_disk, false)

func _disk_active(disk: Area2D, active: bool) -> void:
	if disk == null:
		return
	disk.visible = active #liga e desliga visibilidade
	disk.set_deferred("monitoring", active)
	disk.set_deferred("monitorable", active)
	var shape := disk.get_node_or_null("CollisionShape2D") as CollisionShape2D #liga e desliga a colisão

func _on_disk_reached() -> void: #controle de quantos disk foram coletados e o que fazer
	disks_collected += 1
	if disks_collected == 2:
		_disk_active(third_disk, true)
	elif disks_collected == 3:
		_on_all_disks_reached()

func _on_all_disks_reached() -> void:# terminar fase
	_transition_phase()

func _transition_phase() -> void:
	Autoload.go_next_level("res://scene/teste.tscn")
	get_tree().change_scene_to_file("res://scene/tela_venceu.tscn")

func _start_storm() -> void: #3 ventos criados
	_spawn_vento_at(spawn_points[0])
	await get_tree().create_timer(1.0).timeout
	_spawn_vento_at(spawn_points[1])
	await get_tree().create_timer(1.0).timeout
	_spawn_vento_at(spawn_points[3])

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
		_start_storm()
	elif event.is_action_pressed("pause"):
		pause_menu.pausedespause()
