extends CharacterBody2D

var screen_size

signal death_signal

#region Player Variables
@export_group("Player Variables")

@export_subgroup("General")
@export var health = 6
@export var healthText : Label
@export var hp_bar : ProgressBar
@export var slamCDBar : ProgressBar

@onready var deathFX : CPUParticles2D = $DeathFX

@export_subgroup("Player Movement")
@export var speed : float = 400
@export var dash_speed : float = 20000
@export var dash_dur : float = 0.25
@export var dash_cd : float = 0.5

@export_subgroup("Attack Details")
@export var laser_speed : float = 300
@export var bulletHolder : Node
@export var bullet_cd : float
@export var slam_cd : float = 3.00
#endregion

#region State Variables
var canDash : bool = true
var dashing : bool = false
var last_dir :  = Vector2.LEFT
var isReloading : bool = false
var slamCDon : bool = false
#endregion

#region GFX stuff
var charRightSprite = preload("res://GFX/Player Character/Phigthing Character Rendition 2 Flipped.png")
var charLeftSprite = preload("res://GFX/Player Character/Phighting Character Rendition 2.png")
var charTopFrontSprite = preload("res://GFX/Player Character/Phighting Character Top Front.png")
var charTopDownSprite = preload("res://GFX/Player Character/Phighting Top Down Back.png")
#endregion

#region Scenes to deal with
var laserAttack : Resource = preload("res://Scenes/LaserAttack.tscn")
var slamAttack : Resource = preload("res://Scenes/Slam.tscn")
var dilationText := preload("res://time_dilation_start_text.tscn")
#endregion

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	screen_size = get_viewport_rect().size
	healthText.text = str(health)
	
	hp_bar.init_health(health)

func _physics_process(delta: float) -> void:
	var dir = basic_movement()
	move_and_slide()
	handle_combat()
	dash(dir)

func handle_combat() -> void:
	if Input.is_action_pressed("Fire") and not dashing and not isReloading:
		var bullet : Node2D = laserAttack.instantiate()
		bulletHolder.add_child(bullet)
		bullet.global_position = position
		
		bullet.velocity = laser_speed*last_dir
		isReloading = true
		await get_tree().create_timer(bullet_cd).timeout
		isReloading = false
	
	if Input.is_action_pressed("Slam") and not slamCDon:
		var slam_box : Node2D = slamAttack.instantiate()
		slam_box.position = position
		get_parent().add_child(slam_box)
		slam_box.position.x += last_dir.x*150
		
		slamCDBar.init_time(slam_cd)
		
		if last_dir.x > 0:
			slam_box.get_child(0).get_child(0).disabled = false
			slam_box.get_node("HurtBox").get_node("LeftColl").disabled = true
			slam_box.get_node("Sprite2D").flip_h = false
		else:
			slam_box.get_child(0).get_child(0).disabled = true
			slam_box.get_node("HurtBox").get_node("LeftColl").disabled = false
			slam_box.get_node("Sprite2D").flip_h = true
		
		slamCDon = true
		await get_tree().create_timer(slam_cd).timeout
		slamCDon = false

func basic_movement() -> Vector2:
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if not dashing:
		velocity = input_direction * speed
	
	if input_direction.x > 0:
		$Sprite2D.texture = charRightSprite
	elif input_direction.x < 0:
		$Sprite2D.texture = charLeftSprite
	else:
		$AnimationPlayer.play("Idle")
	
	if not input_direction == Vector2.ZERO:
		last_dir = input_direction
	
	if input_direction == Vector2.ZERO:
		velocity.x = lerp(velocity.x, 0.0, 0.1)
		velocity.y = lerp(velocity.y, 0.0, 0.1)
	
	return input_direction

func dash(dir : Vector2) -> void:
	if Input.is_action_pressed("dash") and canDash:
		velocity = dir * dash_speed
		
		canDash = false
		
		var ghostSprite = Sprite2D.new()
		
		ghostSprite.texture = $Sprite2D.texture
		ghostSprite.position = position
		
		get_parent().add_child(ghostSprite)
		ghostSprite.set_modulate(Color8(145, 100, 244, 201))
		ghostSprite.scale.x = 0.6
		ghostSprite.scale.y = 0.6
		
		var ghostTween = get_tree().create_tween()
		ghostTween.tween_property(ghostSprite, "modulate:a", 0, 0.6)
		ghostTween.finished.connect(ghostSprite.queue_free)
		
		dashing = true
		await get_tree().create_timer(dash_dur).timeout
		dashing = false
		
		await get_tree().create_timer(dash_cd).timeout
		canDash = true

func takeDmg(dmg : int) -> void:
	health -= dmg
	healthText.text = str(health)
	
	print(health)
	
	if health == 1:
		timeDilation()
	
	if health == 0:
		Engine.time_scale = 1
		#STUFF

func _on_hurt_box_area_entered(area: Area2D) -> void:
	set_health(-1)

func set_health(valChange) -> void:
	health += valChange
	if hp_bar:
		hp_bar.set_hp(health)
	
	if health == 1:
		timeDilation()
	
	if health <= 0:
		Engine.time_scale = 1
		deathScreenAndStuff()

func timeDilation() -> void:
	Engine.time_scale = 0.2
	var dilationTextInstance : Label = dilationText.instantiate()
	dilationTextInstance.process_mode = Node.PROCESS_MODE_ALWAYS
	$"../CanvasLayer".add_child(dilationTextInstance)
	
	get_tree().paused = true
	await get_tree().create_timer(dilationTextInstance.getTypeTime()).timeout
	get_tree().paused = false
	
	#await get_tree().create_timer(1.25).timeout
	#
	#get_tree().paused = false
	#
	speed *= 5
	dash_speed *= 5
	bullet_cd /= 5
	dash_cd /= 5
	dash_dur /= 5
	
	await get_tree().create_timer(5, true, false, true).timeout
	speed /= 5
	dash_speed /= 5
	bullet_cd *= 5
	dash_cd *= 5
	dash_dur *= 5
	Engine.time_scale = 1

func deathScreenAndStuff() -> void:
	deathFX.emitting = true
	death_signal.emit()
	$Sprite2D.hide()
