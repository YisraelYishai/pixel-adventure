class_name Player
extends CharacterBody2D


const BASE_SPEED = 175.0
const BASE_ACCELERATION = 750.0
const BASE_FRICTION = 500.0
const BASE_JUMP_VELOCITY = -400.0
const BASE_WALL_JUMP_VELOCITY = 150.0
const BASE_WALL_SLIDE_GRAVITY = 90.0
const SLAM_VELOCITY = 1100.0
const SLAM_PAUSE_TIME = 0.3
const LANDING_MIN_SPEED = 250.0
const LANDING_MAX_SPEED = 750.0
const FOOT_OFFSET_Y = 17.0
const RUN_DUST_LIFETIME = 0.15
const LANDING_FX = {
	"default": {
		"color": Color("d9d2c3"), "amount": 8, "lifetime": 0.3,
		"vel": Vector2(35, 85), "gravity": 180.0, "spread": 20.0,
		"up": 0.25, "size": Vector2(2, 4), "damping": 60.0, "spin": 0.0,
	},
	"sand": {
		"color": Color("d8b778"), "amount": 12, "lifetime": 0.6,
		"vel": Vector2(40, 120), "gravity": 420.0, "spread": 40.0,
		"up": 0.6, "size": Vector2(1.5, 3), "damping": 30.0, "spin": 0.0,
	},
	"mud": {
		"color": Color("71a121ff"), "amount": 8, "lifetime": 0.5,
		"vel": Vector2(50, 130), "gravity": 750.0, "spread": 35.0,
		"up": 1.0, "size": Vector2(3, 5), "damping": 10.0, "spin": 0.0,
	},
	"ice": {
		"color": Color("cdf3ff"), "amount": 14, "lifetime": 0.55,
		"vel": Vector2(70, 160), "gravity": 320.0, "spread": 45.0,
		"up": 0.7, "size": Vector2(2, 3.5), "damping": 20.0, "spin": 540.0,
	},
}

@export_category("Player Settings")
@export_enum("Mask Dude", "Ninja Frog", "Pink Man", "Virtual Guy") var player_character_value: String = "Virtual Guy"

var player_character: String
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
var ending: bool = false
var is_hurt = false
var is_dead = false
var invincibility_time: float = 1.5
var is_invincible := false
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
var swing_knockback_multiplier: float = 2
var life_id := 0
var respawn_locked := false
var transitioning := false
var death_tween: Tween

@onready var animator = $AnimatedSprite2D
@onready var cam = $Camera2D
@onready var dust_particles_2d: GPUParticles2D = $Particles/DustParticles2D
@onready var sand_particles_2d: GPUParticles2D = $Particles/SandParticles2D
@onready var mud_particles_2d: GPUParticles2D = $Particles/MudParticles2D
@onready var ice_particles_2d: GPUParticles2D = $Particles/IceParticles2D
@onready var tile_map_layer: TileMapLayer = %TileMapLayer
@onready var transition_fade: CanvasLayer = %TransitionFade
@onready var transition_wipe: Node = %TransitionWipe
@onready var shutter: ColorRect = $"../../CanvasLayer/Shutter"


func _ready() -> void:
	
	shutter.visible = true
	
	set_character()
	
	dust_particles_2d.lifetime = RUN_DUST_LIFETIME
	call_deferred("set_physics_process", false)
	self.visible = false
	await get_tree().create_timer(0.3).timeout
	self.position = %InitialSpawnPlayer.position
	
	var transition_reparent := transition_wipe
	transition_reparent.play(true)
	await transition_reparent.covered
	shutter.visible = false
	
	appear()
	new_respawn(%InitialSpawnPlayer.position)


func _physics_process(delta: float) -> void:
	# Debug
	$DebugLabel.text = "Health: " + str(health)

	# Slam Cooldown
	if slam_timer > 0:
		slam_timer -= delta

	# Handle Terrains
	var detected_surface = get_surface_type()
	current_wall_surface = get_wall_surface_type()
	if is_on_floor():
		current_surface = detected_surface
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
		if Input.is_action_pressed("jump") and air_jump < 1 and !slamming:
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
		if !is_on_floor() and !slamming and !wall_sliding and slam_timer <= 0 and can_move:
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
			cam.impact_shake(7, 0.35)
		elif slam_effect == "double_jump":
			cam.impact_shake(11, 0.35)
		await get_tree().create_timer(0.3).timeout
		slam_effect = "nil"
		box_breakable = false
		cam.offset = Vector2(0, 0)

	# Handle Reload
	if Input.is_action_just_pressed("reload") and is_on_floor() and !respawn_locked and !transitioning:
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
		var fresh_surface = get_surface_type()
		current_surface = fresh_surface

		if fall_speed > LANDING_MIN_SPEED:
			trigger_landing_particles(fall_speed)

	was_on_floor = is_on_floor()

func set_character():
	match player_character_value:
		"Mask Dude":
			player_character = "1"
		"Ninja Frog":
			player_character = "2"
		"Pink Man":
			player_character = "3"
		"Virtual Guy":
			player_character = "4"


