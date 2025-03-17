extends CharacterBody2D

#TODO: When you add the animations, make all attacks WAIT for it finish using signals, then start. that should be good i hope.
#3/15/25 This is so godsbedamned fucking frustrating 

var global_delta : float
var playerDist
var bossMapSizeX : float
var bossMapSizeY : float

#State Variables
var battleStarted : bool = false
var inAttack : bool = false
var canStartDialog : bool = false

var playerIsClose : bool
var playerIsModerate : bool
var playerIsFar : bool

var lines : Array[String] = [
	"TOODLE MCDOODLE",
	"SINE AND COSINE BEST GIRLS",
	"I LIKE d^2x/dt^2 = (k/m)x!!!!"
]

#region General Variables
@export_category("General Variables")
@export var hp : float = 100
@export var hp_bar : ProgressBar
@export var player : CharacterBody2D 

@export var roomCorner1 : Marker2D
@export var roomCorner2 : Marker2D
#endregion

@export_category("Attack Variables")
#region Dive Attack Variables
@export_subgroup("Dive Attack Variables")
@export var soar_height : float = 100
@export var soar_time : float = 0.5
@export var dive_time : float = 0.25

const diveColStayTime : float = 1
#endregion

#region Bomb Splatter Attack Variables
@export_subgroup("Bomb Splatter Attack Variables")
@export var bombSplatterCount : float = 15
@export var bombSplatterInBTW : float = 0.05
@export var bombSplatterC1 : Marker2D
@export var bombSplatterC2 : Marker2D

var splatterBomb = preload("res://Scenes/SplatterBomb.tscn")
#endregion

#region Close Up Swipe Attack Variables
@export_subgroup("Close Up Swipe Attack Variables")
@export var closeUpSpeed : float = 0.1
@export var min_distance : float = 200
@export var dashSpeed : float = 100

var tempPlayerPos : Vector2

var closeUpActive : bool
var atTempPlayerPos : bool
#endregion

#region Map Partitioner Attack Variables
@export_subgroup("Map Partitioner Attack Variables")
@export var partMidPointWalkSpeed : float = 100
@export var MapPartiRotateTime : float = 5
@export var bossMapMidPoint : Marker2D
@export var angularVel : float = 0.05 #Radians, actually.

var canRotate = false
var partiColli : Area2D
var mapPartiActive : bool
var atMid : bool 
#endregion

#region Close Range Bombing Attack Variables
@export_subgroup("Close Range Bombing Attack Variables")
@export var bombingMaxSize : float = 500
var closeRangeArea : Area2D
#endregion

#region Staying Still Variables
@export_subgroup("Stay Still Time")
@export var stayStillTime : float = 3
#endregion

func _ready() -> void:
	hp_bar.init_health(hp)
	partiColli = $PartitionerCollision
	closeRangeArea = $CloseRangeBombing
	closeRangeArea.get_child(0).set_deferred("disabled", true)
	for colli in partiColli.get_children():
		colli.set_deferred("disabled", true)
	
	bossMapSizeX = abs(roomCorner2.position.x - roomCorner1.position.x)
	bossMapSizeY = abs(roomCorner2.position.y - roomCorner1.position.y)
	
	$TriangularSwipe/CollisionPolygon2D.disabled = true
	
	battleStarted = true

func diveBomb() -> void:
	inAttack = true
	
	var sprite = $Sprite2D
	var dive_pos = player.position
	var dive : Tween = get_tree().create_tween()
	dive.tween_property($".", "position", Vector2(position.x, -soar_height), soar_time).set_trans(Tween.TRANS_QUAD)
	dive.tween_property($".", "position", player.position, dive_time).set_trans(Tween.TRANS_EXPO)
	$DiveAttackArea/CollisionShape2D.set_deferred("disabled", false)
	await get_tree().create_timer(diveColStayTime).timeout
	$DiveAttackArea/CollisionShape2D.set_deferred("disabled", true)
	
	inAttack = false

