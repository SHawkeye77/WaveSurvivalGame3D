extends CharacterBody3D

@onready var world = get_tree().get_first_node_in_group("world")
@onready var waveSpawner = get_tree().get_first_node_in_group("WaveSpawner")
@onready var head = get_node("%Head")
@onready var camera = get_node("%Camera3D")
var endScreen = "res://screens/end_screen.tscn"
# UI
@onready var healthBar = get_node("%HealthBar")
var health = -1
@onready var brainsAmountLabel = get_node("%BrainsAmountLabel")
var brains = -1  # "Brains" currency tracker
@onready var waveLabel = get_node("%WaveLabel")
var wave = -1
# Mystery box
@onready var offerMysteryBoxPanel = get_node("%OfferMysteryBoxPanel")
@onready var mysteryBoxPromptLabel = get_node("%MysteryBoxPromptLabel")
@onready var mysteryBoxTimer = get_node("%MysteryBoxTimer")
# Reload speed upgrade box
@onready var offerReloadSpeedUpgradePanel = get_node("%OfferReloadSpeedUpgradePanel")
@onready var reloadSpeedUpgradePromptLabel = get_node("%ReloadSpeedUpgradePromptLabel")
var reloadTimerIndex = 0
# Bullet damage upgrade box
@onready var offerBulletDamageUpgradePanel = get_node("%OfferBulletDamageUpgradePanel")
@onready var bulletDamageUpgradePromptLabel = get_node("%BulletDamageUpgradePromptLabel")
var bulletDamageIndex = 0
# Notification Panel
@onready var notificationPanel = get_node("%NotificationPanel")
@onready var notificationLabel = get_node("%NotificationLabel")
# Movement
@onready var playerHitColorRect = get_node("%PlayerHitColorRect")
var currentSpeed = null
var tBob = 0.0  # Tracks time for head bobbing
# Bullets
var bulletScene = load("res://Models/Bullet/bullet.tscn")
var bulletInstance = null
var bulletInstance2 = null
var bulletInstance3 = null
var bulletInstance4 = null
var currentRepeaterBullet = 0
# Weapons
@onready var weaponSwitchAnimationPlayer = get_node("%WeaponSwitchAnimationPlayer")
var reloadReady = true
var currentlySwitchingWeapons = false
var currentWeapon = null
# Pistol
@onready var pistolAnimationPlayer = %Pistol/AnimationPlayer
@onready var pistolRaycast = %Pistol/RayCast3D
@onready var pistolReloadTimer = get_node("%PistolReloadTimer")
# Sniper
@onready var sniperAnimationPlayer = %Sniper/AnimationPlayer
@onready var sniperRaycast = %Sniper/RayCast3D
@onready var sniperReloadTimer = get_node("%SniperReloadTimer")
# Repeater
@onready var repeaterAnimationPlayer = %Repeater/AnimationPlayer
@onready var repeaterRaycast = %Repeater/RayCast3D
@onready var repeaterReloadTimer = get_node("%RepeaterReloadTimer")
@onready var repeaterTimeBetweenBulletsTimer = get_node("%RepeaterTimeBetweenBulletsTimer")
# Shotgun
@onready var shotgunAnimationPlayer = %Shotgun/AnimationPlayer
@onready var shotgunRaycast1 = %Shotgun/Bullet01Ray
@onready var shotgunRaycast2 = %Shotgun/Bullet02Ray
@onready var shotgunRaycast3 = %Shotgun/Bullet03Ray
@onready var shotgunRaycast4 = %Shotgun/Bullet04Ray
@onready var shotgunReloadTimer = get_node("%ShotgunReloadTimer")

