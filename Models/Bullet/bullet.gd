extends Node3D

@onready var mesh = get_node("%BulletMesh")
@onready var raycast = get_node("%BulletRayCast")
@onready var particleEmission = get_node("%ParticleEmission")
@onready var bulletAutomaticDespawnTimer = get_node("%BulletAutomaticDespawnTimer")
var damage = -1

func _ready():
	bulletAutomaticDespawnTimer.wait_time = Global.BULLET_AUTOMATIC_DESPAWN_TIMER
	bulletAutomaticDespawnTimer.start()

func _process(delta):
	# Moving the bullet forward
	position += transform.basis * Vector3(0, 0, -Global.BULLET_SPEED) * delta
	# Checking for collision
	if raycast.is_colliding():
		mesh.visible = false  # Remove the bullet visibly
		particleEmission.emitting = true  # Emit the "hit" particles
		raycast.enabled = false
		# Checking if we hit an enemy with the bullet
		if raycast.get_collider().is_in_group("enemy"):
			raycast.get_collider().zombieBodyPartHit(damage)

		await get_tree().create_timer(1.0).timeout
		queue_free()

func _on_bullet_automatic_despawn_timer_timeout():
	queue_free()
