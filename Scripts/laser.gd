extends CharacterBody2D

@export var speed : float = 300

func _physics_process(delta: float) -> void:
	move_and_slide()
