extends Interactor

@onready var player = get_tree().get_first_node_in_group("player")
var cachedClosest: Interactable

func _physics_process(delta):
	var newClosest: Interactable = getClosestInteractable()
	if newClosest != cachedClosest:
		if is_instance_valid(cachedClosest):
			unfocus(cachedClosest)
		if newClosest:
			focus(newClosest)
		cachedClosest = newClosest

func _input(event):
	if event.is_action_pressed("interact"):
		if cachedClosest:
			interact(cachedClosest)

func _on_area_exited(area):
	if cachedClosest == area:
		unfocus(area)
