extends CharacterBody2D

@onready var satelit: Node2D = $Satelit
@onready var Arm1: Node2D = $Arms1
@onready var Arm2: Node2D = $Arms2
@export var weapon_change_interval: float = 4.0   # tempo entre trocas de arma do player
var _parts_remain: int = 0
var _phase: int = 0            # qual estado da maquina de estado cada parte
var _parts: Array = [] #controle de partes 
var _player: Node = null
var _weapon_timer: float = 0.0
signal boss_died

func _ready() -> void:
	_parts = [satelit, Arm1, Arm2]#partes do chefe
	_parts_remain = _parts.size()
	for p in _parts:
		if p == null:
			continue
		if p.has_method("set_boss_pose"): #setar o centro de giro
			p.set_boss_pose(self)
		if p.has_signal("died"):#controle se uma parte morreu
			p.died.connect(_on_part_died)
		if p.has_method("set_phase"):# mudar a maquina de estado das partes
			p.set_phase(_phase)
	_player = get_tree().get_root().find_child("Player", true, false)
	_weapon_timer = weapon_change_interval
	randomize()

func _physics_process(delta: float) -> void:
	_weapon_timer -= delta
	if _weapon_timer <= 0.0:
		_lotery_change()
		_weapon_timer = weapon_change_interval

func _on_part_died() -> void:#recebeu sinal de que uma parte morreu
	_parts_remain -= 1
	if _parts_remain == 2:#phase enraged com 2 partes vivas
		_phase = 1
		_apply_phase_to_alive_parts()
	elif _parts_remain == 1:#phase desesperado com 1 parte viva
		_phase = 2
		_apply_phase_to_alive_parts()
	elif _parts_remain <= 0:
		emit_signal("boss_died")
		queue_free()

func _apply_phase_to_alive_parts() -> void: 
	for p in _parts:
		if is_instance_valid(p) and p.has_method("set_phase"):
			p.set_phase(_phase)

func _lotery_change() -> void:# troca as armas do jogador, para a luta funcionar legal
	if _player == null:
		return
	var possible_types: Array[int] = [1, 2, 4] #quais as opções
	var new_type: int = possible_types[randi() % possible_types.size()]#randomiza qual bala type vai mandr 
	if _player.has_signal("bala_type_changed"):
		_player.bala_type_changed.emit(new_type)
