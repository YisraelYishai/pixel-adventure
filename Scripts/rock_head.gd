extends AnimatableBody2D

@onready var path_follow_2d: PathFollow2D = $".."
var i = 1

func _on_hitbox_body_entered(body: Node2D) -> void:
	var pos = self.global_position
	if body.has_method("hit") and path_follow_2d.is_dangerous:
		body.hit(pos)
	print("Hit ", i, ", number of times and Path2D is_dangerous = ", path_follow_2d.is_dangerous)
	i += 1
