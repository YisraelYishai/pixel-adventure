extends Node

# Signals
signal respawn_objects
signal setting_changed(setting_name, setting_value)

# Settings
const SAVE_PATH = "user://settings.cfg"
const BASE_RES = Vector2i(640, 360)
const BUS_BLUEPRINT: Dictionary = {"master_volume": "Master", "music_volume": "Music", "sfx_volume": "SFX"}
const DEFAULT_SETTINGS: Dictionary = {
	"window_mode": 1, 
	"window_size": 0, 
	"vsync_mode": 1, 
	"fps_limit": 60, 
	"master_volume": 100, 
	"music_volume": 100, 
	"sfx_volume": 100, 
	"mute_all": false, 
	"mute_unfocused": true,
	"reduced_motion": false,
	"screen_shake": 80
	}
const SETTINGS_TYPE: Dictionary = {
	"window_mode": ["int", 0, 1, 2, 3], 
	"window_size": ["int", 0, 1, 2, 3], 
	"vsync_mode": ["int", 0, 1, 2], 
	"fps_limit": ["int", 30, 60, 120, 144, 0], 
	"master_volume": ["range", 0, 100, 5], 
	"music_volume": ["range", 0, 100, 5], 
	"sfx_volume": ["range", 0, 100, 5], 
	"mute_all": ["bool"],
	"mute_unfocused": ["bool"],
	"reduced_motion": ["bool"],
	"screen_shake": ["range", 0, 100, 10]
	}

var config = ConfigFile.new()
var user_settings: Dictionary
var debounce_timer: Timer
var focused: bool = true

func _ready() -> void:
	# Startup
	process_mode = Node.PROCESS_MODE_ALWAYS
	user_settings = DEFAULT_SETTINGS.duplicate()

	load_config()

	for key in user_settings:
		apply_setting(key, user_settings[key])
		note_config(key, user_settings[key])

	save_config()
	
	# Timer
	debounce_timer = Timer.new()
	add_child(debounce_timer)
	debounce_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	debounce_timer.one_shot = true
	debounce_timer.wait_time = 0.5
	debounce_timer.timeout.connect(save_config)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focused = false
		apply_setting("master_volume", get_setting("master_volume"))
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = true
		apply_setting("master_volume", get_setting("master_volume"))

func set_setting(setting_name: String, setting_value: Variant):
	if not DEFAULT_SETTINGS.has(setting_name):
		print_rich("[color=D9544D]Warning: ", setting_name, " is not a valid setting![/color]")
	elif not is_valid_prompt(setting_name, setting_value):
		print_rich("[color=D9544D]Warning: ", str(setting_value), " is not a valid value for ", setting_name, "![/color]")
	elif user_settings[setting_name] == setting_value:
		print_rich("[color=FFFF84][i]Notice: ", setting_name, " is already set to that value.[/i][/color]")
	else:
		user_settings[setting_name] = setting_value
		apply_setting(setting_name, setting_value)
		note_config(setting_name, setting_value)
		setting_changed.emit(setting_name, setting_value)
		debounce_timer.start()


func apply_setting(setting_name: String, setting_value: Variant):
	match setting_name:
		"window_mode":
			match setting_value:
				0:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
					apply_setting("window_size", get_setting("window_size"))
				1:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
				2:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
				3:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		"window_size":
			if get_setting("window_mode") == 0:
				get_window().size = BASE_RES * (int(setting_value) + 1)
				get_window().move_to_center()
		"vsync_mode":
			match setting_value:
				0:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
				1:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
				2:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
		"fps_limit":
			Engine.max_fps = setting_value
		"master_volume", "music_volume", "sfx_volume":
			var bus: String = BUS_BLUEPRINT[setting_name]
			var bus_index: int = AudioServer.get_bus_index(bus)
			var should_mute: bool = setting_value == 0 or (setting_name == "master_volume" and (get_setting("mute_all") or (get_setting("mute_unfocused") and not focused)))
			if bus_index == -1:
				print_rich("[color=D9544D]Warning: No bus named ", bus, " in bus layout![/color]")
				return

			AudioServer.set_bus_mute(bus_index, should_mute)

			if setting_value > 0:
				var linear_value = setting_value / 100.0
				var db_value = linear_to_db(linear_value)
				AudioServer.set_bus_volume_db(bus_index, db_value)
		"mute_all", "mute_unfocused":
			apply_setting("master_volume", get_setting("master_volume"))
		"reduced_motion":
			pass
		"screen_shake":
			pass
		_:
			print_rich("[color=D9544D]Warning: No case for ", setting_name, " in apply_setting![/color]")
			


func get_setting(setting_name: String):
	if DEFAULT_SETTINGS.has(setting_name):
		var value = user_settings[setting_name]
		return value
	else:
		print_rich("[color=D9544D]Warning: ", setting_name, "'s key doesn't exist prompted by get_setting()[/color]")
		return null

func load_config():
	var error = config.load(SAVE_PATH)
	
	if error != OK:
		save_config()

	for key in user_settings:
		var loaded_value = config.get_value(key_to_section(key), key, DEFAULT_SETTINGS[key])
		if is_valid_prompt(key, loaded_value):
			user_settings[key] = loaded_value
		else:
			print_rich("[color=FFFF84][i]Notice: invalid value for ", key, " in config. Using default.[/i][/color]")
			user_settings[key] = DEFAULT_SETTINGS[key]

func note_config(key: String, value: Variant):
	config.set_value(key_to_section(key), key, value)

func save_config():
	config.save(SAVE_PATH)

func quit_game():
	debounce_timer.stop()
	save_config()
	get_tree().quit()

func key_to_section(key: String):
	match key:
		"window_mode", "window_size", "vsync_mode", "fps_limit":
			return "Window"
		"master_volume", "music_volume", "sfx_volume", "mute_all", "mute_unfocused":
			return "Audio"
		"reduced_motion", "screen_shake":
			return "Game"
		_:
			print_rich("[color=D9544D]Invalid key for converting into section![/color]")


func is_valid_prompt(key: String, value: Variant) -> bool:
	if not SETTINGS_TYPE.has(key):
		return false
	elif SETTINGS_TYPE[key][0] == "str" and typeof(value) == TYPE_STRING:
		if SETTINGS_TYPE[key].slice(1).has(value):
			return true
		else:
			return false
	elif SETTINGS_TYPE[key][0] == "int" and typeof(value) == TYPE_INT:
		if SETTINGS_TYPE[key].slice(1).has(value):
			return true
		else:
			return false
	elif SETTINGS_TYPE[key][0] == "range" and typeof(value) == TYPE_INT:
		if (value >= SETTINGS_TYPE[key][1] && value <= SETTINGS_TYPE[key][2]) and ((value - SETTINGS_TYPE[key][1]) % SETTINGS_TYPE[key][3] == 0):
			return true
		else:
			return false
	elif SETTINGS_TYPE[key][0] == "bool" and typeof(value) == TYPE_BOOL:
		return true
	else:
		return false
