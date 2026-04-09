extends AnimatableBody2D

@onready var path_follow_2d: Path2D = $"../.."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	animated_sprite_2d.play("idle")

func _on_hitbox_body_entered(body: Node2D) -> void:
	var pos = self.global_position
	if body.has_method("hit") and path_follow_2d.is_dangerous:
		body.hit(pos)
