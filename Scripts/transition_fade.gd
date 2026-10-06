extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

var color_rect_tween: Tween

func animate() -> void:
	if color_rect_tween:
		color_rect_tween.kill()
		
	get_tree().paused = true
	
	color_rect_tween = create_tween().set_trans(Tween.TRANS_SINE)
	color_rect_tween.tween_property(color_rect, "modulate:a", 1.0, 0.2).connect("finished", finish)
	color_rect_tween.chain().tween_property(color_rect, "modulate:a", 0.0, 0.4)

func finish() -> void:
	get_tree().paused = false
