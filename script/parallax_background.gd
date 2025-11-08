extends ParallaxBackground

@export var scroll_speed: float = 100.0  #fazer ela andar 

func _process(delta: float) -> void:
	scroll_offset.x -= scroll_speed * delta
