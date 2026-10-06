extends Node

signal covered 
signal finished

var diamond_texture: Texture2D = load("res://Assets/Pixel Adventure 1/Other/Transition.png")
var diamonds_tall := 6.0
var gap := 0.14
var fill_gaps := true
var cover_overlap := 1.15
var grow_time := 0.45
var close_time := 0.25
var stagger := 0.7               
var jitter := 0.05                        
var hold_time := 0.1                        
var canvas_layer := 100

var _tree: SceneTree
var _layer: CanvasLayer
var _root: Node2D
var _diamonds: Array[Sprite2D] = []
var _sep := Vector2.ONE      # scale with gaps
var _cover := Vector2.ONE    # scale that fills the gaps
var _playing := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS    # works while the game is paused
	_layer = CanvasLayer.new()
	_layer.layer = canvas_layer
	add_child(_layer)
	_root = Node2D.new()
	_layer.add_child(_root)
	_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # uncomment for pixel art

func _build(start_covered := false) -> void:
	for d in _diamonds:
		d.queue_free()
	_diamonds.clear()

	var vp := get_viewport().get_visible_rect().size
	var s := vp.y / diamonds_tall                         # lattice cell size in pixels
	var base := Vector2.ONE * (s / diamond_texture.get_height())
	_sep = base * (1.0 - gap)
	_cover = base * cover_overlap

	# Scale the diamonds start at: fully filled, or nothing
	var start_scale := Vector2.ZERO
	if start_covered:
		start_scale = _cover if fill_gaps else _sep

	var row_count := int(ceil(vp.y / (s * 0.5))) + 2
	var col_count := int(ceil(vp.x / s)) + 2
	for r in range(-1, row_count):
		var x_off := posmod(r, 2) * s * 0.5
		for c in range(-1, col_count):
			var pos := Vector2(c * s + x_off, r * s * 0.5)
			var d := Sprite2D.new()
			d.texture = diamond_texture
			d.position = pos
			d.scale = start_scale
			var delay := clampf(pos.x / vp.x, 0.0, 1.0) * stagger + randf() * jitter
			d.set_meta("delay", delay)
			_root.add_child(d)
			_diamonds.append(d)


func _grow() -> void:
	var tw := create_tween().set_parallel(true)
	for d in _diamonds:
		var t: float = d.get_meta("delay")
		tw.tween_property(d, "scale", _sep, grow_time).from(Vector2.ZERO) \
			.set_delay(t).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if fill_gaps:
			tw.tween_property(d, "scale", _cover, close_time).from(_sep) \
				.set_delay(t + grow_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

func _shrink() -> void:
	var tw := create_tween().set_parallel(true)
	var open_time := close_time if fill_gaps else 0.0
	for d in _diamonds:
		var t: float = d.get_meta("delay")
		if fill_gaps:
			tw.tween_property(d, "scale", _sep, close_time).from(_cover) \
				.set_delay(t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(d, "scale", Vector2.ZERO, grow_time).from(_sep) \
			.set_delay(t + open_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tw.finished

func play(start_covered := false) -> void:
	if _playing:
		return
	if diamond_texture == null:
		push_error("Transition: diamond texture not loaded.")
		return
	_playing = true

	_tree = get_tree()
	if get_parent() != _tree.root:
		reparent(_tree.root)    # survive the scene change

	_build(start_covered)

	if not start_covered:
		await _grow()
		covered.emit()
		await _tree.create_timer(hold_time).timeout
	else:
		await _tree.create_timer(hold_time).timeout
		covered.emit()

	await _shrink()

	for d in _diamonds:
		d.queue_free()
	_diamonds.clear()
	_playing = false
	finished.emit()
