extends StaticBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.global_position.y < global_position.y:
		# Player freeze logic
		body.velocity = Vector2.ZERO
		body.can_move = false
		body.animator_status = false
		body.animator.play("idle" + body.player_character)
		
		animated_sprite_2d.play("pressed")
		$Confetti.restart()
		await $AnimatedSprite2D.animation_finished
		body.end()
