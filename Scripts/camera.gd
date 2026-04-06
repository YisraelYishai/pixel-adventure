extends Camera2D

var shake_fade: float = 5.0
var rng = RandomNumberGenerator.new()
var shake_strength: float = 0.0


func _ready():
	rng.randomize()


func _process(delta):
	# Gradually decrease shake strength
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_fade * delta)
		# Apply camera shake
		offset = random_offset()


func apply_shake(strength):
	# Call this function when the slam occurs
	shake_strength = strength


func random_offset() -> Vector2:
	return Vector2(
		rng.randf_range(-shake_strength, shake_strength),
		rng.randf_range(-shake_strength, shake_strength),
	)
