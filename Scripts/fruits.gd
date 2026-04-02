extends Area2D

@export_enum("Apple", "Bananas", "Cherries", "Kiwi", "Melon", "Orange", "Pineapple", "Strawberry") var options: String = "Apple"
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animated_sprite_2d.play(options)

func _on_body_entered(body: Node2D) -> void:
	body.fruit_collected()
	animated_sprite_2d.play("Collected")
	await animated_sprite_2d.animation_finished
	queue_free()
