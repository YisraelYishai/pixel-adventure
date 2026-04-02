extends StaticBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func runtime():
	animated_sprite_2d.play("moving")
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play("default")


func _on_area_2d_body_entered(_body: Node2D) -> void:
	runtime()
