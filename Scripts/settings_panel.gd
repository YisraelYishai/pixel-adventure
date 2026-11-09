extends Control
signal closed

var font: Font
var font_size: int = 13
var back_texture: Texture2D

const BACK_ICON_PATH := "res://Assets/Pixel Adventure 1/Menu/Buttons/Back.png"
const CLICK_SOUND_PATH := "res://Assets/SFX and Audio/click.wav"

const PANEL_SIZE := Vector2(448, 312)
const ROW_HEIGHT := 28
const ROW_GAP := 8
const TAB_GAP := 8
const TAB_CONTENT_GAP := 8
const CONTROL_WIDTH := 200
const HEADING_EXTRA := 3
const BACK_SCALE := 1.5
const HOVER_SCALE := 1.06
const CHOOSER_SLIDE := 9.0
const CHOOSER_TEXT_OFFSET := -7.0

const TOGGLE_SIZE := Vector2(38, 22)
const KNOB_Y := 2.0
const KNOB_OFF_X := 3.0
const KNOB_ON_X := 19.0

const C_WHITE := Color("ffffff")
const C_OUTLINE := Color(0.0, 0.0, 0.0, 0.8)        # new: used for every outline
const C_INK := Color("0e2a52")            # text on light faces, label shadow
const C_PANEL := Color("2a72c4")
const C_PANEL_EDGE := Color("1a4f94")
const C_PAGE_BG := Color("215fae")
const C_PAGE_EDGE := Color("154683")
const C_TAB := Color("1f5fb0")
const C_TAB_EDGE := Color("154683")
const C_TAB_HOVER := Color("2872c8")
const C_FACE := Color("bfe0ff")
const C_FACE_HOVER := Color("e6f3ff")
const C_FACE_DOWN := Color("9ccbf5")
const C_FACE_EDGE := Color("6fa6dd")
const C_DISABLED := Color("5f87b3")
const C_DISABLED_EDGE := Color("4c6f96")
const C_DISABLED_TEXT := Color("a9c2dd")
const C_SWITCH_OFF := Color("5a7fae")
const C_SWITCH_OFF_HOVER := Color("6c92c4")
const C_SWITCH_OFF_EDGE := Color("456590")
const C_ACCENT := Color("58d05a")
const C_ACCENT_HOVER := Color("86e374")
const C_ACCENT_EDGE := Color("3d9f3b")
const C_GOLD := Color("f9eae5")
const C_GREEN := Color("58d05a")          # same as the accent; delete it if nothing uses it
const C_TRACK := Color("10305f")
const DIM_COLOR := Color(0.03, 0.10, 0.22, 0.65)
const DISABLED_TINT := Color(0.75, 0.8, 0.9)

const SHAPE_BUTTON := {"size": Vector2i(16, 16), "cut": 2, "width": 1, "margin": 5}
const SHAPE_PANEL := {"size": Vector2i(24, 24), "cut": 3, "width": 2, "margin": 9}
const SHAPE_TRACK := {"size": Vector2i(16, 16), "cut": 2, "width": 1, "margin": 5}
const SHAPE_KNOB := {"size": Vector2i(16, 16), "cut": 2, "width": 1}
const SHAPE_GRABBER := {"size": Vector2i(12, 16), "cut": 2, "width": 1}

const SETTINGS_UI: Dictionary = {
	"window_mode": {"tab": "Display", "label": "Window mode", "options": ["Windowed", "Fullscreen", "Exclusive", "Maximized"]},
	"window_size": {"tab": "Display", "label": "Window size", "options": ["1x", "2x", "3x", "4x"], "enabled_if": {"key": "window_mode", "equals": 0}},
	"vsync_mode": {"tab": "Display", "label": "V-Sync", "options": ["Off", "On", "Adaptive"]},
	"fps_limit": {"tab": "Display", "label": "FPS limit", "options": ["30", "60", "120", "144", "Unlimited"]},
	"master_volume": {"tab": "Audio", "label": "Master"},
	"music_volume": {"tab": "Audio", "label": "Music"},
	"sfx_volume": {"tab": "Audio", "label": "Effects"},
	"mute_all": {"tab": "Audio", "label": "Mute all"},
	"mute_unfocused": {"tab": "Audio", "label": "Mute when unfocused"},
	"reduced_motion": {"tab": "Game", "label": "Reduced motion"},
	"screen_shake": {"tab": "Game", "label": "Screen shake", "enabled_if": {"key": "reduced_motion", "equals": false}},
}

