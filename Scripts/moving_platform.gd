extends PathFollow2D

@onready var animated_sprite_2d: AnimatedSprite2D = $StaticBody2D/AnimatedSprite2D
@onready var moving_platform: Path2D = $".."

var mode: String
var direction: int = 1

var speed: float = 0.0
var target_speed: float = 0.0

var is_paused: bool = false

var MAX_SPEED
const ACCEL := 4.0

func _ready() -> void:	
	MAX_SPEED = moving_platform.max_speed
	mode = moving_platform.PlatformType
	
	if mode == "Platform1":
		target_speed = MAX_SPEED
		play_anim("on")
	else:
		target_speed = 0
		speed = 0
		progress = 0
		is_paused = true
		play_anim("off")


func _physics_process(delta: float) -> void:
	speed = lerp(speed, target_speed, ACCEL * delta)

	if abs(speed) < 1:
		speed = 0

	if is_paused:
		return

	progress += direction * speed * delta
	progress_ratio = clamp(progress_ratio, 0.0, 1.0)

	if progress_ratio >= 1.0 or progress_ratio <= 0.0:
		pause_and_reverse()

	update_animation()


func update_animation() -> void:
	if speed == 0:
		play_anim("off")
	else:
		play_anim("on")


func play_anim(state: String) -> void:
	var anim = str(mode) + "_" + state
	
	if state == "on":
		animated_sprite_2d.play(anim, direction)
	else:
		animated_sprite_2d.play(anim)


func pause_and_reverse() -> void:
	if is_paused:
		return
	
	is_paused = true
	target_speed = 0
	
	await get_tree().create_timer(0.3).timeout
	direction *= -1
	target_speed = MAX_SPEED
	
	is_paused = false

var player_on_platform := false

func _on_detector_body_entered(body: Node2D) -> void:
	if body is Player and mode == "Platform2":
		is_paused = false
		body.can_fall_through = true
		player_on_platform = true
		target_speed = MAX_SPEED


func _on_detector_body_exited(body: Node2D) -> void:
	if body is Player and mode == "Platform2":
		player_on_platform = false
		body.can_fall_through = true
		
		await get_tree().create_timer(0.1).timeout
		
		if not player_on_platform:
			target_speed = 0
