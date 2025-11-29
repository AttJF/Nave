extends CharacterBody2D

@export var field_scene: PackedScene #golpe especial
@export var bala_scene: PackedScene #bala
@export var i_frame_time: float = 1.4 #iframes
@export var player_path: NodePath
@export var shoot_cooldown: float = 3.0
@export var life: int = 10
@export var orbit_radius: float = 180.0 #raio do giro
@export var orbit_start_angle_deg: float = -60.0
@export var orbit_end_angle_deg: float = 60.0
@export var orbit_speed_deg: float = 60.0
@export var warning_scene: PackedScene #sprite de aviso para poder ver o golpe vindo
@export var warning_time: float = 0.6 # tempo entre aviso

var shot_points: Array[Marker2D] = []
enum State { ATTACK, ENRAGED, DESPERATED }#estados
var _field_timer: float = 0.0
var lifetotal: int
var is_invulnerable: bool = false
var _cool: float = 0.0
var _player: Node2D = null
var _flash_tween: Tween = null
var _angle_deg: float
var _dir: int = 1 # para poder inverter quando sair da tela(clampview)
var _boss_pose: Node2D = null
var state: int = State.ATTACK
var _prev_state: int = State.ATTACK
signal died()

func set_boss_pose(center: Node2D) -> void:#setar a onde ele vai ficar transladando
	_boss_pose = center

func set_phase(phase: int) -> void:#as fases
	match phase:
		0:
			_change_state(State.ATTACK)#ninguem morreu
		1:
			_change_state(State.ENRAGED)#morreu 1 parte
		2:
			_change_state(State.DESPERATED)#morreu 2 partes

func _ready() -> void:
	lifetotal = life
	if player_path != NodePath():
		_player = get_node_or_null(player_path)
	if _player == null:
		var found := get_tree().get_root().find_child("Player", true, false)
		if found != null:
			_player = found as Node2D
	_angle_deg = (orbit_start_angle_deg + orbit_end_angle_deg) * 0.5
	if _boss_pose == null and get_parent() is Node2D:#tratar se o boss pose estiver null
		_boss_pose = get_parent() as Node2D
	shot_points.clear()#carregar os pontos onde ele vai usar o golpe especial
	if has_node("ClusterShot"):
		var cluster := $ClusterShot
		for child in cluster.get_children():
			if child is Marker2D:
				shot_points.append(child)
	_field_timer = 5.0
	_change_state(state)

func _physics_process(delta: float) -> void:
	_process_state(delta)

func _change_state(new_state: int) -> void: #logica para dar trigger quando mudar estados, provavelmente vou tirar 
	if new_state == state:
		return
	_prev_state = state
	state = new_state
	_on_state_enter(state)

func _on_state_enter(s: int) -> void:
	_cool = 0.0
	match s:
		State.ENRAGED:
			call_deferred("_special_enraged")
		State.DESPERATED:
			call_deferred("_special_desesperado")

func _process_state(delta: float) -> void:
	var orbit_mult: float = 1.0
	match state:
		State.ATTACK:
			orbit_mult = 1.0#velocidade em orbitar
			_field_timer -= delta
			if _field_timer <= 0.0:# timer para impedir que lance 500 vezes por segundo
				fire_storm()
				_field_timer = 5.0
		State.ENRAGED:
			orbit_mult = 1.5
			_field_timer -= delta
			if _field_timer <= 0.0:
				fire_storm(3)
				_field_timer = 5.0
		State.DESPERATED:
			orbit_mult = 2.0
			_field_timer -= delta
			if _field_timer <= 0.0:
				fire_storm(6)
				_field_timer = 5.0
	_update_orbit(delta, orbit_mult)

func fire_storm(waves: int = 1) -> void:#quantas vezes vai lançar
	if warning_scene == null or field_scene == null: #checando o warning scene
		return
	var parent := get_parent()
	if parent == null:
		return
	for wave in range(waves): #quantas vezes vai fazer
		var positions: Array[Vector2] = []
		for m in shot_points:# 
			if not is_instance_valid(m):
				continue
			var w := warning_scene.instantiate()#manda os avisos primeiro
			parent.add_child(w)
			w.global_position = m.global_position
			positions.append(m.global_position)
		await get_tree().create_timer(warning_time).timeout#tempo entre o aviso e a explosão de fato
		for c in parent.get_children():
			if c is Node2D and c.scene_file_path == warning_scene.resource_path:
				c.queue_free()#limpa os warning
		for pos in positions:
			var f := field_scene.instantiate()
			parent.add_child(f)
			f.global_position = pos
		if wave < waves - 1:
			await get_tree().create_timer(0.3).timeout

