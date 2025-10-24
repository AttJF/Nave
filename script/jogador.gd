extends CharacterBody2D

@export var move_speed: float = 300.0
@export var shoot_cooldown: float = 0.30
@export var bala_scene: PackedScene       

var _cool: float = 0.0

func _physics_process(delta: float) -> void:
	_move(delta)
	_shoot(delta)
	_clamp_inside_view()

func _move(delta: float) -> void: #mover nas direções 
	var input_vec := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	velocity = input_vec * move_speed
	move_and_slide()

func _shoot(delta: float) -> void:
	_cool = max(0.0, _cool - delta)
	if Input.is_action_pressed("shoot") and _cool == 0.0 and bala_scene:
		var b := bala_scene.instantiate()
		var spawn_pos := global_position
		var dir := Vector2.RIGHT 
		b.global_position = spawn_pos
		b.setup(dir)  
		get_tree().current_scene.add_child(b)  #corrigir problema de bala" andar com o jogador
		_cool = shoot_cooldown


func _clamp_inside_view() -> void: #manter o player na tela 
	
	var rect := get_viewport_rect()
	var p := global_position
	p.x = clamp(p.x, rect.position.x + 8.0, rect.end.x - 8.0)
	p.y = clamp(p.y, rect.position.y + 8.0, rect.end.y - 8.0)
	global_position = p
