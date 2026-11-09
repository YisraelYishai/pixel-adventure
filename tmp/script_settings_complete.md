Here's a settings panel built around two parts. A `Settings` autoload owns the values, applies them, and saves them. The panel is a thin UI that builds its rows from a schema list. Because the UI never touches the engine directly, the same scene works in your main menu and your pause menu, and adding a setting later is one dictionary entry.

## 1. The `Settings` autoload (`settings.gd`)

Add it in **Project Settings → Globals → Autoload** with the name `Settings`.

```gdscript
extends Node

signal changed(key: String)

const PATH := "user://settings.cfg"
const BASE_SIZE := Vector2i(640, 360)     # your game's base resolution
const BUSES := {"master": "Master", "music": "Music", "sfx": "SFX"}

# One entry per setting. The panel builds its rows from this list.
const SCHEMA := [
	# Display
	{"tab": "Display", "key": "window_mode", "label": "Window mode", "kind": "choice",
		"options": ["Windowed", "Fullscreen", "Exclusive"], "default": 0},
	{"tab": "Display", "key": "window_scale", "label": "Window size", "kind": "choice",
		"options": ["1x", "2x", "3x", "4x"], "default": 1,
		"enabled_if": {"key": "window_mode", "equals": 0}},
	{"tab": "Display", "key": "vsync", "label": "V-Sync", "kind": "choice",
		"options": ["Off", "On", "Adaptive"], "default": 1},
	{"tab": "Display", "key": "fps_cap", "label": "FPS limit", "kind": "choice",
		"options": ["30", "60", "120", "144", "Unlimited"], "default": 4},
	# Audio
	{"tab": "Audio", "key": "master", "label": "Master", "kind": "slider",
		"min": 0, "max": 100, "step": 5, "default": 80},
	{"tab": "Audio", "key": "music", "label": "Music", "kind": "slider",
		"min": 0, "max": 100, "step": 5, "default": 70},
	{"tab": "Audio", "key": "sfx", "label": "Effects", "kind": "slider",
		"min": 0, "max": 100, "step": 5, "default": 80},
	{"tab": "Audio", "key": "master_muted", "label": "Mute all", "kind": "toggle", "default": false},
	{"tab": "Audio", "key": "mute_unfocused", "label": "Mute when unfocused", "kind": "toggle", "default": true},
	# Game
	{"tab": "Game", "key": "screen_shake", "label": "Screen shake", "kind": "slider",
		"min": 0, "max": 100, "step": 10, "default": 100},
	{"tab": "Game", "key": "reduced_motion", "label": "Reduced motion", "kind": "toggle", "default": false},
]

var values := {}
var save_timer: Timer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	save_timer = Timer.new()
	save_timer.one_shot = true
	save_timer.wait_time = 0.5
	save_timer.timeout.connect(save_file)
	add_child(save_timer)

	for entry in SCHEMA:
		values[entry.key] = entry.default
	load_file()
	for entry in SCHEMA:
		apply(entry.key)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_file()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and get_value("mute_unfocused"):
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		apply_audio()

func get_value(key: String) -> Variant:
	return values.get(key)

func set_value(key: String, value: Variant) -> void:
	if values.get(key) == value:
		return
	values[key] = value
	apply(key)
	changed.emit(key)
	save_timer.start()          # debounced, so dragging a slider doesn't spam the disk

func reset_defaults() -> void:
	for entry in SCHEMA:
		set_value(entry.key, entry.default)

func apply(key: String) -> void:
	match key:
		"window_mode", "window_scale":
			apply_window()
		"vsync":
			var modes := [DisplayServer.VSYNC_DISABLED, DisplayServer.VSYNC_ENABLED, DisplayServer.VSYNC_ADAPTIVE]
			DisplayServer.window_set_vsync_mode(modes[get_value("vsync")])
		"fps_cap":
			Engine.max_fps = [30, 60, 120, 144, 0][get_value("fps_cap")]
		"master", "music", "sfx", "master_muted":
			apply_audio()

func apply_window() -> void:
	var window := get_window()
	match get_value("window_mode"):
		0:
			window.mode = Window.MODE_WINDOWED
			window.size = BASE_SIZE * (int(get_value("window_scale")) + 1)
			window.move_to_center()
		1:
			window.mode = Window.MODE_FULLSCREEN
		2:
			window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN

func apply_audio() -> void:
	for key in BUSES:
		var index := AudioServer.get_bus_index(BUSES[key])
		if index == -1:
			continue
		var linear := float(get_value(key)) / 100.0
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(index, linear <= 0.0 or (key == "master" and get_value("master_muted")))

func save_file() -> void:
	var file := ConfigFile.new()
	for key in values:
		file.set_value("settings", key, values[key])
	file.save(PATH)

func load_file() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) != OK:
		return
	for key in values:
		values[key] = file.get_value("settings", key, values[key])
```

