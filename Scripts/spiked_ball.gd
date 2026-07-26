extends Node2D

@export_category("Preferences")
@export var swing_speed: float = 1.75
@export var max_angle_degrees: float = 60.0
@export var length: float = 75.0

var chain_texture: Texture2D = preload("res://Assets/Pixel Adventure 1/Traps/Spiked Ball/Chain.png")
var spacing: float = 12.0
var time_passed: float = 0.0
var previous_pos: Vector2

@onready var chain_container: Node2D = $ChainContainer
@onready var detector: Area2D = $Ball/Detector

func _ready() -> void:
	previous_pos = global_position
	detector.position.y = length + 5
	
	_build_chain()

func _process(delta: float) -> void:
	var current = global_position
	var sweep_velocity = current - previous_pos
	previous_pos = current
	
	time_passed += delta

	var angle = sin(time_passed * swing_speed) * max_angle_degrees

	rotation_degrees = angle


func _build_chain() -> void:
	var num_links = int(length / spacing)
	
	for i in range(num_links):
		var link_sprite = Sprite2D.new()
		link_sprite.texture = chain_texture
		
		link_sprite.position = Vector2(0, i * spacing)
		
		chain_container.add_child(link_sprite)

func _on_detector_body_entered(body: Node2D) -> void:
	if body is Player and body.has_method("hit"):
		var sweep_velocity = global_position - previous_pos
		body.hit(global_position, sweep_velocity)