var panel: PanelContainer
var tabs: TabContainer
var tab_indicator: Panel
var tab_tween: Tween
var page_tween: Tween
var pop_tween: Tween
var back_button: BaseButton
var reset_button: Button
var dim_overlay: ColorRect
var click_player: AudioStreamPlayer
var knob_texture: ImageTexture
var left_arrow_texture: ImageTexture
var right_arrow_texture: ImageTexture
var rows := {}
var refreshers := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = build_theme()
	knob_texture = make_knob_texture()
	left_arrow_texture = make_arrow_texture(-1)
	right_arrow_texture = make_arrow_texture(1)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	build_frame()
	build_rows()
	setup_tab_indicator()
	Global.setting_changed.connect(on_setting_changed)

# ---------- opening and closing ----------

func open() -> void:
	refresh()
	visible = true
	if pop_tween:
		pop_tween.kill()
	back_button.grab_focus()

	panel.scale = Vector2.ONE
	panel.rotation = 0.0
	panel.modulate.a = 1.0
	if Global.get_setting("reduced_motion"):
		dim_overlay.modulate.a = 1.0
	else:
		panel.scale = Vector2(0.78, 0.78)
		panel.rotation = deg_to_rad(-1.5)
		panel.modulate.a = 0.0
		dim_overlay.modulate.a = 0.0
		pop_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_tween.tween_property(panel, "scale", Vector2.ONE, 0.26)
		pop_tween.tween_property(panel, "rotation", 0.0, 0.24)
		pop_tween.tween_property(panel, "modulate:a", 1.0, 0.16)
		pop_tween.tween_property(dim_overlay, "modulate:a", 1.0, 0.18)

	# the tab indicator needs the layout to settle first
	await get_tree().process_frame
	await get_tree().process_frame
	update_tab_indicator(false)

func close() -> void:
	if not visible:
		return
	if pop_tween:
		pop_tween.kill()
	if Global.get_setting("reduced_motion"):
		finish_close()
		return
	pop_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	pop_tween.tween_property(panel, "scale", Vector2(0.84, 0.84), 0.13)
	pop_tween.tween_property(panel, "rotation", deg_to_rad(1.2), 0.13)
	pop_tween.tween_property(panel, "modulate:a", 0.0, 0.10)
	pop_tween.tween_property(dim_overlay, "modulate:a", 0.0, 0.12)
	pop_tween.chain().tween_callback(finish_close)

func finish_close() -> void:
	visible = false
	panel.scale = Vector2.ONE
	panel.rotation = 0.0
	panel.modulate.a = 1.0
	dim_overlay.modulate.a = 1.0
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

# ---------- juice helpers ----------

func play_click(pitch: float = 1.0) -> void:
	if click_player == null or click_player.stream == null:
		return
	click_player.pitch_scale = pitch * randf_range(0.97, 1.03)
	click_player.play()

func add_hover_pop(control: Control) -> void:
	control.resized.connect(func() -> void: control.pivot_offset = control.size / 2.0)
	control.mouse_entered.connect(scale_to.bind(control, Vector2.ONE * HOVER_SCALE))
	control.mouse_exited.connect(scale_to.bind(control, Vector2.ONE))
	if control is BaseButton:
		control.button_down.connect(func() -> void:
			if not control.disabled:
				scale_to(control, Vector2(1.09, 0.90), 0.06))
		control.button_up.connect(func() -> void:
			var rest := Vector2.ONE * (HOVER_SCALE if control.is_hovered() else 1.0)
			scale_to(control, rest, 0.14))

func scale_to(control: Control, target: Vector2, duration: float = 0.12) -> void:
	kill_meta_tween(control, "scale_tween")
	if Global.get_setting("reduced_motion"):
		control.scale = Vector2.ONE
		return
	control.pivot_offset = control.size / 2.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", target, duration)
	control.set_meta("scale_tween", tween)

