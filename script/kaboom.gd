extends Area2D

@export var max_lifetime: float = 0.2  
@export var damage: int = 2

var _life: float = 0.0
signal hit(target: Node)
#explosão semelhante ao field, vai ser aplicado em quem for atingido pelo rocket
func _ready() -> void:
	monitoring = true
	await get_tree().process_frame
	body_entered.connect(_on_body_entered)
	for body in get_overlapping_bodies():
		_apply_damage(body)

func _physics_process(delta: float) -> void:
	_life += delta
	if _life >= max_lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_apply_damage(body)

func _apply_damage(body: Node) -> void:
	emit_signal("hit", body)
	if body.has_method("_got_hitr"):
		body._got_hitr(damage)
	elif body.has_method("_got_hit"):
		body._got_hit(damage)
	queue_free()
