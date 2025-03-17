extends ProgressBar

@onready var timer : Timer = $Timer
@onready var dmgBar : ProgressBar = $DamageBar

var health: float = 0

func set_hp(new_health : float):
	if not is_instance_valid(dmgBar): dmgBar = $DamageBar
	var prev_health = health
	health = min(max_value, new_health)
	value = float(health)
	
	if health <= 0:
		queue_free()
	
	if health < prev_health:
		if not is_instance_valid(timer): timer = $Timer
		timer.start()
	else:
		dmgBar.value = float(health)

func init_health(_health : float):
	if not is_instance_valid(dmgBar): dmgBar = $DamageBar
	health = _health
	max_value = _health
	value = _health
	dmgBar.max_value = _health
	dmgBar.value = _health

func _on_timer_timeout() -> void:
	dmgBar.value = health
