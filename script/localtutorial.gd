extends Area2D
signal point_reach

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name != "Player":
		return
	hide()
	set_deferred("monitorable", false)
	emit_signal("point_reach")
	queue_free()
