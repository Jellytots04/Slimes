class_name WhiskerAvoidance extends SteeringBehavior

@export var whisker_length: float = 2.5
@export var whisker_angle_degrees: float = 30.0
@export var avoidance_force: float = 5.0

# Track most recent hit results for debug visualisation
var center_hit_active: bool = false
var left_hit_active: bool = false
var right_hit_active: bool = false

func _ready() -> void:
	boid = get_parent().get_parent()

func calculate() -> Vector3:
	if boid.velocity.length() < 0.1:
		center_hit_active = false
		left_hit_active = false
		right_hit_active = false
		return Vector3.ZERO
	
	var forward = boid.global_transform.basis.z
	forward.y = 0
	if forward.length() < 0.01:
		return Vector3.ZERO
	forward = forward.normalized()
	
	# Cast and store results
	center_hit_active = _raycast_in_direction(forward)
	left_hit_active = _raycast_in_direction(forward.rotated(Vector3.UP, deg_to_rad(whisker_angle_degrees)))
	right_hit_active = _raycast_in_direction(forward.rotated(Vector3.UP, deg_to_rad(-whisker_angle_degrees)))
	
	var avoidance_dir := Vector3.ZERO
	
	if center_hit_active:
		if left_hit_active and not right_hit_active:
			avoidance_dir = forward.rotated(Vector3.UP, deg_to_rad(-90))
		elif right_hit_active and not left_hit_active:
			avoidance_dir = forward.rotated(Vector3.UP, deg_to_rad(90))
		else:
			avoidance_dir = forward.rotated(Vector3.UP, deg_to_rad(90))
	elif left_hit_active:
		avoidance_dir = forward.rotated(Vector3.UP, deg_to_rad(-30))
	elif right_hit_active:
		avoidance_dir = forward.rotated(Vector3.UP, deg_to_rad(30))
	
	if avoidance_dir == Vector3.ZERO:
		return Vector3.ZERO
	
	return avoidance_dir.normalized() * boid.stats.speed * avoidance_force

func _raycast_in_direction(direction: Vector3) -> bool:
	var space_state = boid.get_world_3d().direct_space_state
	var from = boid.global_position + Vector3(0, 0.5, 0)
	var to = from + direction * whisker_length
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [boid.get_rid()]
	
	var result = space_state.intersect_ray(query)
	return not result.is_empty()
