extends Node2D

func _ready() -> void:
	get_window().grab_focus()


func _on_world_boundary_body_entered(body: Node2D) -> void:
	if body is Player:
		if body.respawning == false:
			body.out_of_bounds()