Create `Music` and `SFX` buses in the Audio tab. Missing buses are skipped safely.

## 2. The panel

Make a new inherited scene from `menu_panel.tscn` (the base from the last message) and save it as `settings_panel.tscn`. Then:

- Select `Window` and set **Custom Minimum Size** to `384 × 240`.
- Set the panel root's **Process → Mode** to `Always`, so it works in the pause menu.
- Attach this script to the root:

```gdscript
class_name SettingsPanel
extends MenuPanel

const ROW_HEIGHT := 24
const CONTROL_WIDTH := 160

var rows := {}          # key -> {"entry": Dictionary, "row": Control}
var refreshers := {}    # key -> Callable that updates a control from Settings
var tabs: TabContainer

func _ready() -> void:
	super()
	%Heading.text = "Settings"
	build()
	Settings.changed.connect(on_setting_changed)

func open() -> void:
	refresh()
	super()

func build() -> void:
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	%Content.add_child(tabs)

	var pages := {}
	for entry in Settings.SCHEMA:
		if not pages.has(entry.tab):
			var page := VBoxContainer.new()
			page.name = entry.tab               # TabContainer uses the node name as the tab title
			page.add_theme_constant_override("separation", 2)
			tabs.add_child(page)
			pages[entry.tab] = page
		pages[entry.tab].add_child(make_row(entry))

	var reset := Button.new()
	reset.text = "Reset to defaults"
	reset.pressed.connect(Settings.reset_defaults)
	%Content.add_child(reset)
	refresh()

func make_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = ROW_HEIGHT

	var label := Label.new()
	label.text = entry.label
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var control: Control
	match entry.kind:
		"choice":
			control = make_choice(entry)
		"slider":
			control = make_slider(entry)
		"toggle":
			control = make_toggle(entry)
	control.custom_minimum_size.x = CONTROL_WIDTH
	row.add_child(control)

	rows[entry.key] = {"entry": entry, "row": row}
	return row

func make_choice(entry: Dictionary) -> Control:
	var box := HBoxContainer.new()
	var left := Button.new()
	left.text = "<"
	var value_label := Label.new()
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var right := Button.new()
	right.text = ">"
	box.add_child(left)
	box.add_child(value_label)
	box.add_child(right)

	var count: int = entry.options.size()
	var step := func(direction: int) -> void:
		var next := posmod(int(Settings.get_value(entry.key)) + direction, count)
		Settings.set_value(entry.key, next)
	left.pressed.connect(step.bind(-1))
	right.pressed.connect(step.bind(1))

	refreshers[entry.key] = func() -> void:
		value_label.text = entry.options[int(Settings.get_value(entry.key))]
	return box

func make_slider(entry: Dictionary) -> Control:
	var box := HBoxContainer.new()
	var slider := HSlider.new()
	slider.min_value = entry.min
	slider.max_value = entry.max
	slider.step = entry.step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 36
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(slider)
	box.add_child(value_label)

	slider.value_changed.connect(func(value: float) -> void: Settings.set_value(entry.key, int(value)))
	refreshers[entry.key] = func() -> void:
		var value: int = Settings.get_value(entry.key)
		slider.set_value_no_signal(value)
		value_label.text = "%d%%" % value
	return box

func make_toggle(entry: Dictionary) -> Control:
	var button := Button.new()
	button.toggle_mode = true
	button.toggled.connect(func(on: bool) -> void: Settings.set_value(entry.key, on))
	refreshers[entry.key] = func() -> void:
		var on: bool = Settings.get_value(entry.key)
		button.set_pressed_no_signal(on)
		button.text = "ON" if on else "OFF"
	return button

func refresh() -> void:
	for key in refreshers:
		refreshers[key].call()
	for key in rows:
		var entry: Dictionary = rows[key].entry
		var condition: Dictionary = entry.get("enabled_if", {})
		var enabled: bool = condition.is_empty() \
			or Settings.get_value(condition.key) == condition.equals
		set_row_enabled(rows[key].row, enabled)
		rows[key].row.modulate.a = 1.0 if enabled else 0.4

func set_row_enabled(node: Node, enabled: bool) -> void:
	if node is BaseButton:
		node.disabled = not enabled
	elif node is Slider:
		node.editable = enabled
	for child in node.get_children():
		set_row_enabled(child, enabled)

func on_setting_changed(key: String) -> void:
	refresh()
```

