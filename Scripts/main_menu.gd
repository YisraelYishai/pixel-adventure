extends Control

@onready var title: Label = %Title
@onready var top_row: HBoxContainer = %TopRow
@onready var play_button: TextureButton = %PlayButton
@onready var transition_wipe: Node = %TransitionWipe
@onready var volume_button: TextureButton = %VolumeButton
@onready var settings_button: AnimatedButton = %SettingsButton
@onready var quit_button: AnimatedButton = %QuitButton


var bob_amp := 3.0
var bob_speed := 4.12
var title_y: float
var bob_phase := 0.0
var bob_active := false
var hover_tween: Tween
var loaded := false

func _ready() -> void:
	Global.setting_changed.connect(bob_active_change)
	Global.setting_changed.connect(mute_change)
	play_button.pressed.connect(on_play_pressed)
	volume_button.toggled.connect(on_volume_toggled)
	settings_button.pressed.connect(%SettingsPanel.open)
	
	if OS.has_feature("pc"):
		quit_button.pressed.connect(Global.quit_game)
	else:
		quit_button.disabled = true
		quit_button.self_modulate = "ffffff00"
	sync_volume_button()
	
	title.pivot_offset = title.size / 2.0
	title.resized.connect(func(): title.pivot_offset = title.size / 2.0)
	title.mouse_entered.connect(on_title_hover.bind(true))
	title.mouse_exited.connect(on_title_hover.bind(false))

	await get_tree().process_frame
	title_y = title.position.y
	await intro()

	loaded = true
	bob_active_change("reduced_motion", Global.get_setting("reduced_motion"))


func _process(delta: float) -> void:
	if not bob_active:
		return
	bob_phase = fmod(bob_phase + delta * bob_speed, TAU)
	title.position.y = title_y + sin(bob_phase) * bob_amp

func intro() -> void:
	var buttons: Array[Control] = []
	for row in [%BottomRow, %TopRow]:
		for c in row.get_children():
			buttons.append(c)

	title.position.y = title_y - 90
	title.modulate.a = 0.0
	for b in buttons:
		b.scale = Vector2.ZERO

	var t := create_tween()
	if Global.get_setting("reduced_motion"):
		t.set_speed_scale(100)
	t.tween_property(title, "position:y", title_y, 0.6) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(title, "modulate:a", 1.0, 0.5)

	# staggered pop-in
	for i in buttons.size():
		t.parallel().tween_property(buttons[i], "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT) \
			.set_delay(0.67 + i * 0.07)
	await t.finished

func on_title_hover(hovering: bool) -> void:
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if Global.get_setting("reduced_motion"):
		hover_tween.set_speed_scale(100)
	hover_tween.tween_property(title, "scale", Vector2.ONE * (1.08 if hovering else 1.0), 0.2)

func on_volume_toggled(muted: bool) -> void:
	Global.set_setting("mute_all", muted)

func sync_volume_button() -> void:
	var mute_status: bool = Global.get_setting("mute_all")
	volume_button.set_pressed_no_signal(mute_status)
	volume_button.setIcon(load("res://Assets/Pixel Adventure 1/Menu/Buttons/Volume Muted.png") if mute_status else load("res://Assets/Pixel Adventure 1/Menu/Buttons/Volume.png"))


func on_play_pressed() -> void:
	var transition_reparent := transition_wipe
	transition_reparent.play(true)
	await transition_reparent.covered

	get_tree().change_scene_to_file("res://Scenes/levels/test.tscn")

func bob_active_change(status_name, status_value):
	if not loaded:
		return

	if status_name == "reduced_motion":
		if status_value:
			bob_active = false
			title.position.y = title_y
		else:
			bob_active = true

func mute_change(status_name, _status_value):
	if status_name == "mute_all":
		sync_volume_button()
