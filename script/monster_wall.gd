extends CharacterBody2D

@export var move_speed: float = 5    # velocidade base
@export var max_speed: float = 1200.0          # velocidade máxima
@export var acceleration: float = 3.0        # quanto acelera por segundo
@export var knockback_distance: float = 100.0   # recuo ao tomar hit
@export var slow_factor: float = 0.25          # % da velocidade que sobra após hit
@export var min_speed_after_hit: float = 5.0  # velocidade mínima depois do hit

var _current_speed: float = 0.0

func _ready() -> void:
	_current_speed = move_speed

func _physics_process(delta: float) -> void:
	_current_speed = min(_current_speed + acceleration * delta, max_speed)
	velocity.x = _current_speed
	velocity.y = 0.0
	move_and_slide()
	_smash_player() 

func _smash_player() -> void:
	var count := get_slide_collision_count()# ve quantas coisas esta colididno
	for i in range(count):# for para testar com o que esta colidindo
		var col := get_slide_collision(i)
		var body := col.get_collider()
		if body == null:
			continue
		if body.name == "Player":#se for player mata ele 
			if body.has_method("_got_hit"):
				body._got_hit(999999)

func _got_hit(damage: int) -> void:
	global_position.x -= knockback_distance# se tomar dano empurra para traz
	_current_speed *= slow_factor#tambem diminui velocidade
	_current_speed = max(_current_speed, min_speed_after_hit) # so para garantir que tera uma velocidade minima
