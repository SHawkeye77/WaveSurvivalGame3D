extends StaticBody3D

@onready var player = get_tree().get_first_node_in_group("player")
@onready var glowingInsideMesh = get_node("%GlowingInsideMesh")

func addHighlight():
	glowingInsideMesh.visible = true

func removeHighlight():
	glowingInsideMesh.visible = false

func _on_interactable_focused(interactor):
	addHighlight()

func _on_interactable_unfocused(interactor):
	removeHighlight()

func _on_interactable_interacted(interactor):
	player.interactWithBulletDamageUpgrade()
