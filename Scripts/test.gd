extends Node2D


# Called when the node enters the scene tree for the first time.
#func _ready() -> void:


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func _on_world_boundary_body_entered(_body: Node2D) -> void:
	$Player.out_of_bounds()
