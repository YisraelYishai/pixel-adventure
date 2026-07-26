extends StaticBody2D

@onready var detector: Area2D = $Detector
@onready var collision_shape: CollisionShape2D = $Detector/CollisionShape2D
@onready var gpuparticles2d: GPUParticles2D = $GPUParticles2D

@export_category("Preferences")
@export_enum("Up", "Down", "Left", "Right") var orientation: String = "Up"
@export var max_fan_strength := 125.0

const TERMINAL_VELOCITY = 150.0

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

	gpuparticles2d.emitting = true
	var mat = gpuparticles2d.process_material as ParticleProcessMaterial
	mat.direction = Vector3(fan_direction.x, fan_direction.y, 0)

	mat.initial_velocity_min = max_fan_strength * 0.2
	mat.initial_velocity_max = max_fan_strength * 0.3

	var max_range = 50.0
	gpuparticles2d.lifetime = max_range / mat.initial_velocity_min


func _physics_process(_delta: float) -> void:
	if is_colliding and player and player.slamming == false:
		var distance = global_position.distance_to(player.global_position)

		var max_range = max_fan_strength
		if collision_shape.shape is CircleShape2D:
			max_range = collision_shape.shape.radius
		elif collision_shape.shape is RectangleShape2D:
			max_range = collision_shape.shape.size.y

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