func bombSplatter() -> void:
	inAttack = true
	await get_tree().create_timer(0.3).timeout
	
	#region Splatter Corners
	var max_X = bombSplatterC1.position.x
	var min_X = bombSplatterC2.position.x
	
	var max_Y = bombSplatterC2.position.x
	var min_Y = bombSplatterC1.position.x
	#endregion
	
	#Setting this variable up in case I need it
	var bombLocations : Array 
	
	for i in range(bombSplatterCount):
		var bomb = splatterBomb.instantiate()
		get_parent().add_child(bomb)
		bomb.position = Vector2(
			randf_range(min_X, max_X),
			randf_range(min_Y, max_Y)
		)
		bombLocations.append(bomb)
		await get_tree().create_timer(bombSplatterInBTW).timeout
	
	inAttack = false

func closeUpSwipe() -> void:
	inAttack = true
	closeUpActive = true
	
	var playerRelDir = (tempPlayerPos - position).normalized()
	var playerPos = tempPlayerPos
	#var posTweener : Tween = get_tree().create_tween()
	var swipeTime = calcSwipeTime(position.distance_to(playerPos))
	
	if position.distance_to(tempPlayerPos) > min_distance:
		
		position += playerRelDir * closeUpSpeed
	else:
		print("g")
		atTempPlayerPos = true
		$TriangularSwipe.look_at(player.position)
		$TriangularSwipe/CollisionPolygon2D.set_deferred("disabled", false)
		$TriangularSwipe/Sprite2D.visible = true
		
		await get_tree().create_timer(0.6).timeout
		
		$TriangularSwipe/CollisionPolygon2D.set_deferred("disabled", true)
		$TriangularSwipe/Sprite2D.visible = false
		
		closeUpActive = false
		await get_tree().create_timer(2).timeout
		inAttack = false

#Split this method into 2: One that runs in update to get to the position, and one that starts the map partitioner
func mapPartitioner() -> void:
	var midLoc = bossMapMidPoint.position
	var targetDir = (midLoc - position).normalized()
	atMid = false
	inAttack = true 
	mapPartiActive = true
	
	mapPartiStageOne()
	
	if position.distance_to(midLoc) < 10:
		print("hi")
		await get_tree().create_timer(.2).timeout
		for colli in partiColli.get_children():
			colli.set_deferred("disabled", false)
		
		mapPartiStageTwo()
		
		for colli in partiColli.get_children():
			colli.set_deferred("disabled", true)
		inAttack = false
		
	#Rotation Initiation (Main Attack)
	#if atMid:
		#canRotate = true
		#await get_tree().create_timer(0.2).timeout
		#for colli in partiColli.get_children():
			#colli.set_deferred("disabled", false)
		##var rotateTween = get_tree().create_tween()
		##rotateTween.tween_property(partiColli, "rotation", 4*PI, MapPartiRotateTime).set_trans(Tween.TRANS_LINEAR).as_relative()
		#
		#partiColli.rotate(angularVel)
		#await get_tree().create_timer(MapPartiRotateTime).timeout
		#canRotate = false
		##print(canRotate)
		#for colli in partiColli.get_children():
			#colli.set_deferred("disabled", true)
		#
		#mapPartiActive = false
		#inAttack = false

func mapPartiStageOne() -> void:
	var moveTween = get_tree().create_tween()
	moveTween.tween_property($".", "position", bossMapMidPoint.position, 3)

func mapPartiStageTwo() -> void:
	var rotateTween = get_tree().create_tween()
	rotateTween.tween_property(partiColli, "rotation", 5*PI, 3)

func closeRangeBombing() -> void:
	var bombingColl = closeRangeArea.get_child(0)
	var playerPos = player.position
	inAttack = true
	
	$CloseRangeBombing/Sprite2D.visible = true
	bombingColl.set_deferred("disabled", false)
	closeRangeArea.look_at(playerPos)
	
	await get_tree().create_timer(1.5).timeout
	$CloseRangeBombing/Sprite2D.visible = false
	bombingColl.set_deferred("disabled", true)
	inAttack = false

func stayStill() -> void:
	inAttack = true
	await get_tree().create_timer(3).timeout
	inAttack = false

