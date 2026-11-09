extends Camera2D

var shake_intensity: float = 0.0
var active_shake_time: float = 0.0
var shake_duration: float = 0.0
var shake_decay: float = 8.0
var shake_time: float = 0.0
var shake_time_speed: float = 20.0
var noise: FastNoiseLite = FastNoiseLite.new()
var shake_target: Vector2 = Vector2.ZERO

func _ready() -> void:
	randomize()
	noise.seed = randi()
	noise.frequency = 2.0
	Global.setting_changed.connect(handle_camera_smoothing)


func _physics_process(delta: float) -> void:
	if active_shake_time > 0.0:
		shake_time += delta * shake_time_speed
		active_shake_time = max(active_shake_time - delta, 0.0)

		var progress = active_shake_time / max(shake_duration, 0.0001)
		var amplitude = shake_intensity * progress
		shake_target = Vector2(
			noise.get_noise_2d(shake_time, 0.0),
			noise.get_noise_2d(0.0, shake_time),
		) * amplitude

		offset = offset.slerp(shake_target, 16.0 * delta)
		shake_intensity = max(shake_intensity - shake_decay * delta, 0.0)
	else:
		offset = offset.slerp(Vector2.ZERO, 16.0 * delta)


func screen_shake(intensity: float, time: float, frequency: float = 2.0) -> void:
	if Global.get_setting("screen_shake") == 0 or Global.get_setting("reduced_motion"):
		return
	noise.frequency = frequency
	intensity = intensity * Global.get_setting("screen_shake") / 100.0
	shake_intensity = max(shake_intensity, intensity)
	active_shake_time = max(active_shake_time, time)
	shake_duration = max(shake_duration, time)
	shake_time = 0.0


func gentle_shake(intensity: float = 1.0, time: float = 0.2) -> void:
	screen_shake(intensity * 20, time, 1.2)

func impact_shake(intensity: float = 3.5, time: float = 0.3) -> void:
	screen_shake(intensity * 3.5, time, 2.5)

func handle_camera_smoothing(setting_name, setting_value):
	if setting_name == "reduced_motion":
		if setting_value:
			position_smoothing_speed *= 100
		else:
			position_smoothing_speed /= 100
