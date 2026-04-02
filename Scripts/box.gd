extends StaticBody2D

@onready var player: CharacterBody2D = %Player
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var slam_detector: CollisionShape2D = $Area2D/SlamDetector

@export var broken_piece_scene: PackedScene
@export var debris_spritesheet: Texture2D

var health: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.respawn_objects.connect(respawn)
	reset_values()
	
func reset_values():
	if self.name == "MetalBox":
		health = 2
	elif self.name == "WoodenBox":
		health = 1
	else:
		health = 0
	animated_sprite_2d.play("idle1")

func _on_area_2d_body_entered(_body: Node2D) -> void:
	if player.box_breakable:
		call_deferred("box_break", player)

func box_break(player_name):
	player_name.velocity.y = -200
	if player_name.slam_effect == "jump":
		if health > 0:
			health -= 1
			animated_sprite_2d.play("hit1")
			await animated_sprite_2d.animation_finished
			animated_sprite_2d.play("idle1")
		else:
			broken_pieces()
	elif player_name.slam_effect == "double_jump" and self.name != "MetalBox":
		broken_pieces()
	elif player_name.slam_effect == "double_jump" and self.name == "MetalBox":
		if health > 0:
			health -= 2
			animated_sprite_2d.play("hit1")
			await animated_sprite_2d.animation_finished
			animated_sprite_2d.play("idle1")
		else:
			broken_pieces()

func broken_pieces():
	for i in range(4):
		var piece = broken_piece_scene.instantiate()
		get_tree().current_scene.add_child(piece)
		piece.global_position = global_position
		
		piece.setup_piece(i, debris_spritesheet)
		
		# --- The Explosion Effect ---
		var random_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, -0.2)).normalized()
		var random_force = randf_range(150, 400) 
		piece.apply_central_impulse(random_direction * random_force)
		
	hide()
	collision_shape_2d.disabled = true
	slam_detector.disabled = true

func respawn():
	reset_values()
	collision_shape_2d.disabled = false
	slam_detector.disabled = false
	show()
	Global.fade_in(self)
