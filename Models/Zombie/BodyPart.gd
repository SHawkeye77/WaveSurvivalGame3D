extends Area3D

@export var isHead := false

signal bodyPartHit(dam)

func zombieBodyPartHit(bulletDamage):
	if isHead:
		emit_signal("bodyPartHit", bulletDamage * Global.BULLET_HEADSHOT_MULTIPLIER)
	else:
		emit_signal("bodyPartHit", bulletDamage)
