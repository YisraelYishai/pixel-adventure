extends StaticBody2D

@onready var detector: Area2D = $Detector
@onready var collision_shape: CollisionShape2D = $Detector/CollisionShape2D

const MAX_FAN_STRENGTH = 25.0
const MAX_UPWARD_SPEED = -300.0   # cap so player doesn’t fly infinitely

var player: CharacterBody2D = null
var is_colliding = false

func _physics_process(_delta: float) -> void:
	if is_colliding and player:
		var distance = global_position.distance_to(player.global_position)
		var max_range = collision_shape.shape.radius
		
		var intensity = pow(clamp(1.0 - (distance / max_range), 0.0, 1.0), 2)
		print(clamp(abs(1.0 - (distance / max_range)), 0.0, 1.0))
		player.velocity.y -= MAX_FAN_STRENGTH * intensity
		
		player.velocity.y = max(player.velocity.y, MAX_UPWARD_SPEED)

func _on_detector_body_entered(body: Node2D) -> void:
	# Only affect your Player (safer than generic body)
	if body is Player:
		player = body
		is_colliding = true

func _on_detector_body_exited(body: Node2D) -> void:
	if body == player:
		is_colliding = false
		player = null
