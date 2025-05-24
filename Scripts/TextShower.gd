extends Label

@export var message := "Heyo. Thanks a bunch for trying this game out. Honestly means the world to me ♡."
@export var punctuation_time := 0.07
@export var space_time := 0.05
@export var full_stop_time := 0.1
@export var letter_time := 0.02

var lastIndex = 0

func _ready() -> void:
	text = message[0]
	message.strip_edges(true, true)
	showNextText()

func showNextText() -> void:
	var timer = $Timer
	var lastLetter = text[text.length() - 1]
	
	if lastLetter in ",;:":
		timer.wait_time = punctuation_time
	elif lastLetter.is_empty():
		timer.wait_time = space_time
	elif lastLetter in ".?!":
		timer.wait_time = full_stop_time
	else:
		timer.wait_time = letter_time
	
	timer.start()
	await timer.timeout
	
	if len(message) - 1 >= lastIndex + 1:
		lastIndex += 1
		text += message[lastIndex]
		showNextText()
	else:
		pass
