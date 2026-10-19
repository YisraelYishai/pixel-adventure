extends Path2D

@export_category("Script Controls")
@export var wait_time: float = 1.0
@export var smash_duration: float = 0.2
@export var return_duration: float = 1.0

@onready var animated_sprite_2d: AnimatedSprite2D = $PathFollow2D/AnimatableBody2D/AnimatedSprite2D
@onready var path_follow_2d: PathFollow2D = $PathFollow2D

var is_dangerous: bool = false
var offsets: Array[float] = []  # distance along the path of each curve point


func _ready() -> void:
	path_follow_2d.loop = false
	path_follow_2d.rotates = false
	_build_offsets()
	path_follow_2d.progress = 0.0
	animated_sprite_2d.play("idle")
	await get_tree().process_frame
	_run()


func _build_offsets() -> void:
	offsets.clear()
	var total := 0.0
	offsets.append(0.0)
	for i in range(1, curve.point_count):
		total += curve.get_point_position(i - 1).distance_to(curve.get_point_position(i))
		offsets.append(total)


func _run() -> void:
	var last := offsets.size() - 1
	while true:
		# forward: stop + smash at every corner
		for i in range(last):
			await _smash(i, i + 1)
		# backward: slow retract, pausing at every corner
		for i in range(last, 0, -1):
			await _retract(i, i - 1)


func _smash(from_i: int, to_i: int) -> void:
	animated_sprite_2d.play("blink")
	await get_tree().create_timer(wait_time).timeout

	is_dangerous = true
	animated_sprite_2d.play("idle")
	var tween := create_tween()
	tween.tween_property(path_follow_2d, "progress", offsets[to_i], smash_duration) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tween.finished

	play_hit_animation(_get_leg_direction(from_i, to_i))
	await get_tree().create_timer(wait_time).timeout
	is_dangerous = false


func _retract(from_i: int, to_i: int) -> void:
	var leg_time := return_duration * (offsets[from_i] - offsets[to_i]) / offsets[-1]
	var tween := create_tween()
	tween.tween_property(path_follow_2d, "progress", offsets[to_i], leg_time) \
		.set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	await get_tree().create_timer(wait_time * 0.5).timeout


func _get_leg_direction(from_i: int, to_i: int) -> Vector2:
	return curve.get_point_position(to_i) - curve.get_point_position(from_i)


func play_hit_animation(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		animated_sprite_2d.play("right_hit" if dir.x > 0 else "left_hit")
	else:
		animated_sprite_2d.play("bottom_hit" if dir.y > 0 else "top_hit")