func appear():
	transitioning = true
	self.visible = false
	floor_surface = "default"
	cached_surface = "default"
	current_surface = "default"
	update_particles("default")
	call_deferred("set_physics_process", false)

	animator.scale = Vector2(0.3, 0.3)
	animator_status = false
	await get_tree().create_timer(0.75).timeout
	self.visible = true
	self.velocity = Vector2.ZERO
	animator.play("appearing")
	await animator.animation_finished

	animator.scale = Vector2(1.0, 1.0)
	call_deferred("set_physics_process", true)
	animator_status = true
	transitioning = false
	respawn_locked = false


func disappear():
	transitioning = true
	cancel_pending()
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
	if transitioning:
		return
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


func hit(enemy_position: Vector2, enemy_motion: Vector2 = Vector2.ZERO):
	if is_hurt or is_dead or is_invincible or respawn_locked or transitioning:
		return

	var id := life_id
	$DebugLabel.add_theme_color_override("font_color", Color.RED)
	is_hurt = true
	set_collision_mask_value(4, false)
	health -= 1
	var dying = health <= 0

	if not dying:
		invincibility_flash()

	var away = (global_position - enemy_position).normalized()
	var swing_force = Vector2.ZERO
	if enemy_motion.dot(away) > 0.0:
		swing_force = enemy_motion * swing_knockback_multiplier
	var upward_force = Vector2.UP * 120

	set_physics_process(false)
	await get_tree().create_timer(0.15).timeout
	if not is_inside_tree() or id != life_id:
		return
	set_physics_process(true)

	velocity = (away * knockback_force * 0.55) + swing_force + upward_force
	cam.impact_shake(3.5, 0.3)

	if dying:
		is_dead = true
		update_animations()
		await get_tree().create_timer(0.3).timeout
		if not is_inside_tree() or id != life_id:
			return
		death()
		return

	update_animations()
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree() or id != life_id:
		return

	is_hurt = false
	set_collision_mask_value(4, true)
	update_animations()
	$DebugLabel.add_theme_color_override("font_color", Color.WHITE)

func cancel_pending() -> void:
	life_id += 1
	if death_tween and death_tween.is_valid():
		death_tween.kill()

func invincibility_flash() -> void:
	var id := life_id
	is_invincible = true
	var elapsed := 0.0
	while elapsed < invincibility_time and is_invincible and id == life_id:
		animator.modulate.a = 0.3 if animator.modulate.a > 0.9 else 1.0
		await get_tree().create_timer(0.08).timeout
		if not is_inside_tree():
			return
		elapsed += 0.08
	if id != life_id:
		return
	animator.modulate.a = 1.0
	is_invincible = false

func death():
	respawning = true
	is_hurt = false
	animator_status = false
	z_index = 5
	collision_layer = 0
	collision_mask = 0
	can_move = false
	animator.play("idle" + player_character)
	death_tween = create_tween().set_parallel(true)
	death_tween.tween_property(self, "rotation_degrees", 45, 1.5)
	death_tween.finished.connect(respawn)



func out_of_bounds():
	if respawn_locked or transitioning:
		return
	var id := life_id
	await get_tree().create_timer(0.5).timeout
	if id != life_id or respawn_locked:
		return
	respawn(true)



func end():
	if ending:
		return
	ending = true

	var tree := get_tree()
	await disappear()

	if tree == null:
		return
	
	var transition_reparent := transition_wipe
	transition_reparent.play()
	await transition_reparent.covered
	tree.change_scene_to_file("res://Scenes/levels/test2.tscn")


func new_respawn(respawn_position):
	respawn_point = respawn_position
	respawn_point += Vector2(0, -25)


func respawn(health_refill = true):
	if respawn_locked:
		return
	respawn_locked = true
	cancel_pending()

	respawning = true
	is_hurt = false
	is_dead = false
	is_invincible = false
	slamming = false
	slam_effect = "nil"
	box_breakable = false
	double_jumping = false
	wall_sliding = false
	ice_momentum = 0.0
	velocity = Vector2.ZERO
	animator.modulate.a = 1.0
	$DebugLabel.add_theme_color_override("font_color", Color.WHITE)

	if health_refill:
		health = 3

	rotation_degrees = 0
	z_index = 1

	set_collision_layer_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(4, true)

	self.position = respawn_point
	transition_fade.animate()
	appear()

	can_move = true

	await get_tree().create_timer(0.2).timeout
	Global.respawn_objects.emit()
	respawning = false


func get_surface_type() -> String:
	floor_surface = "default"

	if not is_on_floor():
		return "default"

	var foot_offset_y = 24
	var foot_spread = 6

	var points_to_check = [
		global_position + Vector2(0, foot_offset_y),
		global_position + Vector2(-foot_spread, foot_offset_y),
		global_position + Vector2(foot_spread, foot_offset_y),
	]

	var detected_surface = "default"

	for point in points_to_check:
		var local_pos = tile_map_layer.to_local(point)
		var map_pos = tile_map_layer.local_to_map(local_pos)
		var tile_data: TileData = tile_map_layer.get_cell_tile_data(map_pos)

		if tile_data:
			var surface = tile_data.get_custom_data("surface_type")

			if surface == "harmful":
				cached_surface = surface
				floor_surface = surface
				return surface

			if surface != "" and surface != "default":
				detected_surface = surface

	cached_surface = detected_surface
	floor_surface = detected_surface
	return detected_surface


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

