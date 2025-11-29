extends CharacterBody2D

@export var shoot_cooldown: float = 4.0 
@export var bala_scene: PackedScene
@export var powerup_scene: PackedScene
@export var powerup_scene_fire: PackedScene
@export var life_b: PackedScene
@export var i_frame_time: float = 1.4
@export var player_path: NodePath
@export var inimigo_scene: PackedScene

var _cool: float = 0.0
var is_invulnerable : bool = false
var life: int = 6
var lifetotal: int = 10 
var _player: Node2D = null
var _flash_tween: Tween = null
var _dead : bool = false
signal died()

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
	velocity = Vector2.ZERO#n se move
	move_and_slide()
	global_position = global_position#trava no lugar, para o player n conseguir arrastar
	await get_tree().create_timer(3.0).timeout# esperar um pouco antes de atacar
	_shoot(delta)

func _shoot(delta: float) -> void:
	_cool = max(0.0, _cool - delta)
	if _player == null or bala_scene == null:
		return
	if _cool > 0.0:
		return
	var b := bala_scene.instantiate()
	var parent := get_parent()
	parent.add_child(b)
	b.global_position = global_position
	var dir := (_player.global_position - global_position).normalized()
	if b.has_method("setup"):
		b.setup(dir)
	_cool = shoot_cooldown

func _got_hit(damage:int) -> void:
	if is_invulnerable:
		return
	life -= damage
	_start_i_frames(i_frame_time)
	if life <= 0:
		_dead = true

func _death_has_come() -> void:
	var i := inimigo_scene.instantiate()
	var parent := get_parent()
	parent.add_child(i)#instancia um inimigo ao morrer
	i.global_position = global_position
	_lotery()
	emit_signal("died")
	queue_free()


func _lotery() -> void: # sortear qual power up vai deixar 
	var options = [powerup_scene, life_b, powerup_scene_fire]
	var winner: PackedScene = options.pick_random()
	if winner == null:
		return
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
