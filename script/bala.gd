extends Area2D

@export var speed: float = 800.0
@export var max_lifetime: float = 2.0  
var direction: Vector2 = Vector2.ZERO
var _life: float = 0.0

signal hit(target: Node)

func setup(dir: Vector2) -> void: #so vai  para a direita
	direction = Vector2.RIGHT  


func _ready() -> void:
	connect("body_entered", _on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_life += delta

	if _life >= max_lifetime or _is_out_of_screen():
		queue_free()

func _is_out_of_screen() -> bool: #apagar o projetil quando sai da tela 
	var rect := get_viewport_rect()
	return not rect.has_point(global_position)

func _on_body_entered(body: Node) -> void:
	emit_signal("hit", body)
	queue_free()