# Signals
signal playerHit

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Setting up UI
	brains = Global.PLAYER_BRAINS_STARTING_AMOUNT
	health = Global.PLAYER_STARTING_HEALTH
	wave = 1
	healthBar.max_value = Global.PLAYER_STARTING_HEALTH
	updateUI()
	# Setting up weapon reloading
	updateWeaponStats()
	repeaterTimeBetweenBulletsTimer.wait_time = Global.REPEATER_TIME_BETWEEN_BULLETS
	# Setting up interactables
	mysteryBoxPromptLabel.text = "Purchase a mystery gun for " + str(Global.MYSTERY_BOX_PRICE) + " brains?"
	mysteryBoxTimer.wait_time = Global.MYSTERY_BOX_WAIT_TIME
	reloadSpeedUpgradePromptLabel.text = "Purchase a reload speed upgrade for " + str(Global.RELOAD_SPEED_UPGRADE_PRICE) + " brains?"
	bulletDamageUpgradePromptLabel.text = "Purchase a bullet damage upgrade for " + str(Global.BULLET_DAMAGE_UPGRADE_PRICE) + " brains?"
	# Setting up the initial weapon
	await get_tree().create_timer(1.0).timeout  # Otherwise we run into some errors
	currentWeapon = Global.WEAPON_STARTING
	raiseWeapon()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * Global.UI_SENSITIVITY)
		camera.rotate_x(-event.relative.y * Global.UI_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(Global.UI_VERTICAL_ROTATION_MIN), deg_to_rad(Global.UI_VERTICAL_ROTATION_MAX))

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= Global.WORLD_GRAVITY * delta
	
	# Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = Global.PLAYER_JUMP_VELOCITY
	
	# Sprinting
	if Input.is_action_pressed("sprint"):
		currentSpeed = Global.PLAYER_SPRINT_SPEED
	else:
		currentSpeed = Global.PLAYER_WALK_SPEED
	
	# Movement/deceleration
	var inputDir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(inputDir.x, 0, inputDir.y)).normalized()
	# On the ground, give player total control over movement
	if is_on_floor():
		if direction:
			velocity.x = direction.x * currentSpeed
			velocity.z = direction.z * currentSpeed
		else:
			velocity.x = lerp(velocity.x, direction.x * currentSpeed, delta * Global.PLAYER_GROUND_FRICTION)
			velocity.z = lerp(velocity.z, direction.z * currentSpeed, delta * Global.PLAYER_GROUND_FRICTION)
	# Apply inertia when in the air
	else:
		velocity.x = lerp(velocity.x, direction.x * currentSpeed, delta * Global.PLAYER_INERTIA)
		velocity.z = lerp(velocity.z, direction.z * currentSpeed, delta * Global.PLAYER_INERTIA)
	
	# Head bob
	tBob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(tBob)
	
	# Field of view
	var velocityClamped = clamp(velocity.length(), 0.5, Global.PLAYER_SPRINT_SPEED * 2.0)
	var targetFOV = Global.PLAYER_BASE_FOV + Global.PLAYER_FOV_CHANGE * velocityClamped
	camera.fov = lerp(camera.fov, targetFOV, delta * 8.0)

	# Shooting
	if Input.is_action_pressed("shoot"):
		if reloadReady and !currentlySwitchingWeapons:
			if currentWeapon == Global.WEAPONS.PISTOL:
				shootPistol()
			elif currentWeapon == Global.WEAPONS.REPEATER:
				shootRepeater()
			elif currentWeapon == Global.WEAPONS.SNIPER:
				shootSniper()
			elif currentWeapon == Global.WEAPONS.SHOTGUN:
				shootShotgun()
			else:
				print("ERROR: Shooting unknown weapon")

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * Global.PLAYER_BOB_FREQUENCY) * Global.PLAYER_BOB_AMPLITUDE
	pos.x = cos(time * Global.PLAYER_BOB_FREQUENCY / 2) * Global.PLAYER_BOB_AMPLITUDE
	return pos

# Hit by enemy
func hit(dir, dam):
	# Taking damage
	world.playPlayerHurtAudio()
	health -= dam
	if health <= 0:
		gameOver()
	updateUI()
	# Flashing red on screen to indicate hit
	playerHitColorRect.visible = true
	await get_tree().create_timer(Global.UI_HIT_FLASH_EFFECT).timeout
	playerHitColorRect.visible = false
	# Moving in the direction of the hit
	velocity += dir * Global.PLAYER_HIT_STAGGER

# Shooting the pistol weapon
func shootPistol():
	# Playing the animation and sound
	pistolAnimationPlayer.play("PistolShoot")
	world.playPistolShotAudio()
	# Shooting the bullet
	bulletInstance = bulletScene.instantiate()
	bulletInstance.damage = Global.PISTOL_DAMAGE[bulletDamageIndex]
	bulletInstance.position = pistolRaycast.global_position
	bulletInstance.transform.basis = pistolRaycast.global_transform.basis
	get_parent().add_child(bulletInstance)
	# Waiting for reload
	reloadReady = false
	pistolReloadTimer.start()

# Shooting the repeater weapon
func shootRepeater():
	reloadReady = false
	# Just play the repeater audio once
	if currentRepeaterBullet == 0:
		world.playRepeaterShotAudio()
	# If more bullets left in cycle, shoot one bullet
	if currentRepeaterBullet < Global.REPEATER_BULLETS_PER_CYCLE:
		# Playing the animation
		repeaterAnimationPlayer.play("RepeaterShoot")
		# Shooting the bullet
		bulletInstance = bulletScene.instantiate()
		bulletInstance.damage = Global.REPEATER_DAMAGE[bulletDamageIndex]
		bulletInstance.position = repeaterRaycast.global_position
		bulletInstance.transform.basis = repeaterRaycast.global_transform.basis
		get_parent().add_child(bulletInstance)
		currentRepeaterBullet += 1
		repeaterTimeBetweenBulletsTimer.start()
	# Out of bullets on this cycle
	else:
		currentRepeaterBullet = 0
		repeaterReloadTimer.start()

