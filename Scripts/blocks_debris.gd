extends RigidBody2D

var animation_speed: float = 10.0
var frame_timer: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D

func _process(delta):
	if sprite.hframes > 1 and sprite.frame < (sprite.hframes - 1):
		frame_timer += delta * animation_speed
		if frame_timer >= 1.0:
			frame_timer = 0.0
			sprite.frame += 1

func _on_timer_timeout():
	var tween = create_tween()
	var flash_count = 5
	var flash_speed = 0.1

	for i in flash_count:
		tween.tween_property(sprite, "modulate:a", 0.0, flash_speed)
		tween.tween_property(sprite, "modulate:a", 1.0, flash_speed)

	tween.tween_property(sprite, "modulate:a", 0.0, flash_speed)
	tween.tween_callback(queue_free)
