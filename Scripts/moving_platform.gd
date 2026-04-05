extends PathFollow2D

@onready var animated_sprite_2d: AnimatedSprite2D = $StaticBody2D/AnimatedSprite2D
@onready var moving_platform: Path2D = $".."
var mode
var active
var direction = 1
var is_paused = false

func _ready() -> void:
	mode = moving_platform.PlatformType
	if mode == "Platform1":
		animated_sprite_2d.play(str(mode) + "_on")
	else:
		active = false
		animated_sprite_2d.play(str(mode) + "_off")

func _physics_process(_delta: float) -> void:
	if is_paused or active == false:
		return
	move()

func move():
	progress += direction
	
	if progress_ratio >= 1 or progress_ratio <= 0:
		pause_and_reverse()

func pause_and_reverse() -> void:
	is_paused = true
	animated_sprite_2d.play(str(mode) + "_off")
	await get_tree().create_timer(0.5).timeout
	direction = -direction
	is_paused = false
	if direction == 1:
		animated_sprite_2d.play(str(mode) + "_on", 1.0)
	else:
		animated_sprite_2d.play(str(mode) + "_on", -1.0)

func wait_until_start():
	while progress_ratio > 0:
		await get_tree().physics_frame

func _on_detector_body_entered(body: Node2D) -> void:
	if body is Player and mode == "Platform2":
		if direction == 1:
			animated_sprite_2d.play(str(mode) + "_on", 1.0)
		else:
			animated_sprite_2d.play(str(mode) + "_on", -1.0)
		active = true

func _on_detector_body_exited(body: Node2D) -> void:
	if body is Player and mode == "Platform2":
		await pause_and_reverse()
		await wait_until_start()
		active = false
		animated_sprite_2d.play(str(mode) + "_off")
