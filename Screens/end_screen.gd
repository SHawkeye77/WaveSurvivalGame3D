extends Node2D

@onready var gameSummaryLabel = get_node("%GameSummaryLabel")
var startScreen = "res://screens/start_screen.tscn"

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Player won
	if Global.finalWave > Global.maxWave:
		gameSummaryLabel.text = "SUCCESS: You survived all " + str(Global.maxWave) + " waves"
	# Player lost
	else:
		gameSummaryLabel.text = "FAILURE: You died on wave " + str(Global.finalWave)

func _on_main_menu_button_pressed():
	var _level = get_tree().change_scene_to_file(startScreen)
