extends StaticBody2D

var debris_scene = preload("res://Scenes/blocks_debris.tscn")

var part_1_tex = preload("res://Assets/Pixel Adventure 1/Traps/Blocks/Part 1 (22x22).png")
var part_2_tex = preload("res://Assets/Pixel Adventure 1/Traps/Blocks/Part 2 (22x22).png")

func _ready() -> void:
	Global.respawn_objects.connect(respawn)

func smash_block(was_slamming):
	if was_slamming:
		$AnimatedSprite2D.play("hit_side")
	else:
		$AnimatedSprite2D.play("hit_top")
	$CollisionShape2D.disabled = true
	$HitboxBottom/CollisionShape2D.disabled = true
	$HitboxTop/CollisionShape2D.disabled = true
	var piece1 = debris_scene.instantiate()
	var piece2 = debris_scene.instantiate()
	
	var sprite1 = piece1.get_node("Sprite2D")
	sprite1.texture = part_1_tex
	sprite1.hframes = 3
	sprite1.vframes = 1
	sprite1.frame = 0
	
	var sprite2 = piece2.get_node("Sprite2D")
	sprite2.texture = part_2_tex
	sprite2.hframes = 3
	sprite2.vframes = 1
	sprite2.frame = 0
	
	get_tree().current_scene.add_child(piece1)
	get_tree().current_scene.add_child(piece2)
	
	piece1.global_position = global_position + Vector2(0, 2)
	piece2.global_position = global_position + Vector2(0, -2)
	piece1.add_constant_torque(randi_range(150, 200))
	piece2.add_constant_torque(randi_range(150, 200))
	piece1.apply_impulse(Vector2(randi_range(-30, -40), 0))
	piece2.apply_impulse(Vector2(randi_range(-30, -40), randi_range(-30, -40)))
	
	await $AnimatedSprite2D.animation_finished
	hide()

func _on_hitbox_bottom_body_entered(body: Node2D) -> void:
	body.cam.screen_shake(2, 2)
	body.velocity = Vector2(0, 50)
	call_deferred("smash_block", false)

func _on_hitbox_top_body_entered(body: Node2D) -> void:
	if body.box_breakable == true:
		body.cam.screen_shake(2, 2)
		body.velocity = Vector2(0, 50)
		call_deferred("smash_block", true)
	pass

func respawn():
	$AnimatedSprite2D.play("default")
	$CollisionShape2D.disabled = false
	$HitboxBottom/CollisionShape2D.disabled = false
	$HitboxTop/CollisionShape2D.disabled = false
	show()
	Global.fade_in(self)
