extends Node

signal respawn_objects

func fade_in(target_node: CanvasItem):
	target_node.modulate.a = 0.0
	var fade_tween = create_tween()
	fade_tween.tween_property(target_node, "modulate:a", 1.0, 0.5)
