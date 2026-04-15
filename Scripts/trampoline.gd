extends AnimatedSprite2D

@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D

func _ready() -> void:
	play("idle")
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		if animation == "idle" and body.slamming == false:
			body.apply_bounce(-450)
			play("jump")
			await animation_finished
			play("idle")