func standing_on_tilemap() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().dot(up_direction) > 0.7:
			return c.get_collider() is TileMapLayer
	return false

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
	if get_surface_type() == "harmful":
		var facing_dir = -1 if velocity.x >= 0.0 else 1
		hit(self.global_position + Vector2(10 * facing_dir, 10))

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

	var grounded: bool = is_on_floor() and standing_on_tilemap()
	var moving: bool = grounded and abs(velocity.x) > 20

	if not grounded:
		dust_particles_2d.emitting = false
		sand_particles_2d.emitting = false
		mud_particles_2d.emitting = false
		ice_particles_2d.emitting = false
		return

	dust_particles_2d.emitting = surface == "default" and moving
	mud_particles_2d.emitting = surface == "mud" and moving
	ice_particles_2d.emitting = surface == "ice" and abs(velocity.x) > 80

	if surface == "sand" and moving:
		var par = sand_particles_2d.process_material as ParticleProcessMaterial
		par.spread = 40.0
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
			mat.direction = Vector3(-dir/2, -0.5, 0)


class LandingBurst extends Node2D:
	const SURFACE_FRICTION = 600.0

	var parts: Array = []
	var gravity := 400.0
	var damping := 0.0
	var color := Color.WHITE
	var spin := 0.0

	func setup(cfg: Dictionary, t: float) -> void:
		color = cfg.color
		gravity = cfg.gravity
		damping = cfg.damping
		spin = cfg.spin

		var count := int(lerpf(cfg.amount * 0.5, cfg.amount * 1.5, t)) * 2
		var vel_scale := lerpf(0.7, 1.3, t)
		var base_angle := atan(cfg.up)
		var spread_rad := deg_to_rad(cfg.spread)

		for i in count:
			var side := -1.0 if i % 2 == 0 else 1.0
			var angle := base_angle + randf_range(-spread_rad, spread_rad)
			angle = maxf(angle, 0.05)
			var speed := randf_range(cfg.vel.x, cfg.vel.y) * vel_scale

			if t > 0.4 and i % 5 == 0:
				angle = deg_to_rad(randf_range(70.0, 110.0))
				side = 1.0
				speed *= 0.6

			var life: float = cfg.lifetime * randf_range(0.7, 1.0)
			parts.append({
				"pos": Vector2(randf_range(-6.0, 6.0), -1.0),
				"vel": Vector2(side * cos(angle), -sin(angle)) * speed,
				"age": 0.0,
				"life": life,
				"size": randf_range(cfg.size.x, cfg.size.y * lerpf(0.9, 1.4, t)),
				"rot": randf() * TAU,
				"spin": randf_range(-spin, spin) if spin > 0.0 else 0.0,
			})

	func _process(delta: float) -> void:
		for p in parts:
			p.vel.y += gravity * delta
			p.vel.x = move_toward(p.vel.x, 0.0, damping * delta)
			p.pos += p.vel * delta
			p.rot += deg_to_rad(p.spin) * delta
			p.age += delta

			if p.pos.y >= 0.0:
				p.pos.y = 0.0
				p.vel.y = 0.0
				p.vel.x = move_toward(p.vel.x, 0.0, SURFACE_FRICTION * delta)
				p.spin = 0.0

		parts = parts.filter(func(p): return p.age < p.life)
		if parts.is_empty():
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		for p in parts:
			var k: float = p.age / p.life
			var s: float = p.size * (1.0 - k * 0.7)
			var c := color
			c.a = 1.0 - smoothstep(0.5, 1.0, k)
			draw_set_transform(p.pos, p.rot, Vector2.ONE)
			draw_rect(Rect2(-s * 0.5, -s * 0.5, s, s), c)


func trigger_landing_particles(impact_speed: float = 400.0) -> void:
	if not standing_on_tilemap():
		return
	
	var cfg: Dictionary = LANDING_FX.get(current_surface, LANDING_FX["default"])
	var t := clampf(inverse_lerp(LANDING_MIN_SPEED, LANDING_MAX_SPEED, impact_speed), 0.0, 1.0)

	var burst := LandingBurst.new()
	burst.setup(cfg, t)
	burst.z_as_relative = false
	burst.z_index = z_index + 1

	get_burst_parent().add_child(burst)
	burst.global_position = global_position + Vector2(0, FOOT_OFFSET_Y)


func get_burst_parent() -> Node:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().dot(up_direction) > 0.7:
			var col = c.get_collider()
			if col is TileMapLayer:
				return col.get_parent()
			if col is Node2D:
				return col
	return get_parent()
