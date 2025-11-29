extends Area2D

@export var damage: int = 2
@export var duration: float = 2.0 

var _life: float = 0.0
signal hit(target: Node)

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_life += delta
	if _life >= duration:
		queue_free()

func _on_body_entered(body: Node) -> void:
	emit_signal("hit", body)
	if body.has_method("_got_hit"):
		body._got_hit(damage)
