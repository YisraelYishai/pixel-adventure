extends StaticBody2D

@onready var detector: Area2D = $Detector
@onready var collision_shape: CollisionShape2D = $Detector/CollisionShape2D

@export_enum("Up", "Down", "Left", "Right") var orientation: String = "Up"
@export var max_fan_strength := 1000.0

const TERMINAL_VELOCITY = 200.0

var fan_direction: Vector2
var player: CharacterBody2D = null
var is_colliding = false

func _ready() -> void:
	if orientation == "Up":
		fan_direction = Vector2(0, -1)
	elif orientation == "Down":
		fan_direction = Vector2(0, 1)
	elif orientation == "Left":
		fan_direction = Vector2(-1, 0)
	elif orientation == "Right":
		fan_direction = Vector2(1, 0)

func _physics_process(_delta: float) -> void:
	if is_colliding and player:
		var distance = global_position.distance_to(player.global_position)
		
		var max_range = 100.0
		if collision_shape.shape is CircleShape2D:
			max_range = collision_shape.shape.radius
		elif collision_shape.shape is RectangleShape2D:
			max_range = collision_shape.shape.size.y # Or size.x depending on orientation
		
		var intensity = clamp(1.0 - (distance / max_range), 0.0, 1.0)
		
		var push_vector = fan_direction * (max_fan_strength * intensity)
		
		player.velocity += push_vector
		
		player.velocity = player.velocity.limit_length(TERMINAL_VELOCITY)

func _on_detector_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player = body
		is_colliding = true

func _on_detector_body_exited(body: Node2D) -> void:
	if body == player:
		is_colliding = false
		player = null
