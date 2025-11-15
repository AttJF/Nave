extends Area2D

@export var speed: float = 800.0
@export var max_lifetime: float = 2.0  
@export var damage: int = 5
@export var cooldown_time: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var _life: float = 0.0
signal hit(target: Node)
signal start_cooldown(cooldown_time: float)

func setup(dir: Vector2) -> void:
	if dir.length() > 0.0:
		direction = dir.normalized()
	else:
		direction = Vector2.RIGHT

func _ready() -> void:
	emit_signal("start_cooldown", cooldown_time)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_life += delta

	if _life >= max_lifetime or _is_out_of_screen():
		queue_free()

func _is_out_of_screen() -> bool:
	var rect := get_viewport_rect()
	return not rect.has_point(global_position)

func _on_body_entered(body: Node) -> void:
	emit_signal("hit", body)
	if body.has_method("_got_hit"):
		body._got_hit(damage)
	queue_free()
