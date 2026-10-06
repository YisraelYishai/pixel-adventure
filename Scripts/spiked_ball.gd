extends Node2D

@export_category("Preferences")
@export var swing_speed: float = 1.75
@export var max_angle_degrees: float = 60.0
@export var length: float = 75.0

var chain_texture: Texture2D = preload("res://Assets/Pixel Adventure 1/Traps/Spiked Ball/Chain.png")
var spacing: float = 12.0
var time_passed: float = 0.0
var previous_pos: Vector2
var knockback_scale: float = 1.25
var max_knockback_speed: float = 300.0

@onready var chain_container: Node2D = $ChainContainer
@onready var detector: Area2D = $Ball/Detector

func _ready() -> void:
	previous_pos = global_position
	detector.position.y = length + 5
	
	_build_chain()

func _process(delta: float) -> void:
	time_passed += delta
	rotation_degrees = sin(time_passed * swing_speed) * max_angle_degrees

func _physics_process(_delta: float) -> void:
	for body in detector.get_overlapping_bodies():
		_on_detector_body_entered(body)

func _build_chain() -> void:
	var num_links = int(length / spacing)
	
	for i in range(num_links):
		var link_sprite = Sprite2D.new()
		link_sprite.texture = chain_texture
		
		link_sprite.position = Vector2(0, i * spacing)
		
		chain_container.add_child(link_sprite)

func get_sweep_velocity() -> Vector2:
	var ang_vel := deg_to_rad(max_angle_degrees) * swing_speed * cos(time_passed * swing_speed)
	var r := detector.global_position - global_position
	var vel := Vector2(-r.y, r.x) * ang_vel * knockback_scale
	return vel.limit_length(max_knockback_speed)

func _on_detector_body_entered(body: Node2D) -> void:
	if body is Player and body.has_method("hit"):
		body.hit(global_position, get_sweep_velocity())
