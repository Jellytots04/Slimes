class_name SeekFood extends SteeringBehavior

@export var target_lost_distance: float = 25.0

var target_food: Food = null

func _ready() -> void:
	boid = get_parent().get_parent()
	
func calculate() -> Vector3:
	if target_food and not is_instance_valid(target_food):
		target_food = null
	
	# Look for a target if there is none nearby
	if not target_food:
		target_food = find_nearest_food()
	
	# If no food has been found return to zero (Slime will keep wandering)
	if not target_food:
		return Vector3.ZERO
	
	return boid.arrive_force(target_food.global_position)

func find_nearest_food() -> Node3D:
	var preference: int = boid.stats.food_preference
	var all_food = boid.get_tree().get_nodes_in_group("food")
	print("SeekFood called | food count: ", all_food.size(), " | target: ", target_food)
	
	var nearest: Food = null
	var nearest_distance = INF
	
	for food in all_food:
		if not is_instance_valid(food):
			continue
		if food.consumed:
			continue
		
		var distance: float = food.global_position.distance_to(boid.global_position)
		if preference != 0 and food.get_food_type() != preference:
			continue
		
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = food
	
	return nearest

func clear_target() -> void:
	target_food = null