# Subtle row highlight and nudge when hovering a setting row.
func add_row_juice(row: Control, label: Label) -> void:
	row.mouse_entered.connect(func() -> void:
		if row.modulate == DISABLED_TINT:
			return
		label.add_theme_color_override("font_color", C_GOLD)
		if not Global.get_setting("reduced_motion"):
			kill_meta_tween(label, "row_tween")
			var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			t.tween_property(label, "position:x", 3.0, 0.12)
			label.set_meta("row_tween", t))
	row.mouse_exited.connect(func() -> void:
		label.remove_theme_color_override("font_color")
		if not Global.get_setting("reduced_motion"):
			kill_meta_tween(label, "row_tween")
			var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			t.tween_property(label, "position:x", 0.0, 0.14)
			label.set_meta("row_tween", t))

# A quick bigger-then-back pulse, used by the reset button.
func pulse(button: BaseButton) -> void:
	if Global.get_setting("reduced_motion"):
		return
	kill_meta_tween(button, "scale_tween")
	button.pivot_offset = button.size / 2.0
	var rest := HOVER_SCALE if button.is_hovered() else 1.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.16, 0.88), 0.06)
	tween.tween_property(button, "scale", Vector2(0.95, 1.08), 0.08)
	tween.tween_property(button, "scale", Vector2.ONE * rest, 0.12)
	button.set_meta("scale_tween", tween)

# The little bounce of a slider's number when it changes.
func pop_label(label: Label) -> void:
	if Global.get_setting("reduced_motion"):
		return
	kill_meta_tween(label, "pop_tween")
	label.pivot_offset = label.size / 2.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.18, 1.18), 0.05)
	tween.tween_property(label, "scale", Vector2.ONE, 0.11)
	label.set_meta("pop_tween", tween)

# Slides the old text out and the new text in. direction: 1 = next, -1 = previous.
func slide_label(label: Label, new_text: String, direction: int) -> void:
	kill_meta_tween(label, "slide_tween")
	label.position.x = 0.0
	label.modulate.a = 1.0
	if label.text == "" or not is_visible_in_tree() or Global.get_setting("reduced_motion"):
		label.text = new_text
		return
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:x", -direction * CHOOSER_SLIDE, 0.08)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.08)
	tween.tween_callback(func() -> void:
		label.text = new_text
		label.position.x = direction * CHOOSER_SLIDE)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "position:x", 0.0, 0.15)
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.12)
	label.set_meta("slide_tween", tween)

func kill_meta_tween(node: Node, meta_name: String) -> void:
	if node.has_meta(meta_name):
		var old: Tween = node.get_meta(meta_name)
		if old:
			old.kill()

# ---------- the sliding tab indicator ----------

func half_gap() -> int:
	return int(TAB_GAP / 2.0)

func tab_padding() -> Vector2i:
	return Vector2i(8 + half_gap(), 2)

func setup_tab_indicator() -> void:
	var tab_bar: TabBar = tabs.get_tab_bar()
	tab_indicator = Panel.new()
	tab_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab_indicator.show_behind_parent = true
	tab_indicator.add_theme_stylebox_override("panel",
		make_box_style(SHAPE_BUTTON, C_FACE_HOVER, C_FACE_EDGE, C_OUTLINE, 2, 0, tab_padding(), half_gap()))
	tab_bar.add_child(tab_indicator)
	tab_bar.resized.connect(snap_tab_indicator)
	tabs.sort_children.connect(snap_tab_indicator.call_deferred)

# Layout passes call this. It must not interrupt the slide animation.
func snap_tab_indicator() -> void:
	if tab_tween and tab_tween.is_running():
		return
	update_tab_indicator(false)

func update_tab_indicator(animate: bool = true) -> void:
	if not is_instance_valid(tab_indicator):
		return
	var tab_bar: TabBar = tabs.get_tab_bar()
	var index: int = tabs.current_tab
	if index < 0 or index >= tab_bar.tab_count:
		return
	var rect: Rect2 = tab_bar.get_tab_rect(index)
	if rect.size == Vector2.ZERO:
		return
	if tab_tween:
		tab_tween.kill()
	if not animate or not is_visible_in_tree() or Global.get_setting("reduced_motion"):
		tab_indicator.position = rect.position
		tab_indicator.size = rect.size
		return
	tab_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tab_tween.tween_property(tab_indicator, "position", rect.position, 0.18)
	tab_tween.tween_property(tab_indicator, "size", rect.size, 0.18)

