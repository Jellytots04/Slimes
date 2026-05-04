class_name Flocking extends SteeringBehavior

@export var separation_radius: float = 2.0
@export var alignment_radius: float = 5.0
@export var cohesion_radius: float = 5.0

@export var separation_weight: float = 2.0
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boid = get_parent().get_parent()

func calculate() -> Vector3:
	var separation = Vector3.ZERO
	var alignment = Vector3.ZERO
	var cohesion_centre = Vector3.ZERO
	
	var sep_count = 0
	var align_count = 0
	var coh_count = 0
	
	for other in boid.nearby_slimes:
		if not is_instance_valid(other):
			continue

		var offset = other.global_position - boid.global_position
		offset.y = 0
		var distance = offset.length()
		
		if distance < 0.01:
			continue
		
		# Separation: Push away from neighbours
		if distance < separation_radius:
			separation -= offset.normalized() / distance
			sep_count += 1
			
		# Alignment: Average velocity of the nearby slimes
		if distance < alignment_radius:
			alignment += other.velocity
			align_count += 1
		
		# Cohesion: Average position of nearby slimes
		if distance < cohesion_radius:
			cohesion_centre += other.global_position
			coh_count += 1
	
	var separation_force = Vector3.ZERO
	if sep_count > 0:
		separation_force = (separation / sep_count) * boid.stats.speed
		
	var alignment_force = Vector3.ZERO
	if align_count > 0:
		var avg_velocity = alignment / align_count
		if avg_velocity.length() > 0.01:
			alignment_force = avg_velocity.normalized() * boid.stats.speed - boid.velocity
	
	var cohesion_force = Vector3.ZERO
	if coh_count > 0:
		var centre = cohesion_centre / coh_count
		var to_centre = centre - boid.global_position
		to_centre.y = 0
		if to_centre.length() > 0.01:
			cohesion_force = to_centre.normalized() * boid.stats.speed - boid.velocity
	
	return (separation_force * separation_weight) \
		 + (alignment_force * alignment_weight) \
		 + (cohesion_force * cohesion_weight)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
