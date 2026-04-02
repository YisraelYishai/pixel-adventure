extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var status: bool = false
var send_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	send_position = Vector2(position.x + 10, position.y)
	animated_sprite_2d.play("default")

func _on_body_entered(body: Node2D) -> void:
	if status == false:
		status = true
		body.new_respawn(send_position)
		animated_sprite_2d.play("flag_out")
		await animated_sprite_2d.animation_finished
		animated_sprite_2d.play("flag_idle")