func on_tab_changed(_tab: int) -> void:
	# While the panel is hidden (including while it is being built) there is nothing to show or play.
	if not is_visible_in_tree():
		return
	play_click(1.1)
	update_tab_indicator(true)
	var page: Control = tabs.get_current_tab_control()
	if page == null or Global.get_setting("reduced_motion"):
		return
	if page_tween:
		page_tween.kill()
	page.modulate.a = 0.0
	page.pivot_offset = page.size / 2.0
	page.scale = Vector2(0.97, 0.97)
	page_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	page_tween.tween_property(page, "modulate:a", 1.0, 0.15)
	page_tween.tween_property(page, "scale", Vector2.ONE, 0.15)

# ---------- the look: a Theme built in code ----------

func build_theme() -> Theme:
	var t := Theme.new()
	if font:
		t.default_font = font
	if font_size > 0:
		t.default_font_size = font_size

	t.set_constant("separation", "VBoxContainer", ROW_GAP)
	t.set_constant("separation", "HBoxContainer", 6)

	# labels and the heading
	t.set_color("font_color", "Label", C_WHITE)
	t.set_color("font_shadow_color", "Label", C_OUTLINE)
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	t.set_type_variation("HeadingLabel", "Label")
	t.set_color("font_color", "HeadingLabel", C_GOLD)
	t.set_color("font_shadow_color", "HeadingLabel", C_OUTLINE)
	var base_size: int = font_size if font_size > 0 else ThemeDB.fallback_font_size
	t.set_font_size("font_size", "HeadingLabel", base_size + HEADING_EXTRA)

	# the main panel and the box around each tab's rows
	t.set_stylebox("panel", "PanelContainer",
		make_box_style(SHAPE_PANEL, C_PANEL, C_PANEL_EDGE, C_OUTLINE, 4, 0, Vector2i(10, 8)))
	t.set_type_variation("TabPagePanel", "PanelContainer")
	t.set_stylebox("panel", "TabPagePanel",
		make_box_style(SHAPE_PANEL, C_PAGE_BG, C_PAGE_EDGE, C_OUTLINE, 3, 0, Vector2i(10, 8)))

	# buttons
	var pressed := make_box_style(SHAPE_BUTTON, C_FACE_DOWN, C_FACE_EDGE, C_OUTLINE, 1, 2)
	t.set_stylebox("normal", "Button", make_box_style(SHAPE_BUTTON, C_FACE, C_FACE_EDGE, C_OUTLINE, 3))
	t.set_stylebox("hover", "Button", make_box_style(SHAPE_BUTTON, C_FACE_HOVER, C_FACE_EDGE, C_OUTLINE, 3))
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("hover_pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", make_box_style(SHAPE_BUTTON, C_DISABLED, C_DISABLED_EDGE, C_OUTLINE, 3))
	t.set_stylebox("focus", "Button", make_focus_style())
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(color_name, "Button", C_INK)
	t.set_color("font_disabled_color", "Button", C_DISABLED_TEXT)

	# toggle switch track (the knob is a child that slides)
	t.set_type_variation("ToggleSwitch", "Button")
	var no_pad := Vector2i(0, 0)
	t.set_stylebox("normal", "ToggleSwitch", make_box_style(SHAPE_TRACK, C_SWITCH_OFF, C_SWITCH_OFF_EDGE, C_OUTLINE, 2, 0, no_pad))
	t.set_stylebox("hover", "ToggleSwitch", make_box_style(SHAPE_TRACK, C_SWITCH_OFF_HOVER, C_SWITCH_OFF_EDGE, C_OUTLINE, 2, 0, no_pad))
	t.set_stylebox("pressed", "ToggleSwitch", make_box_style(SHAPE_TRACK, C_ACCENT, C_ACCENT_EDGE, C_OUTLINE, 2, 0, no_pad))
	t.set_stylebox("hover_pressed", "ToggleSwitch", make_box_style(SHAPE_TRACK, C_ACCENT_HOVER, C_ACCENT_EDGE, C_OUTLINE, 2, 0, no_pad))
	t.set_stylebox("disabled", "ToggleSwitch", make_box_style(SHAPE_TRACK, C_DISABLED, C_DISABLED_EDGE, C_OUTLINE, 2, 0, no_pad))

	# tabs: the selected tab is drawn by the sliding indicator, so its own style is empty
	var tab_pad := tab_padding()
	var width: int = SHAPE_BUTTON["width"]
	var selected_empty := StyleBoxEmpty.new()
	selected_empty.content_margin_left = width + tab_pad.x
	selected_empty.content_margin_right = width + tab_pad.x
	selected_empty.content_margin_top = width + tab_pad.y
	selected_empty.content_margin_bottom = width + tab_pad.y + 2
	t.set_stylebox("tab_selected", "TabContainer", selected_empty)
	t.set_stylebox("tab_unselected", "TabContainer", make_box_style(SHAPE_BUTTON, C_TAB, C_TAB_EDGE, C_OUTLINE, 2, 0, tab_pad, half_gap()))
	t.set_stylebox("tab_hovered", "TabContainer", make_box_style(SHAPE_BUTTON, C_TAB_HOVER, C_TAB_EDGE, C_OUTLINE, 2, 0, tab_pad, half_gap()))
	t.set_stylebox("tab_disabled", "TabContainer", make_box_style(SHAPE_BUTTON, C_DISABLED, C_DISABLED_EDGE, C_OUTLINE, 2, 0, tab_pad, half_gap()))
	t.set_stylebox("tab_focus", "TabContainer", make_focus_style(half_gap()))
	var tab_panel := StyleBoxEmpty.new()
	tab_panel.content_margin_top = TAB_CONTENT_GAP
	t.set_stylebox("panel", "TabContainer", tab_panel)
	t.set_color("font_selected_color", "TabContainer", C_INK)
	t.set_color("font_unselected_color", "TabContainer", C_WHITE)
	t.set_color("font_hovered_color", "TabContainer", C_WHITE)
	t.set_color("font_disabled_color", "TabContainer", C_DISABLED_TEXT)

	# sliders (blue-violet fill with plum-lilac grabber)
	t.set_stylebox("slider", "HSlider", make_track_style(C_TRACK))
	t.set_stylebox("grabber_area", "HSlider", make_track_style(C_ACCENT))
	t.set_stylebox("grabber_area_highlight", "HSlider", make_track_style(C_ACCENT_HOVER))
	t.set_stylebox("focus", "HSlider", make_focus_style())
	t.set_icon("grabber", "HSlider", make_grabber(C_FACE, C_FACE_EDGE))
	t.set_icon("grabber_highlight", "HSlider", make_grabber(C_FACE_HOVER, C_FACE_EDGE))
	t.set_icon("grabber_disabled", "HSlider", make_grabber(C_DISABLED, C_DISABLED_EDGE))
	return t

