extends Marker2D

@export var anim_dur = 0.3

func _physics_process(delta: float) -> void:
	await get_tree().create_timer(anim_dur).timeout
	queue_free()
