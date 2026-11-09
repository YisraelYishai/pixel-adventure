extends TextureButton
class_name AnimatedButton

var hoverLighten := 0.22
var pressDarken := 0.35

# Matches the settings menu's plum/gold palette
const HOVER_TINT := Color("ffe89e") # warm gold highlight blend
const PRESS_TINT := Color("9b73bd") # plum-violet shadow blend

var hoverScale := Vector2(1.15, 1.15)
var pressScale := Vector2(1.14, 0.84) # wide & flat squash on press
var hoverTiltDegrees := 2.5           # subtle playful tilt on hover

var tween: Tween
static var cache := {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	buildStates()
	updatePivot()
	updatePivot.call_deferred()
	resized.connect(updatePivot)
	item_rect_changed.connect(updatePivot)

	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	focus_entered.connect(_on_hover.bind(true))
	focus_exited.connect(_on_hover.bind(false))
	button_down.connect(_on_press_down)
	button_up.connect(_on_press_up)


func updatePivot() -> void:
	pivot_offset = size / 2.0


func _on_hover(active: bool) -> void:
	if disabled:
		return
	var target_scale := hoverScale if active else Vector2.ONE
	var target_rot := deg_to_rad(hoverTiltDegrees) if active else 0.0
	animate(target_scale, target_rot, 0.14)


func _on_press_down() -> void:
	if disabled:
		return
	# Fast squash down with a slight counter-tilt
	animate(pressScale, deg_to_rad(-hoverTiltDegrees * 0.8), 0.06)


func _on_press_up() -> void:
	if disabled:
		return
	var hovered := is_hovered() or has_focus()
	var rest_scale := hoverScale if hovered else Vector2.ONE
	var rest_rot := deg_to_rad(hoverTiltDegrees) if hovered else 0.0

	if tween:
		tween.kill()
	updatePivot()

	if Global.get_setting("reduced_motion"):
		scale = rest_scale
		rotation = rest_rot
		return

	# Springy stretch rebound before settling
	tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.92, 1.18) * rest_scale, 0.07)
	tween.parallel().tween_property(self, "rotation", rest_rot, 0.12)
	tween.chain().tween_property(self, "scale", rest_scale, 0.12)


func animate(target_scale: Vector2, target_rot: float, time: float) -> void:
	if tween:
		tween.kill()
	updatePivot()
	if Global.get_setting("reduced_motion"):
		scale = target_scale
		rotation = target_rot
		return
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, time)
	tween.tween_property(self, "rotation", target_rot, time)


func buildStates() -> void:
	if texture_normal == null:
		return
	if texture_hover != null and texture_pressed != null:
		return
	var path := texture_normal.resource_path
	var key := str(path, "|", hoverLighten, "|", pressDarken)
	var states: Array = cache.get(key, [])
	if states.is_empty():
		var source := texture_normal.get_image()
		if source == null:
			return
		source = source.duplicate()
		if source.is_compressed():
			source.decompress()
		source.convert(Image.FORMAT_RGBA8)
		states = [
			ImageTexture.create_from_image(tint(source, hoverLighten)),
			ImageTexture.create_from_image(tint(source, -pressDarken)),
		]
		if path != "":
			cache[key] = states
	if texture_hover == null:
		texture_hover = states[0]
	if texture_pressed == null:
		texture_pressed = states[1]


func setIcon(newTexture: Texture2D) -> void:
	texture_normal = newTexture
	texture_hover = null
	texture_pressed = null
	buildStates()


func tint(source: Image, amount: float) -> Image:
	var result: Image = source.duplicate()
	for y in result.get_height():
		for x in result.get_width():
			var pixel := result.get_pixel(x, y)
			if pixel.a == 0.0:
				continue
			# Preserve dark Pixel Adventure outlines so buttons stay crisp
			if pixel.v < 0.22:
				continue
			var shifted: Color
			if amount > 0.0:
				shifted = pixel.lightened(amount).lerp(HOVER_TINT, 0.15)
			else:
				shifted = pixel.darkened(-amount).lerp(PRESS_TINT, 0.28)
			shifted.a = pixel.a
			result.set_pixel(x, y, shifted)
	return result
