extends Node2D

@export var spawnEnemies := false
@onready var deathMenu := $"Death Menu"
@onready var bgAudio := $BGAudio

var noFightingAudio := preload("res://SFX/energetic-bgm-242515.mp3")
var fightingAudio := preload("res://SFX/gaming-music-8-bit-console-play-background-intro-theme-278382.mp3")

var battleStarted := false

var enemy := preload("res://Scenes/Enemy.tscn")

func _ready() -> void:
	$Player.death_signal.connect(showDeathMenu)
	deathMenu.hide()
	
	bgAudio.volume_db = -80
	bgAudio.stream = noFightingAudio
	bgAudio.play()
	var audioTween = get_tree().create_tween()
	audioTween.tween_property(bgAudio, "volume_db", -20, 3)

func _on_spawn_timer_timeout() -> void:
	if spawnEnemies:
		var enemy_instance = enemy.instantiate()
		$Holders/Enemies.add_child(enemy_instance)
		enemy_instance.position = $Holders/SpawnPoints.get_children().pick_random().position

func showDeathMenu() -> void:
	print("Hello.")
	deathMenu.show()
	get_tree().paused = true

func RetryButtonPressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func QuitButtonPressed() -> void:
	get_tree().quit()

func OnBattleStartAreaEntered(area: Area2D) -> void:
	$Luita.startBattle()
	$Area2D.set_deferred("monitoring", false)
	
	var audioTween = get_tree().create_tween()
	audioTween.tween_property(bgAudio, "volume_db", -80, 2)
	
	bgAudio.stream = fightingAudio
	bgAudio.play()
	audioTween.tween_property(bgAudio, "volume_db", -20, 2)
