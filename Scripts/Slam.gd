extends StaticBody2D

@export var slam_dur : float = 0.45

func _process(delta: float) -> void:
	await get_tree().create_timer(slam_dur).timeout
	queue_free()
