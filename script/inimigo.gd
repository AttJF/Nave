extends CharacterBody2D

@export var move_speed: float = 500.0
@export var shoot_cooldown: float = 4.0 
@export var bala_scene: PackedScene
@export var powerup_scene: PackedScene
@export var powerup_scene_fire: PackedScene
@export var life_b: PackedScene
@export var i_frame_time: float = 1.4
@export var player_path: NodePath #onde esta o player
@export var patrol_left_x: float = -100.0
@export var patrol_right_x: float = 100.0
@export var detection_range: float = 900.0
@export var attack_range: float = 700.0
@export var desired_distance: float = 500.0 # quão perto do player vai ficar ao ficar agressivo
@export var distance_tolerance: float = 100
@export var spot_hold_time: float = 2.0 	#tempo para no no lugar
@export var spot_tolerance: float = 10.0	#margem para se aproximar no ponto
@export var screen_margin: float = 32.0      # margem pra não colar nas bordas
@export var stuck_time: float = 0.6          # tempo controle para travamento
@export var stuck_move_threshold: float = 2.0 # distancia minima para travamento
@export var min_distance_from_player: float = 250.0 # distancia para evitar colisão com player

enum State { IDLE, PATROL, ATTACK, RUNNING } #maquina de estado
var state: State = State.PATROL #começa na patrulha
var _cool: float = 0.0
var is_invulnerable : bool = false
var life: int = 6
var lifetotal: int =10 #controle para saber se tomou tiro 
var _dir_x: int = 1
var _player: Node2D = null
var _flash_tween: Tween = null #pisca pisca
var _spot_target: Vector2 = Vector2.ZERO # local sorteado para tentar acertar o jogador
var _spot_timer: float = 0.0 #tempo que vai ficar parado la
var _last_pos: Vector2 = Vector2.ZERO
var _stuck_timer: float = 0.0
var _run_target: Vector2 = Vector2.ZERO  # local para fugir quando tomar bala
var _has_target: bool = false     
var _dead: bool = false
signal died() #controle de waves

func _ready() -> void:
	if player_path != NodePath():
		_player = get_node_or_null(player_path)
	if _player == null:
		var found := get_tree().get_root().find_child("Player", true, false)
		if found != null:
			_player = found as Node2D

func _physics_process(delta: float) -> void:
	if _dead:
		_dead = false
		_death_has_come()
	_update_state()
	_process_state(delta)
	_shoot(delta)
	_clamp_inside_view()

func _update_state() -> void:
	var prev_state := state
	if _player == null:
		state = State.PATROL
		return
	if is_invulnerable: #tomou tiro ele corre e entra no estado running
		state = State.RUNNING
		return
	_run_target = Vector2.ZERO
	var dist := global_position.distance_to(_player.global_position)
	if life < lifetotal: #se tiver tomado tiro ja entra no estado atacando
		state = State.ATTACK
	elif dist > detection_range:
			state = State.PATROL
	elif dist > attack_range:
		state = State.IDLE
	else:
		state = State.ATTACK
	if state != prev_state: #para sortear novos pontos de fuga, preciso ressetar o run_target
		match prev_state:
			State.RUNNING:
				_run_target = Vector2.ZERO
				_has_target = false

func _process_state(delta: float) -> void:
	match state: 
		State.PATROL:
			_patrol_move(delta)
		State.IDLE:
			_stop_move()
		State.RUNNING:
			_running_away()
		State.ATTACK:
			_chase_player(delta)  

func _running_away() -> void:
	var rect := get_viewport().get_visible_rect()
	# escolhe ponto de fuga
	if not _has_target:
		_choose_run_target(rect)
	# corre para o local
	var to_target := _run_target - global_position
	var dist := to_target.length()
	if dist > spot_tolerance:
		var dir := to_target.normalized()
		velocity = dir * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	
func _patrol_move(delta: float) -> void: #praticamente n usa
	velocity.x = _dir_x * move_speed
	velocity.y = 0.0
	move_and_slide()
	if global_position.x <= patrol_left_x:
		_dir_x = 1
	elif global_position.x >= patrol_right_x:
		_dir_x = -1

func _stop_move() -> void:
	velocity = Vector2.ZERO
	move_and_slide()

func _chase_player(delta: float) -> void:
	if _player == null:
		_stop_move()
		_spot_target = Vector2.ZERO
		_stuck_timer = 0.0
		_last_pos = global_position
		return
	# sortear alvo
	if _spot_target == Vector2.ZERO or _spot_timer <= 0.0:
		_pick_spot_to_attack()
	var to_spot: Vector2 = _spot_target - global_position
	var dist: float = to_spot.length()
	if dist > spot_tolerance:
		var dir: Vector2 = to_spot.normalized()
		var desired_vel: Vector2 = dir * move_speed
		velocity = desired_vel
	else:
		# chegou no ponto para
		velocity = Vector2.ZERO
		_spot_timer -= delta
		_shoot(delta)
	# ver se ta travando
	var moved_dist: float = global_position.distance_to(_last_pos)
	if moved_dist < stuck_move_threshold and dist > spot_tolerance * 2.0:
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0
	if _stuck_timer >= stuck_time:
		_spot_target = Vector2.ZERO
		_stuck_timer = 0.0
	_last_pos = global_position
	move_and_slide()

