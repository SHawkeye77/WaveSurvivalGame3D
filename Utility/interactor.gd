extends Area3D

class_name Interactor

var controller: Node3D

func interact(interactable: Interactable) -> void:
	interactable.interacted.emit(self)

func focus(interactable: Interactable) -> void:
	interactable.focused.emit(self)

func unfocus(interactable: Interactable) -> void:
	interactable.unfocused.emit(self)

# Returns the closest overlapping interactable or null if there isn't one
func getClosestInteractable() -> Interactable:
	var list: Array[Area3D] = get_overlapping_areas()
	var distance: float
	var closest_distance: float = INF
	var closest: Interactable = null
	
	for interactable in list:
		distance = interactable.global_position.distance_to(global_position)
		
		# Sets the first interactable in the list as closest
		if distance < closest_distance:
			closest = interactable as Interactable
			closest_distance = distance
	
	return closest
