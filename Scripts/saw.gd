extends PathFollow2D

@onready var animated_sprite_2d: AnimatedSprite2D = $StaticBody2D/AnimatedSprite2D
@onready var saw: Path2D = $".."

var direction: int = 1

var speed: float = 0.0
var target_speed: float = 0.0

var is_paused: bool = false

var MAX_SPEED
const ACCEL := 4.0

func _ready() -> void:
	MAX_SPEED = saw.max_speed
	
	target_speed = MAX_SPEED
	animated_sprite_2d.play("on")


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
	if is_paused:
		animated_sprite_2d.play("off")
	else:
		animated_sprite_2d.play("on")



func pause_and_reverse() -> void:
	if is_paused:
		return
	
	is_paused = true
	target_speed = 0
	
	await get_tree().create_timer(0.3).timeout
	direction *= -1
	target_speed = MAX_SPEED
	
	is_paused = false


func _on_detector_body_entered(body: Node2D) -> void:
	if body is Player and body.has_method("hit"):
		var pos = self.global_position
		body.hit(pos)
