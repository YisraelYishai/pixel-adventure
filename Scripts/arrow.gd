extends Area2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	Global.respawn_objects.connect(respawn)

func _on_body_entered(body: Node2D) -> void:
	if body.slamming == false:
		body.cam.apply_shake(1)
		body.velocity.y = -450
		body.air_jump += 1
	$AnimatedSprite2D.play("hit")
	await $AnimatedSprite2D.animation_finished
	hide()
	collision_shape_2d.disabled = true
	
func respawn():
	$AnimatedSprite2D.play("default")
	collision_shape_2d.disabled = false
	show()
	Global.fade_in(self)