func shootSniper():
	# Playing the animation
	sniperAnimationPlayer.play("SniperShoot")
	world.playSniperShotAudio()
	# Shooting the bullet
	bulletInstance = bulletScene.instantiate()
	bulletInstance.damage = Global.SNIPER_DAMAGE[bulletDamageIndex]
	bulletInstance.position = sniperRaycast.global_position
	bulletInstance.transform.basis = sniperRaycast.global_transform.basis
	get_parent().add_child(bulletInstance)
	# Waiting for reload
	reloadReady = false
	sniperReloadTimer.start()

func shootShotgun():
	# Playing the animation
	shotgunAnimationPlayer.play("ShotgunShoot")
	world.playShotgunShotAudio()
	# Shooting the bullets
	# 1
	bulletInstance = bulletScene.instantiate()
	bulletInstance.damage = Global.SHOTGUN_DAMAGE[bulletDamageIndex]
	bulletInstance.position = shotgunRaycast1.global_position
	bulletInstance.transform.basis = shotgunRaycast1.global_transform.basis
	get_parent().add_child(bulletInstance)
	# 2
	bulletInstance2 = bulletScene.instantiate()
	bulletInstance2.damage = Global.SHOTGUN_DAMAGE[bulletDamageIndex]
	bulletInstance2.position = shotgunRaycast2.global_position
	bulletInstance2.transform.basis = shotgunRaycast2.global_transform.basis
	get_parent().add_child(bulletInstance2)
	# 3
	bulletInstance3 = bulletScene.instantiate()
	bulletInstance3.damage = Global.SHOTGUN_DAMAGE[bulletDamageIndex]
	bulletInstance3.position = shotgunRaycast3.global_position
	bulletInstance3.transform.basis = shotgunRaycast3.global_transform.basis
	get_parent().add_child(bulletInstance3)
	# 4
	bulletInstance4 = bulletScene.instantiate()
	bulletInstance4.damage = Global.SHOTGUN_DAMAGE[bulletDamageIndex]
	bulletInstance4.position = shotgunRaycast4.global_position
	bulletInstance4.transform.basis = shotgunRaycast4.global_transform.basis
	get_parent().add_child(bulletInstance4)
	# Waiting for reload
	reloadReady = false
	shotgunReloadTimer.start()

# Plays the animation to lower the current weapon
func lowerCurrentWeapon():
	currentlySwitchingWeapons = true
	if currentWeapon == Global.WEAPONS.PISTOL:
		weaponSwitchAnimationPlayer.play("LowerPistol")
	elif currentWeapon == Global.WEAPONS.REPEATER:
		weaponSwitchAnimationPlayer.play("LowerRepeater")
	elif currentWeapon == Global.WEAPONS.SNIPER:
		weaponSwitchAnimationPlayer.play("LowerSniper")
	elif currentWeapon == Global.WEAPONS.SHOTGUN:
		weaponSwitchAnimationPlayer.play("LowerShotgun")
	else:
		print("ERROR: Lowering unknown weapon")

# Raises the "current" weapon
func raiseWeapon():
	# Play the associated equip sound
	world.playGunEquipAudio()
	# Raise the new weapon
	if currentWeapon == Global.WEAPONS.PISTOL:
		weaponSwitchAnimationPlayer.play_backwards("LowerPistol")
	elif currentWeapon == Global.WEAPONS.REPEATER:
		weaponSwitchAnimationPlayer.play_backwards("LowerRepeater")
	elif currentWeapon == Global.WEAPONS.SNIPER:
		weaponSwitchAnimationPlayer.play_backwards("LowerSniper")
	elif currentWeapon == Global.WEAPONS.SHOTGUN:
		weaponSwitchAnimationPlayer.play_backwards("LowerShotgun")
	else:
		print("ERROR: Raising unknown weapon")
	await get_tree().create_timer(0.3).timeout
	currentlySwitchingWeapons = false

func zombieDeath(b):
	brains += b
	updateUI()

### Mystery box ###
func interactWithMysteryBox():
	if !currentlySwitchingWeapons:
		# If could buy it, offer it
		if brains >= Global.MYSTERY_BOX_PRICE:
			offerMysteryBoxPanel.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
		# If can't buy it, let them know
		else:
			notifyPlayer("Not enough brains to purchase mystery box (requires " + str(Global.MYSTERY_BOX_PRICE) + ")")