# A 9-slice box with an outline and a coloured lip along the bottom.
# lip: height of the bottom edge. drop: how far the content sinks (pressed look).
# h_inset: pulls the drawn box in from the sides without changing its layout size (tab gaps).
func make_box_style(shape: Dictionary, face: Color, edge: Color, outline: Color, lip: int, drop: int = 0, pad: Vector2i = Vector2i(8, 2), h_inset: int = 0) -> StyleBoxTexture:
	var width: int = shape["width"]
	var margin: int = shape["margin"]
	var style := StyleBoxTexture.new()
	style.texture = ImageTexture.create_from_image(make_box_image(shape, face, edge, outline, lip))
	style.texture_margin_left = margin
	style.texture_margin_right = margin
	style.texture_margin_top = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = width + pad.x
	style.content_margin_right = width + pad.x
	style.content_margin_top = width + pad.y + drop
	style.content_margin_bottom = width + pad.y + lip
	if h_inset > 0:
		style.expand_margin_left = -h_inset
		style.expand_margin_right = -h_inset
	return style

func make_grabber(face: Color, edge: Color) -> ImageTexture:
	return ImageTexture.create_from_image(make_box_image(SHAPE_GRABBER, face, edge, C_OUTLINE, 2))

func make_knob_texture() -> ImageTexture:
	return ImageTexture.create_from_image(make_box_image(SHAPE_KNOB, C_FACE_HOVER, C_FACE_EDGE, C_OUTLINE, 2))

