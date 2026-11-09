extends Node


func _ready() -> void:
	Global.setting_changed.connect(report)
	#Global.set_setting("reduced_motion", true)

func report(setting, new_value):
	print("New value set: key=", setting, " ,value=", new_value)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			Global.set_setting("reduced_motion", false)
		if event.keycode == KEY_F:
			Global.set_setting("reduced_motion", true)
