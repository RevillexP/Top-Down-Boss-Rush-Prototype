extends Node2D

@export var spawnEnemies = false

var enemy = preload("res://Scenes/Enemy.tscn")

func _on_spawn_timer_timeout() -> void:
	if spawnEnemies:
		var enemy_instance = enemy.instantiate()
		$Holders/Enemies.add_child(enemy_instance)
		enemy_instance.position = $Holders/SpawnPoints.get_children().pick_random().position