# A chunky pixel chevron for the chooser arrows. dir: -1 = points left, 1 = points right.
func make_arrow_texture(dir: int) -> ImageTexture:
	var w := 7
	var h := 9
	var mid := int(h / 2.0)
	var image := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var dist := absi(y - mid)
		var x_start := dist if dir < 0 else (w - 1 - dist - 2)
		for step in 3:
			var x := x_start + step
			if x >= 0 and x < w:
				image.set_pixel(x, y, C_INK)
	return ImageTexture.create_from_image(image)

func make_box_image(shape: Dictionary, face: Color, edge: Color, outline: Color, lip: int) -> Image:
	var box_size: Vector2i = shape["size"]
	var cut: int = shape["cut"]
	var width: int = shape["width"]
	var image := Image.create_empty(box_size.x, box_size.y, false, Image.FORMAT_RGBA8)
	for y in box_size.y:
		for x in box_size.x:
			if not is_inside(x, y, box_size, cut):
				continue   # stays transparent: this rounds the corners
			var color := face
			if is_outline(x, y, box_size, cut, width):
				color = outline
			elif y >= box_size.y - width - lip:
				color = edge
			image.set_pixel(x, y, color)
	return image

func is_inside(x: int, y: int, box_size: Vector2i, cut: int) -> bool:
	if x < 0 or y < 0 or x >= box_size.x or y >= box_size.y:
		return false
	return mini(x, box_size.x - 1 - x) + mini(y, box_size.y - 1 - y) >= cut

func is_outline(x: int, y: int, box_size: Vector2i, cut: int, width: int) -> bool:
	for dy in range(-width, width + 1):
		for dx in range(-width, width + 1):
			if absi(dx) + absi(dy) <= width and not is_inside(x + dx, y + dy, box_size, cut):
				return true
	return false