func _on_yes_purchase_mystery_box_button_pressed():
	offerMysteryBoxPanel.visible = false
	brains -= Global.MYSTERY_BOX_PRICE
	updateUI()
	lowerCurrentWeapon()
	mysteryBoxTimer.start()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	world.playMysteryBoxAudio()
	get_tree().paused = false
func _on_mystery_box_timer_timeout():
	# Selecting a random weapon, updating in logs what our new weapon is, then raising it
	var randomWeapon = Global.WEAPONS.values()[randi() % Global.WEAPONS.size()]
	currentWeapon = randomWeapon
	raiseWeapon()
func _on_no_purchase_mystery_box_button_pressed():
	world.playInteractionAudio()
	offerMysteryBoxPanel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

### Reload speed upgrade ###
func interactWithReloadSpeedUpgrade():
	# If already fully upgraded, let them know
	if reloadTimerIndex >= len(Global.PISTOL_RELOAD_TIMERS) - 1: # Arbitrarily checking pistol
		notifyPlayer("Reload speed already at max!")
	# If could buy it, offer it
	elif brains >= Global.RELOAD_SPEED_UPGRADE_PRICE:
		offerReloadSpeedUpgradePanel.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true
	# If can't buy it, let them know
	else:
		notifyPlayer("Not enough brains to purchase reload speed upgrade (requires " + str(Global.RELOAD_SPEED_UPGRADE_PRICE) + ")")
func _on_yes_purchase_reload_speed_upgrade_button_pressed():
	offerReloadSpeedUpgradePanel.visible = false
	brains -= Global.RELOAD_SPEED_UPGRADE_PRICE
	updateUI()
	reloadTimerIndex += 1
	updateWeaponStats()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	world.playReloadSpeedUpgradeAudio()
	get_tree().paused = false
func _on_no_purchase_reload_speed_upgrade_button_pressed():
	world.playInteractionAudio()
	offerReloadSpeedUpgradePanel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

### Bullet Damage Upgrade ###
func interactWithBulletDamageUpgrade():
	# If already fully upgraded, let them know
	if bulletDamageIndex >= len(Global.PISTOL_DAMAGE) - 1: # Arbitrarily checking pistol
		notifyPlayer("Bullet damage already at max!")
	# If could buy it, offer it
	elif brains >= Global.BULLET_DAMAGE_UPGRADE_PRICE:
		offerBulletDamageUpgradePanel.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true
	# If can't buy it, let them know
	else:
		notifyPlayer("Not enough brains to purchase bullet damage upgrade (requires " + str(Global.BULLET_DAMAGE_UPGRADE_PRICE) + ")")
func _on_yes_purchase_bullet_damage_upgrade_button_pressed():
	offerBulletDamageUpgradePanel.visible = false
	brains -= Global.BULLET_DAMAGE_UPGRADE_PRICE
	updateUI()
	bulletDamageIndex += 1
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	world.playBulletDamageUpgradeAudio()
	get_tree().paused = false
func _on_no_purchase_bullet_damage_upgrade_button_pressed():
	world.playInteractionAudio()
	offerBulletDamageUpgradePanel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

# Notification system
func notifyPlayer(notificationText):
	notificationPanel.visible = true
	notificationLabel.text = notificationText
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
func _on_notification_acknowledgement_button_pressed():
	world.playInteractionAudio()
	notificationPanel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

### Reload timers ###
func _on_sniper_reload_timer_timeout():
	reloadReady = true
func _on_pistol_reload_timer_timeout():
	reloadReady = true
func _on_repeater_reload_timer_timeout():
	reloadReady = true
func _on_shotgun_time_between_bullets_timer_timeout():
	reloadReady = true

func _on_repeater_time_between_bullets_timer_timeout():
	shootRepeater()

func updateWeaponStats():
	pistolReloadTimer.wait_time = Global.PISTOL_RELOAD_TIMERS[reloadTimerIndex]
	repeaterReloadTimer.wait_time = Global.REPEATER_RELOAD_TIMERS[reloadTimerIndex]
	sniperReloadTimer.wait_time = Global.SNIPER_RELOAD_TIMERS[reloadTimerIndex]
	shotgunReloadTimer.wait_time = Global.SHOTGUN_RELOAD_TIMERS[reloadTimerIndex]

func updateUI():
	healthBar.value = health
	brainsAmountLabel.text = str(brains)
	waveLabel.text = "Wave: " + str(wave)

func gameOver():
	Global.finalWave = wave
	var _level = get_tree().change_scene_to_file(endScreen)
