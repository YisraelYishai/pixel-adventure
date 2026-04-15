class_name Player
extends CharacterBody2D

'''To-Do:
	Adjust values of particles for better visuals during landing'''

const BASE_SPEED = 175.0
const BASE_ACCELERATION = 750.0
const BASE_FRICTION = 500.0
const BASE_JUMP_VELOCITY = -400.0
const BASE_WALL_JUMP_VELOCITY = 150.0
const BASE_WALL_SLIDE_GRAVITY = 90.0
const SLAM_VELOCITY = 1100.0
const SLAM_PAUSE_TIME = 0.3

@export_category("Player Settings")
@export_enum("1", "2", "3", "4") var player_character: String = "1"

var speed = 200.0
var acceleration = 800.0
var friction = 700.0
var jump_velocity = -400.0
var wall_jump_velocity = 150.0
var wall_slide_gravity = 90.0
var animator_status: bool = true
var can_move: bool = true
var air_jump = 0
var var_jump_applied: bool = false
var released_jump_key: bool = false
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
var current_surface := "default"
var current_wall_surface := "default"
var cached_surface := "default"
var floor_surface := "default"
var ice_momentum := 0.0
var air_control := 1.0
var was_on_floor := false
var is_bouncing: bool = false

@onready var animator = $AnimatedSprite2D
@onready var cam = $Camera2D
@onready var sand_particles_2d: GPUParticles2D = $Particles/SandParticles2D
@onready var mud_particles_2d: GPUParticles2D = $Particles/MudParticles2D
@onready var ice_particles_2d: GPUParticles2D = $Particles/IceParticles2D
@onready var tile_map_layer: TileMapLayer = %TileMapLayer


func _ready() -> void:
	call_deferred("set_physics_process", false)
	self.visible = false
	await get_tree().create_timer(0.3).timeout
	self.position = %InitialSpawnPlayer.position
	appear()
	new_respawn(%InitialSpawnPlayer.position)