func make_track_style(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = C_OUTLINE
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	box.anti_aliasing = false
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box

# The gold outline shown when a control has keyboard or controller focus.
func make_focus_style(h_inset: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.set_border_width_all(2)
	box.border_color = C_GOLD
	box.set_corner_radius_all(3)
	box.set_expand_margin_all(2)
	if h_inset > 0:
		box.expand_margin_left = 2 - h_inset
		box.expand_margin_right = 2 - h_inset
	box.anti_aliasing = false
	return box

# ---------- building ----------

func build_frame() -> void:
	dim_overlay = ColorRect.new()
	dim_overlay.color = DIM_COLOR
	dim_overlay.modulate.a = 0.0
	dim_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.resized.connect(func() -> void: panel.pivot_offset = panel.size / 2.0)
	center.add_child(panel)

	click_player = AudioStreamPlayer.new()
	click_player.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	if CLICK_SOUND_PATH != "" and ResourceLoader.exists(CLICK_SOUND_PATH):
		click_player.stream = load(CLICK_SOUND_PATH)
	add_child(click_player)

	var column := VBoxContainer.new()
	panel.add_child(column)

	# header: back button, heading, and a spacer the size of the back button to keep the heading centred
	var header := HBoxContainer.new()
	column.add_child(header)

	back_button = make_back_button()
	back_button.pressed.connect(play_click.bind(0.9))
	add_hover_pop(back_button)
	header.add_child(back_button)

	var heading := Label.new()
	heading.text = "Settings"
	heading.theme_type_variation = "HeadingLabel"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)

	var spacer := Control.new()
	spacer.custom_minimum_size = back_button.get_combined_minimum_size()
	header.add_child(spacer)

	tabs = TabContainer.new()
	tabs.tab_alignment = TabBar.ALIGNMENT_CENTER
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.tab_changed.connect(on_tab_changed)
	column.add_child(tabs)

	# footer: reset in the bottom right corner
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(footer)

	reset_button = Button.new()
	reset_button.text = "Reset"
	reset_button.tooltip_text = "Restore all settings"
	reset_button.pressed.connect(reset_defaults)
	add_hover_pop(reset_button)
	footer.add_child(reset_button)

func make_back_button() -> BaseButton:
	var texture: Texture2D = back_texture
	if texture == null and ResourceLoader.exists(BACK_ICON_PATH):
		texture = load(BACK_ICON_PATH)
	if texture == null:
		# No icon found: fall back to a styled button with an arrow.
		var fallback := Button.new()
		fallback.icon = left_arrow_texture
		fallback.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.custom_minimum_size = Vector2(34, 0)
		fallback.pressed.connect(close)
		return fallback

	var button := TextureButton.new()
	button.texture_normal = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = (texture.get_size() * BACK_SCALE).round()
	button.pressed.connect(close)
	# TextureButton has no hover or focus look of its own, so tint it gold.
	var update := func() -> void:
		button.modulate = C_GOLD if (button.is_hovered() or button.has_focus()) else Color.WHITE
	button.mouse_entered.connect(update)
	button.mouse_exited.connect(update)
	button.focus_entered.connect(update)
	button.focus_exited.connect(update)
	return button

func build_rows() -> void:
	var pages := {}
	for key in SETTINGS_UI:
		if not Global.SETTINGS_TYPE.has(key):
			push_warning("SETTINGS_UI has '%s' but SETTINGS_TYPE does not." % key)
			continue
		var info: Dictionary = SETTINGS_UI[key]
		var tab_name: String = info["tab"]
		if not pages.has(tab_name):
			var page_panel := PanelContainer.new()
			page_panel.name = tab_name   # TabContainer uses the node name as the tab title
			page_panel.theme_type_variation = "TabPagePanel"
			tabs.add_child(page_panel)

			var page := VBoxContainer.new()
			page_panel.add_child(page)
			pages[tab_name] = page
		pages[tab_name].add_child(make_row(key, info))
	refresh()

func make_row(key: String, info: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = ROW_HEIGHT
	row.mouse_filter = Control.MOUSE_FILTER_PASS

	var label_slot := Control.new()
	label_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label_slot)

	var label := Label.new()
	label.text = info["label"]
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_slot.add_child(label)

	var control: Control
	match Global.SETTINGS_TYPE[key][0]:
		"bool":
			control = make_toggle(key)
		"range":
			control = make_slider(key)
		"int", "str":
			control = make_chooser(key, info)
		_:
			push_warning("No control for the tag of '%s'." % key)
			control = Control.new()
	control.custom_minimum_size.x = CONTROL_WIDTH
	row.add_child(control)

	add_row_juice(row, label)
	rows[key] = row
	return row

func make_toggle(key: String) -> Control:
	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_END

	var button := Button.new()
	button.toggle_mode = true
	button.theme_type_variation = "ToggleSwitch"
	button.custom_minimum_size = TOGGLE_SIZE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(button)
	add_hover_pop(button)

	var knob := TextureRect.new()
	knob.texture = knob_texture
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.pivot_offset = SHAPE_KNOB["size"] / 2.0
	button.add_child(knob)
	knob.position = Vector2(KNOB_OFF_X, KNOB_Y)

	# Slides the knob with a subtle stretch. Snaps when hidden or reduced motion is on.
	var move_knob := func(on: bool) -> void:
		var target := Vector2(KNOB_ON_X if on else KNOB_OFF_X, KNOB_Y)
		if knob.position == target:
			return
		kill_meta_tween(knob, "slide_tween")
		if not is_visible_in_tree() or Global.get_setting("reduced_motion"):
			knob.position = target
			knob.scale = Vector2.ONE
			return
		var slide := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		slide.tween_property(knob, "position", target, 0.16)
		slide.parallel().tween_property(knob, "scale", Vector2(1.18, 0.86), 0.06)
		slide.chain().tween_property(knob, "scale", Vector2.ONE, 0.10)
		knob.set_meta("slide_tween", slide)

	button.toggled.connect(func(on: bool) -> void:
		play_click(1.18 if on else 0.88)
		Global.set_setting(key, on))
	refreshers[key] = func() -> void:
		var on: bool = Global.get_setting(key)
		button.set_pressed_no_signal(on)
		move_knob.call(on)
	return box

func make_slider(key: String) -> Control:
	var rule: Array = Global.SETTINGS_TYPE[key]   # ["range", min, max, step]
	var box := HBoxContainer.new()

	var slider := HSlider.new()
	slider.min_value = rule[1]
	slider.max_value = rule[2]
	slider.step = rule[3]
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(slider)
	add_hover_pop(slider)

	var value_label := Label.new()
	value_label.custom_minimum_size.x = 40
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(value_label)

	# Sliders send floats, but the validator only accepts ints.
	# The click rises in pitch as the slider goes up.
	slider.value_changed.connect(func(value: float) -> void:
		play_click(lerpf(0.8, 1.4, inverse_lerp(float(rule[1]), float(rule[2]), value)))
		pop_label(value_label)
		Global.set_setting(key, roundi(value)))
	refreshers[key] = func() -> void:
		var value: int = Global.get_setting(key)
		slider.set_value_no_signal(value)
		value_label.text = "%d%%" % value
	return box

func make_chooser(key: String, info: Dictionary) -> Control:
	var allowed: Array = Global.SETTINGS_TYPE[key].slice(1)
	var labels: Array = info.get("options", [])
	if allowed.is_empty():
		push_warning("No allowed options for '%s'." % key)
		return Control.new()
	if labels.size() != allowed.size():
		push_warning("'%s' has %d allowed values but %d option labels." % [key, allowed.size(), labels.size()])

	var box := HBoxContainer.new()

	var left := Button.new()
	left.icon = left_arrow_texture
	left.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.custom_minimum_size.x = 28
	left.tooltip_text = "Previous option"

	# the label sits in a clipped slot so the text can slide in and out
	var value_slot := Control.new()
	value_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_slot.clip_contents = true
	var value_label := Label.new()
	value_slot.add_child(value_label)
	value_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Lift the label slightly so its visual center aligns with the raised face of the 3px-lip buttons
	value_label.offset_top = CHOOSER_TEXT_OFFSET
	value_label.offset_bottom = CHOOSER_TEXT_OFFSET
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var right := Button.new()
	right.icon = right_arrow_texture
	right.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.custom_minimum_size.x = 28
	right.tooltip_text = "Next option"

	box.add_child(left)
	box.add_child(value_slot)
	box.add_child(right)
	add_hover_pop(left)
	add_hover_pop(right)

	# remembers which arrow was pressed, so the text slides the right way (an array so the lambdas share it)
	var last_direction := [1]

	var step := func(direction: int) -> void:
		var current_index: int = allowed.find(Global.get_setting(key))
		if current_index == -1:
			current_index = 0
		var next_index := posmod(current_index + direction, allowed.size())
		if next_index == current_index:
			return
		play_click(1.0 + 0.1 * direction)
		last_direction[0] = direction
		Global.set_setting(key, allowed[next_index])
	left.pressed.connect(step.bind(-1))
	right.pressed.connect(step.bind(1))

	refreshers[key] = func() -> void:
		var current_value = Global.get_setting(key)
		var index: int = allowed.find(current_value)
		var new_text: String = str(labels[index]) if (index >= 0 and index < labels.size()) else str(current_value)
		if value_label.text == new_text:
			return
		slide_label(value_label, new_text, last_direction[0])
		last_direction[0] = 1
	return box

# ---------- keeping the UI in sync ----------

func refresh() -> void:
	for key in refreshers:
		refreshers[key].call()
	for key in rows:
		var condition: Dictionary = SETTINGS_UI[key].get("enabled_if", {})
		var enabled: bool = condition.is_empty() or Global.get_setting(condition["key"]) == condition["equals"]
		set_row_enabled(rows[key], enabled)
		rows[key].modulate = Color.WHITE if enabled else DISABLED_TINT

func set_row_enabled(node: Node, enabled: bool) -> void:
	if node is BaseButton:
		node.disabled = not enabled
	elif node is Slider:
		node.editable = enabled
	for child in node.get_children():
		set_row_enabled(child, enabled)

func on_setting_changed(_setting_name, _setting_value) -> void:
	if visible:
		refresh()

func reset_defaults() -> void:
	for key in Global.DEFAULT_SETTINGS:
		if Global.get_setting(key) != Global.DEFAULT_SETTINGS[key]:
			Global.set_setting(key, Global.DEFAULT_SETTINGS[key])
	refresh()
	pulse(reset_button)
	play_click(1.2)
