extends Area2D
@export var speed: float = 800.0#velocidade
@export var max_lifetime: float = 2.0  #quanto tempo fica na tela
@export var damage: int = 1
@export var cooldown_time: float = 0.30# cooldown de quando posso atirar de novo
var direction: Vector2 = Vector2.RIGHT #vai so para a direita
var _life: float = 0.0
signal hit(target: Node)
signal start_cooldown(cooldown_time: float)

func setup(dir: Vector2) -> void:
	if dir.length() > 0.0:
		direction = dir.normalized()
	else:
		direction = Vector2.RIGHT

func _ready() -> void:
	emit_signal("start_cooldown", cooldown_time) #da o sinal ao player que pode atirar novamente apos o cooldown
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_life += delta
	if _life >= max_lifetime or _is_out_of_screen():
		queue_free()

func _is_out_of_screen() -> bool:# para dar free quando sair da tela
	var rect := get_viewport_rect()
	return not rect.has_point(global_position)

func _on_body_entered(body: Node) -> void: #manda um sinal para quem foi atingido
	emit_signal("hit", body)
	if body.has_method("_got_hitp"):#para o chefão especial, so essa bala o machuca
		body._got_hitp(damage)
	elif body.has_method("_got_hit"):#para todo o resto
		body._got_hit(damage)
	queue_free()
