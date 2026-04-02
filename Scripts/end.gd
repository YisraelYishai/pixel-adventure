extends StaticBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.global_position.y < global_position.y:
		animated_sprite_2d.play("pressed")
		await get_tree().create_timer(0.2).timeout
		body.end()
