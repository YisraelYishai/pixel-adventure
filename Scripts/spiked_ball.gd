extends Node2D

@export_category("Pendulum")
@export var length: float = 75.0
@export var gravity: float = 250.0
@export var start_angle_degrees: float = 60.0
@export_range(0.0, 2.0) var damping: float = 0.05
@export var keep_swinging: bool = true
@export_range(0.0, 10.0) var motor_strength: float = 1.0

var knockback_scale: float = 1.0
var max_knockback_speed: float = 200.0
var hit_cooldown: float = 0.5
var recoil: float = 0.2

var chain_texture: Texture2D = preload("res://Assets/Pixel Adventure 1/Traps/Spiked Ball/Chain.png")
var spacing: float = 12.0

var angle: float            
var angular_velocity: float = 0.0
var target_energy: float
var _cooldowns: Dictionary = {}

@onready var chain_container: Node2D = $ChainContainer
@onready var detector: Area2D = $Ball/Detector

func _ready() -> void:
	detector.position.y = length + 5
	angle = deg_to_rad(start_angle_degrees)
	rotation = angle
	target_energy = _energy()
	_build_chain()

func _physics_process(delta: float) -> void:
	_step_pendulum(delta)
	_tick_cooldowns(delta)
	_check_hits()


func _energy() -> float:
	var kinetic := 0.5 * length * length * angular_velocity * angular_velocity
	var potential := gravity * length * (1.0 - cos(angle))
	return kinetic + potential

func _step_pendulum(delta: float) -> void:
	var accel := -(gravity / length) * sin(angle) - damping * angular_velocity
	angular_velocity += accel * delta  
	angle += angular_velocity * delta

	if keep_swinging and absf(angular_velocity) > 0.01:
		var missing := target_energy - _energy()
		var push := signf(angular_velocity) * missing / (length * length)
		angular_velocity += push * motor_strength * delta

	rotation = angle

func get_tip_velocity() -> Vector2:
	var r := detector.global_position - global_position
	return Vector2(-r.y, r.x) * angular_velocity


func _check_hits() -> void:
	var vel := get_tip_velocity()
	for body in detector.get_overlapping_bodies():
		if body is Player and body.has_method("hit") and not _cooldowns.has(body):
			_hit_body(body, vel)

func _hit_body(body: Node2D, vel: Vector2) -> void:
	var push := (vel * knockback_scale).limit_length(max_knockback_speed)
	body.hit(global_position, push)
	_cooldowns[body] = hit_cooldown
	angular_velocity *= 1.0 - recoil
	target_energy = maxf(target_energy, _energy())

func _tick_cooldowns(delta: float) -> void:
	for body in _cooldowns.keys():
		_cooldowns[body] -= delta
		if _cooldowns[body] <= 0.0 or not is_instance_valid(body):
			_cooldowns.erase(body)


func _build_chain() -> void:
	var num_links := ceili(length / spacing)
	for i in num_links:
		var link := Sprite2D.new()
		link.texture = chain_texture
		link.position = Vector2(0, i * spacing)
		chain_container.add_child(link)