func _shoot(delta: float) -> void:
	_cool = max(0.0, _cool - delta)
	if state != State.ATTACK:
		return
	if _player == null or bala_scene == null: 
		return
	if _cool > 0.0:
		return
	var b := bala_scene.instantiate()#problema que eu estava tendo com a bala resolvido
	var parent := get_parent()
	parent.add_child(b)
	b.global_position = global_position
	var dir := (_player.global_position - global_position).normalized()#para passar a posição do player como alvo
	if b.has_method("setup"):
		b.setup(dir)
	_cool = shoot_cooldown

func _got_hit(damage:int) -> void:#igual player
	if is_invulnerable:
		return
	life -= damage
	_start_i_frames(i_frame_time)
	if life <= 0:
		_dead = true

func _death_has_come()->void:
	queue_free()
	_lotery()
	emit_signal("died") # controle de waves 

func _lotery()->void:# decidir o que ele vai deixar ao morrer
	var options = [powerup_scene, life_b, powerup_scene_fire]
	var winner: PackedScene = options.pick_random()
	var p := winner.instantiate()
	var parent := get_parent()
	parent.add_child(p)
	p.global_position = global_position

func _start_i_frames(duration: float) -> void:
	is_invulnerable = true
	_flash_start()
	await get_tree().create_timer(duration).timeout
	_flash_stop()
	is_invulnerable = false

func _flash_start() -> void:
	# Cancela tween antigo se existir
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween().set_loops()
	_flash_tween.tween_property(self, "modulate:a", 0.3, 0.08)
	_flash_tween.tween_property(self, "modulate:a", 1.0, 0.08)

func _flash_stop() -> void:
	modulate.a = 1.0
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = null

func _clamp_inside_view() -> void:
	var rect := get_viewport().get_visible_rect()
	var p := global_position
	p.x = clampf(p.x, rect.position.x + 8.0, rect.end.x - 8.0)
	p.y = clampf(p.y, rect.position.y + 8.0, rect.end.y - 8.0)
	global_position = p

func _choose_run_target(rect: Rect2) -> void:
	# pontos de fuga 
	var center := rect.position + rect.size * 0.5
	var right_mid := rect.position + Vector2(rect.size.x, rect.size.y * 0.5)
	var top_right := rect.position + Vector2(rect.size.x * 0.8, rect.size.y * 0.25)
	var bottom_right := rect.position + Vector2(rect.size.x * 0.85, rect.size.y * 0.75)
	var top_left := rect.position + Vector2(rect.size.x * 0.2, rect.size.y * 0.25)
	var bottom_mid := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.9)
	var all_points: Array[Vector2] = [
		center,
		right_mid,
		top_right,
		bottom_right,
		top_left,
		bottom_mid
	]
	var points := all_points.duplicate()
	if _player != null: 
		points = points.filter(
			func(p: Vector2) -> bool:
				return p.distance_to(_player.global_position) > min_distance_from_player)
	if _player != null and points.is_empty(): 	# se todos derem colisão, pega o mais distante do player
		var best_point := all_points[0]
		var best_dist := best_point.distance_to(_player.global_position)
		for p in all_points:
			var d := p.distance_to(_player.global_position)
			if d > best_dist:
				best_dist = d
				best_point = p
		_run_target = best_point
	else:
		# sorteia um dos pontos seguros
		var pool := points if not points.is_empty() else all_points
		_run_target = pool[randi() % pool.size()]
	_has_target = true

func _pick_spot_to_attack() -> void: #é usado para mover o inimigo em uma posição ideal 
	if _player == null:
		return
	var rect := get_viewport().get_visible_rect()
	var player_pos := _player.global_position
	# raio de tolerancia 
	var inner_r: float = max(0.0, desired_distance - distance_tolerance)
	var outer_r: float = desired_distance + distance_tolerance
	var radius: float = randf_range(inner_r, outer_r)
	var max_angle: float = deg_to_rad(60.0)  # tentando manter inimigo a direita e na frente do player para poder tomar tiro
	var angle: float = randf_range(-max_angle, max_angle)
	var dir: Vector2 = Vector2.RIGHT.rotated(angle).normalized()
	var candidate: Vector2 = player_pos + dir * radius
	#não deixar travar na margem
	var min_x: float = rect.position.x + screen_margin
	var max_x: float = rect.position.x + rect.size.x - screen_margin
	var min_y: float = rect.position.y + screen_margin
	var max_y: float = rect.position.y + rect.size.y - screen_margin
	candidate.x = clamp(candidate.x, min_x, max_x)
	candidate.y = clamp(candidate.y, min_y, max_y)
	_spot_target = candidate #onde ele vai 
	_spot_timer = spot_hold_time #tempo que se mantem no lugar escolhido
