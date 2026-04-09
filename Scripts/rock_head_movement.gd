extends PathFollow2D

var wait_time: float = 1.0
var smash_duration: float = 0.2
var return_duration: float = 2.0
var is_dangerous: bool = false

func _ready() -> void:
	loop = false 
	progress_ratio = 0.0
	start_path_smash()

func start_path_smash() -> void:
	var tween = create_tween().set_loops()
	
	tween.tween_interval(wait_time)
	tween.tween_callback(func(): is_dangerous = true)
	
	tween.tween_property(self, "progress_ratio", 1.0, smash_duration) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	
	tween.tween_interval(wait_time)
	tween.tween_callback(func(): is_dangerous = false)
	
	tween.tween_property(self, "progress_ratio", 0.0, return_duration) \
		.set_trans(Tween.TRANS_LINEAR)