Everything flows one way. A control changes `Settings`, `Settings` applies it and emits `changed`, and the panel refreshes every row. So the volume button, a controller shortcut, and the Reset button can all change a setting and the panel stays correct.

## 3. Hook it up

**Main menu**: your volume button and the panel now share one source of truth:

```gdscript
func _ready() -> void:
	# ... existing code ...
	%SettingsButton.pressed.connect(%SettingsPanel.open)
	%VolumeButton.set_pressed_no_signal(Settings.get_value("master_muted"))
	Settings.changed.connect(on_settings_changed)

func on_volume_toggled(muted: bool) -> void:
	Settings.set_value("master_muted", muted)

func on_settings_changed(key: String) -> void:
	if key == "master_muted":
		%VolumeButton.set_pressed_no_signal(Settings.get_value("master_muted"))
```

**Pause menu**: instance the same `settings_panel.tscn` and call `open()` from its Settings button. Because the panel root is set to `Process: Always`, it keeps working while `get_tree().paused` is true. Escape closes the panel before it can reach the pause menu, since the base script marks the event handled.

**Using the settings elsewhere in the game:**

```gdscript
var shake := base_shake * Settings.get_value("screen_shake") / 100.0

# in menus, to skip the idle title bob
bob_active = not Settings.get_value("reduced_motion")
```

## 4. Why this size

- **384×240** on a 640×360 base is 60% of the width and two thirds of the height, which leaves a clear frame of dim around it. It's also a multiple of 8, so 9-slice art lines up cleanly.
- The window doesn't resize when you switch tabs, because the minimum size is fixed. Keep each tab to **five rows or fewer** (24px each). If a tab needs more, wrap its page in a `ScrollContainer`.
- Add one shared `Theme` resource with your font, button, slider, and tab styleboxes, and set it on the panel root. Every row inherits it and you never style controls by hand. Use Nearest filtering and whole-number font sizes, like your other UI.

## Where to take it next

- A **Controls** tab with key rebinding via `InputMap`, saved in the same config file.
- An **FPS counter** toggle: a CanvasLayer with a Label, shown or hidden in `apply()`.
- A short **tick sound** when a slider drag ends, so the volume change is audible. Connect `drag_ended` in `make_slider`.
- A **revert countdown** for the window size, in case a mode change leaves someone on an unusable screen.

I used snake_case to match your script. If you want camelCase instead, say so and I'll convert it. Tell me which of the extras you want and I'll write it.