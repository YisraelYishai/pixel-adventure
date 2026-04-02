extends Node2D

func _ready() -> void:
	get_window().grab_focus()

func _on_world_boundary_body_entered(_body: Node2D) -> void:
	$Player.out_of_bounds()