func _cleanup_warnings() -> void:#corrigir bug de quando morre com warning na tela 
	var parent := get_parent()
	if parent == null:
		return
	for c in parent.get_children():
		if c is Node2D and warning_scene != null and c.scene_file_path == warning_scene.resource_path:
			c.queue_free()

func _update_orbit(delta: float, speed_mult: float = 1.0) -> void:
	if _boss_pose == null:
		return
	_angle_deg += orbit_speed_deg * speed_mult * _dir * delta #altera em que grau da curva o satelite fica
	print("sat angle:", _angle_deg)
	if _angle_deg > orbit_end_angle_deg: #se passar do angulo do raio volta
		_angle_deg = orbit_end_angle_deg
		_dir = -1
	elif _angle_deg < orbit_start_angle_deg: #se passar do angulo do raio volta
		_angle_deg = orbit_start_angle_deg
		_dir = 1
	var ang_rad := deg_to_rad(_angle_deg) #transforma em radiano para por transformar
	var offset := Vector2.LEFT.rotated(ang_rad) * orbit_radius# transforma no lado esquerdo, colocondo ele no angulo junto com raio
	global_position = _boss_pose.global_position + offset
	_clamp_inside_view()

func _clamp_inside_view() -> void:
	var rect := get_viewport().get_visible_rect()
	var p := global_position
	var clamped_x := clampf(p.x, rect.position.x + 16.0, rect.end.x - 16.0)
	var clamped_y := clampf(p.y, rect.position.y + 16.0, rect.end.y - 16.0)
	if p.x != clamped_x or p.y != clamped_y:
		_dir *= -1 #muda a direção
	global_position = Vector2(clamped_x, clamped_y)

func _special_attack() -> void:
	return

func _special_enraged() -> void:
	if field_scene == null:#garantir que tem a bala
		return
	var rect := get_viewport().get_visible_rect()#pegar valor da borda
	var parent := get_parent() if get_parent() != null else self
	var spacing := 64.0
	var x := rect.position.x
	while x <= rect.end.x:#percorrer todo o y mantendo o mesmo x (area de cima)
		var f_top := field_scene.instantiate()
		parent.add_child(f_top)
		f_top.global_position = Vector2(x, rect.position.y)
		x += spacing
	x = rect.position.x
	while x <= rect.end.x:#percorrer todo o  y mantendo o mesmo x (area de baixo)
		var f_bottom := field_scene.instantiate()
		parent.add_child(f_bottom)
		f_bottom.global_position = Vector2(x, rect.end.y)
		x += spacing
	_cool = shoot_cooldown * 1.5

func _special_desesperado() -> void:
	if field_scene == null:
		return
	var rect := get_viewport().get_visible_rect()
	var parent := get_parent() if get_parent() != null else self
	var spacing := 64.0
	var x := rect.position.x
	while x <= rect.end.x:
		var f_bottom := field_scene.instantiate()
		parent.add_child(f_bottom)
		f_bottom.global_position = Vector2(x, rect.end.y)
		x += spacing
	x = rect.position.x
	while x <= rect.end.x:
		var f_top := field_scene.instantiate()
		parent.add_child(f_top)
		f_top.global_position = Vector2(x, rect.position.y)
		x += spacing
	var y := rect.position.y
	while y <= rect.end.y:
		var f_left := field_scene.instantiate()
		parent.add_child(f_left)
		f_left.global_position = Vector2(rect.position.x, y)
		y += spacing
	y = rect.position.y
	while y <= rect.end.y:
		var f_right := field_scene.instantiate()
		parent.add_child(f_right)
		f_right.global_position = Vector2(rect.end.x, y)
		y += spacing
	_cool = shoot_cooldown * 2.0
 #abaixo é o mesmo do inimigo
func _got_hitf(damage: int) -> void:#outro got_hit, para so poder tomar dano de arma especifica
	if is_invulnerable:
		return
	life -= damage
	_start_i_frames(i_frame_time)
	if life <= 0:
		_death_has_come()

func _death_has_come() -> void:
	emit_signal("died")
	queue_free()

func _exit_tree() -> void:
	_cleanup_warnings()

func _start_i_frames(duration: float) -> void:
	is_invulnerable = true
	_flash_start()
	await get_tree().create_timer(duration).timeout
	_flash_stop()
	is_invulnerable = false

func _flash_start() -> void:
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
