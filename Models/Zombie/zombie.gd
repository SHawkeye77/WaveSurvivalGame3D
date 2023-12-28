extends CharacterBody3D

@onready var player = get_tree().get_first_node_in_group("player")
@onready var wavesSpawner = get_tree().get_first_node_in_group("WaveSpawner")
@onready var navAgent = get_node("%NavigationAgent3D")
@onready var animationTree = get_node("%AnimationTree")
@onready var zombieGroanAudio = get_node("%ZombieGroanAudio")
@onready var zombieGroanTimer = get_node("%ZombieGroanTimer")
var stateMachine = null  # Used to get current animation state of the zombie
var health = -1
var brains = -1
var damage = -1
var speed = -1

func _ready():
	stateMachine = animationTree.get("parameters/playback")
	zombieGroanTimer.wait_time = randi_range(Global.ZOMBIE_GROAN_TIMER_MIN, Global.ZOMBIE_GROAN_TIMER_MAX)
	zombieGroanTimer.start()

func _process(delta):
	velocity = Vector3.ZERO
	
	# Animations and navigation
	match stateMachine.get_current_node():
		"Run":
			# Navigation
			navAgent.set_target_position(player.global_position)
			var nextNavPoint = navAgent.get_next_path_position()
			velocity = (nextNavPoint - global_position).normalized() * speed
			# Looking towards direction of player
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * Global.ZOMBIE_TURNING_SPEED)
		"Attack":
			# Looking in direction of player
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)

	# Changing conditions for animations
	animationTree.set("parameters/conditions/zombieAttack", targetInRange())
	animationTree.set("parameters/conditions/zombieRun", !targetInRange())

	move_and_slide()

func setScale(s):
	scale = Vector3(s, s, s)

# Returns boolean if the player is in the attack range of the zombie
func targetInRange():
	return global_position.distance_to(player.global_position) < Global.ZOMBIE_ATTACK_RANGE

# Triggered when arm of zombie is extended in Attack animation
func hitFinished():
	if global_position.distance_to(player.global_position) < Global.ZOMBIE_ATTACK_RANGE + Global.ZOMBIE_ATTACK_RANGE_BUFFER:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir, damage)

func _on_area_3d_body_part_hit(dam):
	health -= dam
	if health <= 0:
		death()

func death():
	wavesSpawner.enemyDied(self)
	animationTree.set("parameters/conditions/zombieDie", true)  # Triggering the death animation
	player.zombieDeath(brains)
	await get_tree().create_timer(4.5).timeout
	queue_free()

func _on_zombie_groan_timer_timeout():
	zombieGroanAudio.play()
	zombieGroanTimer.wait_time = randi_range(Global.ZOMBIE_GROAN_TIMER_MIN, Global.ZOMBIE_GROAN_TIMER_MAX)
	zombieGroanTimer.start()
