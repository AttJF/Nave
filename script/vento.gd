extends Area2D

@export var speed: float = 300.0
@export var cooldown_time: float = 0.30

var direction: Vector2 = Vector2.LEFT  
var _life: float = 0.0

signal move_b(target: Node, is_active: bool)
signal start_cooldown(cooldown_time: float)
signal ended()

func setup(dir: Vector2) -> void:
	if dir.length() > 0.0:
		direction = dir.normalized()
	else:
		direction = Vector2.LEFT

func _ready() -> void:
	emit_signal("start_cooldown", cooldown_time)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		connect("move_b", Callable(player, "_on_wind_move_b"))

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	if _is_out_of_screen():
		await get_tree().create_timer(3.0).timeout
		emit_signal("ended")
		queue_free()

func _is_out_of_screen() -> bool:
	var rect := get_viewport_rect()
	return not rect.has_point(global_position)

func _on_body_entered(body: Node) -> void: #botar o efeito se estiver no player
	if body.is_in_group("player") or body.name == "Player":
		emit_signal("move_b", body, true)

func _on_body_exited(body: Node) -> void: #tirar o efeito se n estiver mais no player
	if body.is_in_group("player") or body.name == "Player":
		emit_signal("move_b", body, false)
