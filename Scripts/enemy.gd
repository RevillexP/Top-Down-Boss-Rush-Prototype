extends CharacterBody2D

@export var speed : int = 10
@export var explosionTimer : float = 5
@export var damageOnExplosion : float 

@export var explosionHolder : Node

var explosionFX = preload("res://Scenes/explosion_fx.tscn")

var player_pos
var target_pos
var notExploding : bool = true

@onready var player = get_parent().get_parent().get_parent().get_node("Player")

func _ready() -> void:
	explosionHolder = get_parent().get_parent().get_parent().get_node("Holders").get_node("ExplosionHolder")

func _physics_process(delta: float) -> void:
	player_pos = player.position
	target_pos = (player_pos - position).normalized()
	$AnimatedSprite2D.visible = true
	$AnimatedSprite2D.play("Slime")
	
	if position.distance_to(player_pos) > 5 and notExploding:
		velocity = target_pos*speed
		move_and_slide()
		#look_at(player_pos)

func explode(dmg : int) -> void:
	$ExplosionRadius/ExplosionCollision.set_deferred("disabled", false);
	notExploding = false;
	
	var FX : CPUParticles2D = explosionFX.instantiate()
	explosionHolder.add_child(FX)
	FX.position = position
	FX.one_shot = true
	FX.emitting = true
	
	await get_tree().create_timer(0.05).timeout
	#Make Anims play here
	queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("Player_attack"):
		area.get_parent().queue_free()
		explode(explosionTimer)
	elif area.get_parent().is_in_group("Player"):
		explode(damageOnExplosion)

func _on_explosion_radius_body_entered(body: Node2D) -> void:
	if body.get_parent().is_in_group("Player"):
		body.takeDmg()

func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		explode(damageOnExplosion)
