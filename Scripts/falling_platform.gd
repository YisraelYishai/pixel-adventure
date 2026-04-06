extends AnimatedSprite2D

var amplitude := 5.0
var frequency := 2.0
var initial_y: float
var has_fallen := false
var fall_tween: Tween
var weight := 0.0
var max_weight := 0.8
var weight_build_speed := 2.0
var player_on_top := false

func _ready() -> void:
	Global.respawn_objects.connect(respawn)
	initial_y = global_position.y

func _process(delta: float) -> void:
	if not has_fallen:
		var time = Time.get_ticks_msec() / 1000.0
		var offset_calculated = sin(time * frequency) * amplitude
		
		global_position.y = initial_y + offset_calculated + weight * 10.0
		
		if player_on_top:
			weight += weight_build_speed * delta
			weight = clamp(weight, 0.0, max_weight)
		else:
			weight = 0.0
		
		if weight >= max_weight:
			start_fall()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.global_position.y < global_position.y:
		player_on_top = true

func _on_area_2d_body_exited(_body: Node2D) -> void:
	player_on_top = false
	weight = 0.0

func start_fall():
	if has_fallen:
		return
	
	has_fallen = true
		
	var shake_tween = create_tween()
	for i in range(6):
		shake_tween.tween_property(self, "offset:x", 2.0, 0.05)
		shake_tween.tween_property(self, "offset:x", -2.0, 0.05)
		
	shake_tween.tween_property(self, "offset:x", 0.0, 0.0) 
		
	await shake_tween.finished
	
	if not has_fallen: return 
		
	self.play("falling")
	await get_tree().create_timer(0.2).timeout
	if not has_fallen: return

	fall_tween = create_tween().set_trans(Tween.TRANS_SINE)
	fall_tween.tween_property(self, "global_position", global_position + Vector2(0, 500), 1.0)
	fall_tween.finished.connect(destroy)

func destroy():
	$StaticBody2D/CollisionShape2D.disabled = true
	hide()
		
func respawn():
	has_fallen = false
	weight = 0.0
	player_on_top = false
	
	if fall_tween and fall_tween.is_valid():
		fall_tween.kill()
		
	global_position.y = initial_y
	offset.x = 0.0
	
	$StaticBody2D/CollisionShape2D.disabled = false
	self.play("default")
	
	show()
