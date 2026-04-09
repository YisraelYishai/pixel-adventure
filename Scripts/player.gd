class_name Player
extends CharacterBody2D

'''To-Do: 
	NIL'''

const SPEED = 200.0
const ACCELERATION = 800.0
const FRICTION = 700.0
const JUMP_VELOCITY = -400.0
const WALL_JUMP_VELOCITY = 150.0
const WALL_SLIDE_GRAVITY = 90.0
const SLAM_VELOCITY = 1100.0
const SLAM_PAUSE_TIME = 0.3

@export_category("Player Settings")
@export_enum("1", "2", "3", "4") var player_character: String = "1"

var animator_status: bool = true
var can_move: bool = true
var air_jump = 0
var double_jumping = false
var wall_sliding = false
var slamming = false
var slam_effect = "nil"
var slam_timer = 0.0
var box_breakable = false
var respawn_point: Vector2
var fruits = 0
var health = 3
var respawning: bool
var is_hurt = false
var knockback_force = 500
var can_fall_through = false

@onready var animator = $AnimatedSprite2D
@onready var cam = $Camera2D


func _ready() -> void:
	self.visible = false
	await get_tree().create_timer(0.3).timeout
	self.position = $"../InitialSpawnPlayer".position
	appear()
	new_respawn($"../InitialSpawnPlayer".position)


func _physics_process(delta: float) -> void:
	# DebugLabel
	$DebugLabel.text = "Health: " + str(health)

	# Slam Cooldown
	if slam_timer > 0:
		slam_timer -= delta

	# Add the gravity.
	if not is_on_floor() and !slamming:
		velocity += get_gravity() * delta

	# Handle jump
	if is_on_floor() and can_move:
		air_jump = 0
		if Input.is_action_pressed("jump") and air_jump < 1 and !slamming:
			air_jump += 1
			velocity.y = JUMP_VELOCITY
	else:
		if Input.is_action_just_pressed("jump") and air_jump < 2 and !wall_sliding and animator_status and can_move:
			air_jump += 1
			double_jumping = true
			update_animations()
			velocity.y = JUMP_VELOCITY + 100

	# Handle Wall Jump
	if Input.is_action_just_pressed("jump") and is_on_wall() and can_move:
		if Input.is_action_pressed("right"):
			velocity.y = JUMP_VELOCITY
			velocity.x = -WALL_JUMP_VELOCITY
		if Input.is_action_pressed("left"):
			velocity.y = JUMP_VELOCITY
			velocity.x = WALL_JUMP_VELOCITY
		air_jump += 1

	# Handle Wall Sliding
	if is_on_wall() and !is_on_floor() and can_move:
		if Input.is_action_pressed("right") or Input.is_action_pressed("left"):
			wall_sliding = true
		else:
			wall_sliding = false
	else:
		wall_sliding = false

	if wall_sliding:
		velocity.y += (WALL_SLIDE_GRAVITY * delta)
		velocity.y = min(velocity.y, WALL_SLIDE_GRAVITY)

	# Handle Slam
	if Input.is_action_just_pressed("slam"):
		if can_fall_through:
			set_collision_mask_value(2, false)
			await get_tree().create_timer(0.25).timeout
			set_collision_mask_value(2, true)
			return
		if !is_on_floor() and !slamming and slam_timer <= 0 and can_move:
			slamming = true
			box_breakable = true
			if air_jump == 1:
				slam_effect = "jump"
			else:
				slam_effect = "double_jump"
				velocity = Vector2.ZERO
				animator.play("double_jump" + player_character)
				animator_status = false
				await get_tree().create_timer(SLAM_PAUSE_TIME).timeout
				animator_status = true
			velocity.y = SLAM_VELOCITY

	if slamming and is_on_floor():
		slamming = false
		slam_timer = 0.6

		if slam_effect == "jump":
			cam.apply_shake(3)
		elif slam_effect == "double_jump":
			cam.apply_shake(7)
		await get_tree().create_timer(0.3).timeout
		slam_effect = "nil"
		box_breakable = false
		cam.offset = Vector2(0, 0)

	# Handle Reload
	if Input.is_action_just_pressed("reload") and is_on_floor():
		await disappear()
		respawn(false)

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("left", "right")
	var target_velocity = direction * SPEED

	if direction != 0 and !slamming and can_move:
		velocity.x = move_toward(velocity.x, target_velocity, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# Handle Flip
	if can_move:
		if direction == 1:
			animator.flip_h = false
		elif direction == -1:
			animator.flip_h = true

	move_and_slide()

	if animator_status:
		update_animations()


func appear():
	call_deferred("set_physics_process", false)
	animator.scale = Vector2(0.3, 0.3)
	animator_status = false
	self.visible = true
	self.velocity = Vector2.ZERO
	animator.play("appearing")
	await animator.animation_finished
	animator.scale = Vector2(1.0, 1.0)
	animator.play("idle" + player_character)
	call_deferred("set_physics_process", true)
	animator_status = true


func disappear():
	call_deferred("set_physics_process", false)
	self.visible = false
	animator.scale = Vector2(0.3, 0.3)
	animator_status = false
	self.visible = true
	animator.play("disappearing")
	await animator.animation_finished
	animator.scale = Vector2(1.0, 1.0)
	self.visible = false


func update_animations():
	# Handle Animations
	if is_on_floor() and !is_hurt:
		if velocity.x == 0:
			animator.animation = "idle" + player_character
		else:
			animator.animation = "run" + player_character
	elif wall_sliding:
		animator.play("wall_slide" + player_character)
	elif is_hurt:
		animator.play("hit" + player_character)
	else:
		if velocity.y < 0:
			animator.animation = "jump" + player_character
		elif air_jump == 2 and double_jumping:
			animator.play("double_jump" + player_character)
			await animator.animation_finished
			double_jumping = false
			animator.play("fall" + player_character)
		elif velocity.y > 10 or slamming:
			animator.animation = "fall" + player_character
		pass


func fruit_collected():
	fruits += 1


func hit(enemy_position: Vector2):
	$DebugLabel.add_theme_color_override("font_color", Color.RED)

	if is_hurt:
		return

	is_hurt = true
	set_collision_mask_value(4, false)
	health -= 1

	var knockback_dir = (global_position - enemy_position).normalized()
	velocity = knockback_dir * knockback_force
	cam.apply_shake(2)
	update_animations()

	await get_tree().create_timer(0.2).timeout
	
	is_hurt = false
	
	set_collision_mask_value(4, true)
	update_animations()

	$DebugLabel.add_theme_color_override("font_color", Color.WHITE)

	if health <= 0:
		death()


func death():
	respawning = true
	z_index = 5
	collision_layer = 0
	collision_mask = 0
	can_move = false
	animator.play("idle" + player_character)
	animator_status = false
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "rotation_degrees", 45, 1.5)
	tween.finished.connect(respawn)


func out_of_bounds():
	await get_tree().create_timer(0.5).timeout
	respawn(true)


func end():
	await disappear()
	get_tree().reload_current_scene()
	# Change it to next scene


func new_respawn(respawn_position):
	respawn_point = respawn_position


func respawn(health_refill = true):
	respawning = true
	if health_refill:
		health = 3
	rotation_degrees = 0
	z_index = 1
	set_collision_layer_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(4, true)
	self.position = respawn_point
	appear()
	can_move = true
	await get_tree().create_timer(0.2).timeout
	Global.respawn_objects.emit()
	respawning = false
