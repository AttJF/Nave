class_name Player
extends CharacterBody2D

@export var move_speed: float = 300.0
@export var bala_scene: PackedScene   
@export var i_frame_time: float = 1.4     
@export var bala_rocket_scene: PackedScene
@export var bala_power_scene: PackedScene
@export var bala_spread_scene: PackedScene
@export var bala_laser_scene: PackedScene

enum balaType { NORMAL, ROCKET, SHOTGUN, FIRE }
var current_bala_type: balaType = balaType.NORMAL
var is_invulnerable : bool = false
var can_shoot: bool = true
var life: int = 1
signal bala_type_changed(new_type: int)
signal life_changed(life :int)

func _physics_process(delta: float) -> void:
	_move(delta)
	_shoot(delta)
	_clamp_inside_view()

func _ready() -> void:
	life_changed.emit(life)
	connect("bala_type_changed", Callable(self, "_on_bala_type_changed"))

func _move(delta: float) -> void: #mover nas direções 
	var input_vec := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	velocity = input_vec * move_speed
	move_and_slide()

func _shoot(delta: float) -> void:
	if not Input.is_action_pressed("shoot"):
		return
	if not can_shoot: #controle do cooldown, o tempo de cooldown é passado pela cena bala
		return	
	var muzzle := $Muzzle #muzzle
	var scene := _get_current_bala_scene()
	if scene == null:
		return
	var b := scene.instantiate() #instancia primeiro
	if b.has_signal("start_cooldown"): #pega o sinal do cooldown
		b.connect("start_cooldown", Callable(self, "_on_bala_start_cooldown"))
	var parent := get_parent() # instacia com parente para a bala se mover por conta
	parent.add_child(b)
	can_shoot = false
	b.global_position = muzzle.global_position
	var dir := Vector2.RIGHT
	if b.has_method("setup"):
		b.setup(dir)

func _on_bala_type_changed(new_type: int) -> void:
	current_bala_type = new_type

func _get_current_bala_scene() -> PackedScene:
	match current_bala_type:
		balaType.NORMAL:
			return bala_scene
		balaType.ROCKET:
			return bala_rocket_scene
		balaType.SHOTGUN:
			return bala_spread_scene
		balaType.FIRE:
			return bala_laser_scene
		_:
			return bala_scene

func _got_hit(damage:int) -> void:
	if is_invulnerable:
		return
	life -= damage
	life_changed.emit(life)
	_start_i_frames(i_frame_time) 
	if life <=0:
		death_has_come()

func death_has_come()->void:
	queue_free()
	get_tree().change_scene_to_file("res://scene/tela_perdeu.tscn")  
	
func _clamp_inside_view() -> void: #manter o player na tela 
	var rect := get_viewport_rect()
	var p := global_position
	p.x = clamp(p.x, rect.position.x + 8.0, rect.end.x - 8.0)
	p.y = clamp(p.y, rect.position.y + 8.0, rect.end.y - 8.0)
	global_position = p
	
func _start_i_frames(duration: float) -> void:
	is_invulnerable = true
	_flash_start() #pisca pisca
	await get_tree().create_timer(duration).timeout
	_flash_stop()
	is_invulnerable = false

#pisca pisca
func _flash_start() -> void:
	if has_node("."):
		# pisca usando Tween 
		var tween := create_tween().set_loops() # loopando
		tween.tween_property(self, "modulate:a", 0.3, 0.08)
		tween.tween_property(self, "modulate:a", 1.0, 0.08)

func _on_bala_start_cooldown(cd: float) -> void:
	_start_shoot_cooldown(cd)

func _start_shoot_cooldown(cd: float) -> void: #timer recebido do sinal da bala 
	await get_tree().create_timer(cd).timeout
	can_shoot = true

func _flash_stop() -> void:
	modulate.a = 1.0
	for t in get_tree().get_processed_tweens():
		if t.is_valid():
			t.kill()
