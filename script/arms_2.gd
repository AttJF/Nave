extends CharacterBody2D

@export var bala_scene: PackedScene
@export var powerup_scene: PackedScene
@export var powerup_scene_fire: PackedScene
@export var life_b: PackedScene
@export var i_frame_time: float = 1.4
@export var player_path: NodePath
@export var shoot_cooldown: float = 3.0
@export var life: int = 15
@export var move_amplitude_x: float = 120.0
@export var move_amplitude_y: float = 80.0
@export var move_speed_x: float = 1.5
@export var move_speed_y: float = 2.0
@export var phase_offset: float = 0.0

enum State { ATTACK, ENRAGED, DESPERATED }
signal died()
var lifetotal: int
var is_invulnerable: bool = false
var _cool: float = 0.0
var _player: Node2D = null
var _flash_tween: Tween = null
var _boss_pose: Node2D = null
var _local_offset: Vector2 = Vector2.ZERO
var _time_accum: float = 0.0
var state: int = State.ATTACK
var _prev_state: int = State.ATTACK

func set_boss_pose(center: Node2D) -> void:
	_boss_pose = center
	if is_inside_tree():
		_local_offset = global_position - _boss_pose.global_position

func set_phase(phase: int) -> void:
	match phase:
		0:
			_change_state(State.ATTACK)
		1:
			_change_state(State.ENRAGED)
		2:
			_change_state(State.DESPERATED)

func _ready() -> void:
	lifetotal = life

	if player_path != NodePath():
		_player = get_node_or_null(player_path)
	if _player == null:
		var found := get_tree().get_root().find_child("Player", true, false)
		if found != null:
			_player = found as Node2D
	_time_accum = phase_offset
	if _boss_pose != null:
		_local_offset = global_position - _boss_pose.global_position
	add_to_group("enemy")
	_change_state(state)

func _physics_process(delta: float) -> void:
	_process_state(delta)

func _change_state(new_state: int) -> void:
	if new_state == state:
		return
	_prev_state = state
	state = new_state
	_on_state_exit(_prev_state)
	_on_state_enter(state)

func _on_state_enter(s: int) -> void:
	_cool = 0.0
	match s:
		State.ENRAGED:
			_special_enraged()
		State.DESPERATED:
			_special_desesperado()

func _on_state_exit(s: int) -> void:
	pass

func _process_state(delta: float) -> void:
	var speed_mult := 1.0
	match state:
		State.ATTACK:
			speed_mult = 1.0
			_shoot_normal(delta)
		State.ENRAGED:
			speed_mult = 1.3
			_shoot_enraged(delta)
		State.DESPERATED:
			speed_mult = 1.6
			_shoot_desperated(delta)
	_update_oscillation(delta, speed_mult)

func _update_oscillation(delta: float, speed_mult: float = 1.0) -> void:
	if _boss_pose == null:
		return
	_time_accum += delta * speed_mult
	var offset_x := sin(_time_accum * move_speed_x) * move_amplitude_x
	var offset_y := sin(_time_accum * move_speed_y) * move_amplitude_y
	var base := _boss_pose.global_position + _local_offset
	global_position = base + Vector2(offset_x, offset_y)

func _can_shoot(delta: float) -> bool:
	_cool = max(0.0, _cool - delta)
	if _player == null or bala_scene == null:
		return false
	if _cool > 0.0:
		return false
	return true

func _shoot(direction: Vector2) -> void:
	if _player == null or bala_scene == null:
		return

	var dir := direction.normalized()
	var b := bala_scene.instantiate()
	var parent := get_parent()
	if parent == null:
		parent = get_tree().current_scene
	parent.add_child(b)
	b.global_position = global_position

	if b.has_method("setup"):
		b.setup(dir)

func _shoot_normal(delta: float) -> void:
	if not _can_shoot(delta):
		return
	var dir := (_player.global_position - global_position).normalized()
	_shoot(dir)
	_cool = shoot_cooldown

func _shoot_enraged(delta: float) -> void:
	if not _can_shoot(delta):
		return
	var base_dir := (_player.global_position - global_position).normalized()
	var side := base_dir.orthogonal().normalized() * 0.3
	var dirs := [
		base_dir + side,
		base_dir - side
	]
	for d in dirs:
		call_deferred("_shoot", d)
	_cool = shoot_cooldown * 0.7

func _shoot_desperated(delta: float) -> void:
	if not _can_shoot(delta):
		return
	var base_dir := (_player.global_position - global_position).normalized()
	var ortho := base_dir.orthogonal().normalized()
	var offsets: Array[float] = [-2.0, -1.0, 0.0, 1.0, 2.0]
	for o in offsets:
		var mult := 0.3 * o
		var d := (base_dir + ortho * mult).normalized()
		call_deferred("_shoot", d)
	_cool = shoot_cooldown * 0.5

func _special_attack_attack() -> void:
	if bala_scene == null or _player == null:
		return
	for i in range(3):
		var dir := (_player.global_position - global_position).normalized()
		call_deferred("_shoot", dir)

func _special_enraged() -> void:
	if bala_scene == null:
		return
	var shots := 8
	for i in range(shots):
		var angle := TAU * float(i) / float(shots)
		var dir := Vector2.RIGHT.rotated(angle)
		call_deferred("_shoot", dir)
	_cool = shoot_cooldown * 1.2

func _special_desesperado() -> void:
	if bala_scene == null:
		return
	var shots := 12
	for i in range(shots):
		var angle := TAU * float(i) / float(shots) + 0.3
		var dir := Vector2.RIGHT.rotated(angle)
		call_deferred("_shoot", dir)
	_cool = shoot_cooldown * 1.6


func _got_hitp(damage:int) -> void:
	if is_invulnerable:
		return
	life -= damage
	_start_i_frames(i_frame_time)
	if life <= 0:
		_death_has_come()

func _death_has_come() -> void:
	emit_signal("died")
	queue_free()

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
