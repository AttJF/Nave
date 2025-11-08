extends ParallaxLayer

func _ready() -> void: #tentar corrigir linha quando a imagem da mirror
	var sprite: Sprite2D = $Sprite2D
	if sprite.texture:
		var tex_size: Vector2 = sprite.texture.get_size()
		motion_mirroring.x = tex_size.x * sprite.scale.x
