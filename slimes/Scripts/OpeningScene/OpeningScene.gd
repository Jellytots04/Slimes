extends Node3D

@onready var start_button: Button = $Camera3D/Control/CanvasLayer/Panel/VBoxContainer/StartButton
@onready var quit_button: Button = $Camera3D/Control/CanvasLayer/Panel/VBoxContainer/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	# Free all slimes in this scene before switching
	for slime in get_tree().get_nodes_in_group("slimes"):
		slime.queue_free()
	
	await get_tree().process_frame
	
	get_tree().change_scene_to_file("res://Scenes/PCDebugandTest/PCMainTest.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
