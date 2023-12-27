extends Node2D

var level = "res://screens/world.tscn"

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_play_button_pressed():
	var _level = get_tree().change_scene_to_file(level)
