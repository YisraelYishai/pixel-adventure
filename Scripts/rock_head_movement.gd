extends Path2D

enum Direction {
	DOWN,
	UP,
	LEFT,
	RIGHT,
}

@export var direction: Direction = Direction.DOWN
@onready var animated_sprite_2d: AnimatedSprite2D = $PathFollow2D/AnimatableBody2D/AnimatedSprite2D
@onready var path_follow_2d: PathFollow2D = $PathFollow2D

var wait_time: float = 1.0
var smash_duration: float = 0.2
var return_duration: float = 2.0
var is_dangerous: bool = false


func _ready() -> void:
	path_follow_2d.loop = false
	path_follow_2d.rotates = false
	path_follow_2d.progress_ratio = get_return_progress()
	animated_sprite_2d.play("idle")
	await get_tree().process_frame
	start_path_smash()

func start_path_smash() -> void:
	var tween = create_tween().set_loops()

	tween.tween_callback(func(): animated_sprite_2d.play("blink"))
	tween.tween_interval(wait_time)
	tween.tween_callback(func(): is_dangerous = true)

	tween.tween_callback(func(): animated_sprite_2d.play("idle"))
	tween.tween_property(path_follow_2d, "progress_ratio", get_target_progress(), smash_duration) \
	.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	tween.tween_callback(func(): play_hit_animation())
	tween.tween_interval(wait_time)
	tween.tween_callback(func(): is_dangerous = false)

	tween.tween_property(path_follow_2d, "progress_ratio", get_return_progress(), return_duration) \
	.set_trans(Tween.TRANS_LINEAR)


func play_hit_animation():
	match direction:
		Direction.DOWN:
			animated_sprite_2d.play("bottom_hit")
		Direction.UP:
			animated_sprite_2d.play("top_hit")
		Direction.LEFT:
			animated_sprite_2d.play("left_hit")
		Direction.RIGHT:
			animated_sprite_2d.play("right_hit")


func get_target_progress() -> float:
	match direction:
		Direction.DOWN, Direction.RIGHT:
			return 1.0
		Direction.UP, Direction.LEFT:
			return 0.0

	return 1.0


func get_return_progress() -> float:
	match direction:
		Direction.DOWN, Direction.RIGHT:
			return 0.0
		Direction.UP, Direction.LEFT:
			return 1.0

	return 0.0
