extends RigidBody2D

@onready var sprite = $Sprite2D

func setup_piece(frame_index: int, piece_texture: Texture2D):
	# Apply the specific spritesheet for this box variety
	sprite.texture = piece_texture 
	# Set the frame
	sprite.frame = frame_index

func _ready():
	var tween = create_tween()
	tween.tween_interval(1.0)

	var flash_count = 5
	var flash_speed = 0.1

	for i in flash_count:
		tween.tween_property(sprite, "modulate:a", 0.0, flash_speed)
		tween.tween_property(sprite, "modulate:a", 1.0, flash_speed)

	tween.tween_property(sprite, "modulate:a", 0.0, flash_speed)

	tween.tween_callback(queue_free)