func _physics_process(delta: float) -> void:
	playerDist = position.distance_to(player.position)
	
	$AnimationPlayer.play("Float_Idle")
	global_delta = delta
	
	if player.position.x - position.x < 0:
		$Sprite2D.flip_h = true
	else:
		$Sprite2D.flip_h = false
	#Logic Loop
	#if battleStarted:
		#dive_bomb()
	
	if playerDist < bossMapSizeX/4:
		playerIsClose = true
		playerIsModerate = false
		playerIsFar = false
	elif playerDist < bossMapSizeX/2:
		playerIsClose = false
		playerIsModerate = true
		playerIsFar = false
	else:
		playerIsClose = false
		playerIsModerate = false
		playerIsFar = true
	
	#Close Range - Viable Options - Close Range bombing, Close Up Swipe, Dive Bomb
	#Moderate Range - Viable Options - Dive Bomb, Close Up Swipe, Map Partitioner, Bomb Splatter
	#Long Range - Viable options - Dive Bomb, Bomb Splatter, Map Partitioner, Reducing Distance to player (shift to go to moderate range) 
	#Staying still - possible at all ranges
	
	var attackDice : int

	if closeUpActive and not atTempPlayerPos:
		closeUpSwipe()
	#if mapPartiActive:
		#if position.distance_to(bossMapMidPoint.position) > 10:
			#velocity = (bossMapMidPoint.position - position).normalized() * partMidPointWalkSpeed
		#else: 
			#velocity = Vector2.ZERO
			#atMid = true
	elif not inAttack and battleStarted:
		#print(Time.get_datetime_string_from_system())
		if playerIsClose:
			attackDice = randi_range(1,4)
			
			match attackDice:
				1: closeRangeBombing(); print("Close Range Bombing")
				2: diveBomb(); print("Dive Bomb")
				3: closeUpSwipe(); print("Close Up Swipe")
				4: stayStill(); print("Staying Still")
		
		elif playerIsModerate:
			attackDice = randi_range(1,4)
			
			match attackDice:
				1: diveBomb(); print("Dive Bomb")
				2: closeUpSwipe(); print("Close Up Swipe"); tempPlayerPos = player.position; atTempPlayerPos = false
				#3: mapPartitioner(); print("Map Partitioner")
				3: bombSplatter(); print("Bomb Splatter")
				4: stayStill(); print("Staying Still")
		
		elif playerIsFar:
			attackDice = randi_range(1,5)
			
			match attackDice:
				1: diveBomb(); print("Dive Bomb")
				2: bombSplatter(); print("Bomb Splatter")
				#3: mapPartitioner(); print("Map Partitioner")
				3: pass #Work on a function to close up to moderate range
				4: stayStill(); print("Staying Still")
	
	handleDialog()
	move_and_slide()

func set_health(valChange) -> void:
	hp += valChange
	hp_bar.set_hp(hp)
	
	if hp <= 0:
		queue_free()

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("Player_attack") and area.get_parent().is_in_group("AreaEffect"):
		#for child in area.get_parent().get_node("HurtBox").get_children():
			#child.set_deferred("disabled", true)
		set_health(-8)
	
	elif area.get_parent().is_in_group("Player_attack"):
		set_health(-1)
		area.get_parent().queue_free()

func calcSwipeTime(playerDist) -> float:
	#Ok, how will I work this out? There are two problems: One if shes too close. If so, she doesn't need 2 seconds to get to the player!
	#Two, two seconds is a dastardly long amount of time! I need something (IF shes at a moderate or far range) that will give me a
	#generalized amount of time between 1-2 seconds. It's obviously a function of player distance.
	#Ok. So... let's figure this out. Try 1: Very rudimentary solution.
	
	var workAroundDist = playerDist
	workAroundDist = workAroundDist/1000*2
	return workAroundDist

func handleDialog() -> void:
	if canStartDialog and Input.is_action_pressed("Advance_Dialog"):
		canStartDialog = false
		DialogManager.startDialog(global_position, lines)

func DialogAreaEntered(area: Area2D) -> void:
	canStartDialog = true
	$DialogStartArea.queue_free()
