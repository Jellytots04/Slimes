class_name Avoidance extends SteeringBehavior

@export var avoidance_radius: float = 20.0
@export var urgency_multiplier = 2.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boid = get_parent().get_parent()

func calculate() -> Vector3:
	var force = Vector3.ZERO
	
	for other in boid.nearby_slimes:
		if not is_instance_valid(other):
			continue
			
		var to_other = other.global_position - boid.global_position
		to_other.y = 0
		var distance = to_other.length()
		
		if distance < 0.01:
			continue
		
		if distance > avoidance_radius:
			continue
		
		var push = -to_other.normalized() * (1.0 / distance) * boid.stats.speed * urgency_multiplier
		force += push
	# print(boid.name, " avoidance force: ", force)
	return force
