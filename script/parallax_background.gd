extends ParallaxBackground

@export var speed_base: float = 100.0  #base
var speed_scroll: float #que esta no moment

func _ready() -> void:
	speed_scroll = speed_base

func _process(delta: float) -> void:
	scroll_offset.x -= speed_scroll * delta

func boost_speed(multiplier: float = 3.0, duration: float = 1.5) -> void:
	var tween := create_tween()
	tween.tween_property(self, "speed_scroll", speed_base * multiplier, 0.3)
	tween.tween_interval(duration)
	tween.tween_property(self, "speed_scroll", speed_base, 0.5)
