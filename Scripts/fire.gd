extends StaticBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var active: bool = false
var fire_presence: bool = false
var character

func _ready() -> void:
	animated_sprite_2d.play("off")

func _process(_delta: float) -> void:
	if active and fire_presence:
		character.hit(global_position)

func fire():
	animated_sprite_2d.play("activation")
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play("on")
	active = true
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play("off")
	active = false

func _on_hitbox_body_entered(body: Node2D) -> void:
	character = body
	fire()

func _on_fire_body_entered(_body: Node2D) -> void:
	fire_presence = true

func _on_fire_body_exited(_body: Node2D) -> void:
	fire_presence = false