func _physics_process(delta: float) -> void:
	# DebugLabel
	$DebugLabel.text = "Health: " + str(health)
	# Slam Cooldown
	if slam_timer > 0:
		slam_timer -= delta

	# Handle Terrains
	var detected_surface = get_surface_type()
	current_wall_surface = get_wall_surface_type()
	current_surface = detected_surface if detected_surface != "default" else current_surface
	apply_surface_effects(current_surface, current_wall_surface)
	update_particles(floor_surface)

	# Add the gravity
	if not is_on_floor() and !slamming:
		velocity += get_gravity() * delta

	# Check Bounce for Trampoline
	if is_on_ceiling() or velocity.y > 0:
		is_bouncing = false

	# Handle jump
	if is_on_floor() and can_move:
		air_jump = 0
		if Input.is_action_just_pressed("jump") and air_jump < 1 and !slamming:
			var_jump_applied = false
			released_jump_key = false
			air_jump += 1
			velocity.y = jump_velocity
	else:
		if !released_jump_key and !Input.is_action_pressed("jump") and !slamming:
			released_jump_key = true

		if released_jump_key and !var_jump_applied and velocity.y < 0.0:
			if not is_bouncing:
				velocity.y *= 0.5
				var_jump_applied = true

		if Input.is_action_just_pressed("jump") and air_jump < 2 and !wall_sliding and animator_status and can_move:
			air_jump += 1
			double_jumping = true
			update_animations()
			velocity.y = jump_velocity + 100

	# Handle Wall Jump
	if Input.is_action_just_pressed("jump") and is_on_wall() and can_move:
		if Input.is_action_pressed("right"):
			velocity.y = jump_velocity
			velocity.x = -wall_jump_velocity
		if Input.is_action_pressed("left"):
			velocity.y = jump_velocity
			velocity.x = wall_jump_velocity
		air_jump += 1

	# Handle Wall Sliding
	var direction := Input.get_axis("left", "right")

	if is_on_wall() and !is_on_floor() and can_move:
		var normal = get_wall_normal()

		if direction != 0 and sign(direction) == -sign(normal.x):
			wall_sliding = true
		else:
			wall_sliding = false
	else:
		wall_sliding = false

	if wall_sliding:
		velocity.y += (wall_slide_gravity * delta)
		velocity.y = min(velocity.y, wall_slide_gravity)

	# Handle Slam
	if Input.is_action_just_pressed("slam"):
		if can_fall_through:
			set_collision_mask_value(2, false)
			await get_tree().create_timer(0.25).timeout
			set_collision_mask_value(2, true)
			can_fall_through = false
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
			cam.screen_shake(3, 1.5)
		elif slam_effect == "double_jump":
			cam.screen_shake(4, 1.5)
		await get_tree().create_timer(0.3).timeout
		slam_effect = "nil"
		box_breakable = false
		cam.offset = Vector2(0, 0)

	# Handle Reload
	if Input.is_action_just_pressed("reload") and is_on_floor():
		await disappear()
		respawn(false)

	# Get the input direction and handle the movement/deceleration.
	if current_surface == "ice" or cached_surface == "ice":
		if direction != 0:
			ice_momentum = move_toward(ice_momentum, direction * speed, acceleration * delta)
		else:
			ice_momentum = move_toward(ice_momentum, 0, friction * 0.2 * delta)

		velocity.x = ice_momentum

	else:
		var target_velocity = direction * speed

		if direction != 0 and !slamming and can_move:
			velocity.x = move_toward(velocity.x, target_velocity, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

		ice_momentum = velocity.x

		air_control = 1.0

		if not is_on_floor():
			if current_surface == "mud":
				air_control = 0.5

		if direction != 0 and !slamming and can_move:
			velocity.x = move_toward(
				velocity.x,
				target_velocity,
				acceleration * air_control * delta,
			)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

	# Handle Flip
	if can_move:
		if direction == 1:
			animator.flip_h = false
		elif direction == -1:
			animator.flip_h = true

	var fall_speed = velocity.y

	move_and_slide()

	if animator_status:
		update_animations()

	# Landing detection and Ice Cancel
	if is_on_wall():
		var wall_normal = get_wall_normal()
		if sign(ice_momentum) == -sign(wall_normal.x):
			ice_momentum *= 0.2

	if not was_on_floor and is_on_floor():
		if fall_speed > 250:
			trigger_landing_particles()

	was_on_floor = is_on_floor()


func appear():
	floor_surface = "default"
	cached_surface = "default"
	current_surface = "default"
	update_particles("default")
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
		double_jumping = false
		if velocity.x == 0:
			animator.play("idle" + player_character)
		else:
			animator.play("run" + player_character)
	elif wall_sliding:
		animator.play("wall_slide" + player_character)
	elif is_hurt:
		animator.play("hit" + player_character)
	else:
		if double_jumping:
			if animator.animation != "double_jump" + player_character:
				animator.play("double_jump" + player_character)
			elif not animator.is_playing():
				double_jumping = false

		# Handle normal jumping / falling
		if not double_jumping:
			if velocity.y < 0:
				animator.play("jump" + player_character)
			else:
				animator.play("fall" + player_character)


func fruit_collected():
	fruits += 1


func apply_bounce(bounce_force: float) -> void:
	velocity.y = bounce_force
	air_jump += 1
	is_bouncing = true
	double_jumping = false


func hit(enemy_position: Vector2):
	$DebugLabel.add_theme_color_override("font_color", Color.RED)

	if is_hurt:
		return

	is_hurt = true
	set_collision_mask_value(4, false)
	health -= 1

	var knockback_dir = (global_position - enemy_position).normalized()
	velocity = knockback_dir * knockback_force
	cam.screen_shake(2, 2)
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


func get_surface_type() -> String:
	floor_surface = "default"

	if not is_on_floor():
		return "default"

	var foot_offset = Vector2(0, 24)
	var position_to_check = global_position + foot_offset

	var local_pos = tile_map_layer.to_local(position_to_check)
	var map_pos = tile_map_layer.local_to_map(local_pos)
	var tile_data: TileData = tile_map_layer.get_cell_tile_data(map_pos)

	if tile_data:
		var my_custom_data = tile_data.get_custom_data("surface_type")
		cached_surface = my_custom_data
		floor_surface = my_custom_data
		return my_custom_data

	return "default"


func get_wall_surface_type() -> String:
	if not is_on_wall():
		return "default"

	var direction := Input.get_axis("left", "right")

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var normal = collision.get_normal()

		if abs(normal.x) > 0.7:
			if direction != 0 and sign(direction) == -sign(normal.x):
				if collision.get_collider() is TileMapLayer:
					var layer = collision.get_collider()
					var hit_point = collision.get_position()
					var point_inside_wall = hit_point - normal * 2.0
					var local_point = layer.to_local(point_inside_wall)
					var tile_pos = layer.local_to_map(local_point)
					var tile_data = layer.get_cell_tile_data(tile_pos)

					if tile_data:
						return tile_data.get_custom_data("surface_type")

	return "default"


func apply_surface_effects(surface: String, wall_surface: String) -> void:
	speed = BASE_SPEED
	acceleration = BASE_ACCELERATION
	friction = BASE_FRICTION
	jump_velocity = BASE_JUMP_VELOCITY
	wall_jump_velocity = BASE_WALL_JUMP_VELOCITY
	wall_slide_gravity = BASE_WALL_SLIDE_GRAVITY

	match surface:
		"sand":
			speed = 90
			acceleration = 350
			friction = 1000
			jump_velocity = -350
		"mud":
			speed = 40
			acceleration = 300
			friction = 1200
			jump_velocity = -260
		"ice":
			speed = 200
			acceleration = 200
			friction = 20
			jump_velocity = -420
		"one_way":
			can_fall_through = true

	match wall_surface:
		"sand":
			wall_jump_velocity = 80
			wall_slide_gravity = 50
		"mud":
			wall_jump_velocity = 60
			wall_slide_gravity = 10
		"ice":
			wall_jump_velocity = 250
			wall_slide_gravity = 150
		"one_way":
			can_fall_through = true


func update_particles(surface: String) -> void:
	var grounded: bool = is_on_floor()
	var moving: bool = grounded and abs(velocity.x) > 20

	if not grounded:
		sand_particles_2d.emitting = false
		mud_particles_2d.emitting = false
		ice_particles_2d.emitting = false
		return

	mud_particles_2d.emitting = surface == "mud" and moving
	ice_particles_2d.emitting = surface == "ice" and abs(velocity.x) > 80

	if surface == "sand" and moving:
		var par = sand_particles_2d.process_material as ParticleProcessMaterial
		par.spread = 50.0
		if randi() % 6 == 0:
			sand_particles_2d.restart()
	else:
		sand_particles_2d.emitting = false

	if surface == "sand" and moving:
		var dir = sign(velocity.x)

		if dir == 0:
			return

		var mat = sand_particles_2d.process_material as ParticleProcessMaterial

		if mat:
			mat.direction = Vector3(-dir, -0.5, 0)


func trigger_landing_particles():
	match current_surface:
		"mud":
			print("mud")
			var p = mud_particles_2d
			var mat = p.process_material as ParticleProcessMaterial

			p.amount = 100
			mat.direction = Vector3(0, -2, 0)
			mat.spread = 120
			p.restart()
			
			p.amount = 3
			mat.direction = Vector3(0, -0.7, 0)
			mat.spread = 100
		"sand":
			print("sand")
			var p = sand_particles_2d
			var mat = p.process_material as ParticleProcessMaterial

			p.amount = 30
			mat.direction = Vector3(0, -1, 0)
			mat.spread = 40
			p.restart()
			
			p.amount = 30
			mat.direction = Vector3(0, -1, 0)
			mat.spread = 40
		"ice":
			print("ice")
			var p = ice_particles_2d
			var mat = p.process_material as ParticleProcessMaterial

			p.amount = 15
			mat.direction = Vector3(0, -1, 0)
			mat.spread = 10
			p.restart()
			
			p.amount = 15
			mat.direction = Vector3(0, -1, 0)
			mat.spread = 10
			
	sand_particles_2d.restart()
	mud_particles_2d.restart()
	ice_particles_2d.restart()
