extends Control

const NEXT_SCENE := "res://Scenes/levels/main_menu.tscn"
const SKIP_ALLOWED_AFTER := 1.75

@onready var anim: AnimationPlayer = $AnimationPlayer

var done := false
@onready var transition_wipe: Node = $TransitionWipe


func _input(event: InputEvent) -> void:
	if anim.current_animation_position < SKIP_ALLOWED_AFTER:
		return
	if (event is InputEventKey and event.pressed and not event.echo) \
			or (event is InputEventMouseButton and event.pressed):
		go_next()


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	go_next()


func go_next() -> void:
	if done:
		return
	done = true
	
	await get_tree().create_timer(0.15).timeout
	var transition_reparent := transition_wipe
	transition_reparent.play(true)
	await transition_reparent.covered
	
	get_tree().change_scene_to_file(NEXT_SCENE)
