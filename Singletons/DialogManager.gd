extends Node

#OK, so what's happening here?

@onready var textBoxScene = preload("res://Scenes/TextBox.tscn")

var dialogLines: Array[String] = []
var currentLineIndex = 0

var textBox
var textBoxPosition : Vector2

var isDialogActive = false
var canAdvanceLine = false

func startDialog(positon : Vector2, lines : Array[String]):
	#Dialog Setup, checks if its already running, if not, sets variables up.
	if isDialogActive:
		return
	
	dialogLines = lines
	textBoxPosition = positon
	showTextBox()
	
	isDialogActive = true

func showTextBox():
	textBox = textBoxScene.instantiate()
	textBox.finished_displaying.connect(_on_text_box_finished_displaying)
	get_tree().root.add_child(textBox) 
	textBox.global_position = textBoxPosition
	textBox.displayText(dialogLines[currentLineIndex])
	canAdvanceLine = false

func _on_text_box_finished_displaying():
	canAdvanceLine = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Advance_Dialog") and isDialogActive and canAdvanceLine:
		textBox.queue_free()
		currentLineIndex += 1
		if currentLineIndex >= dialogLines.size():
			isDialogActive = false
			currentLineIndex = 0
			return
		
		showTextBox()
