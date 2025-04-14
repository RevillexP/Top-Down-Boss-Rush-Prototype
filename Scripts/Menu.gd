extends Control

func _ready() -> void:
	$AudioStreamPlayer.stream = load("res://SFX/funny-bgm-240795.mp3")
	$AudioStreamPlayer.play()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func exitButtonPressed() -> void:
	get_tree().quit()
