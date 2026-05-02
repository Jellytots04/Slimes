class_name Wander extends SteeringBehavior

@export var wander_radius: float = 5.0 # How far the targets can be picked
@export var arrival_distance: float = 0.8 # How close before picking a new target
@export var pause_min: float = 0.3 # Minimum time to pause at target
@export var pause_max: float = 1.2 # Maximum time to pause at target
@export var max_travel_time: float = 5.0 # Max time traveling to current target spot

var current_target: Vector3
var pause_timer: float = 0.0
var travel_timer: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boid = get_parent().get_parent()
	pick_new_target()

func calculate() -> Vector3:
	if pause_timer > 0.0:
		pause_timer -= get_process_delta_time()
		return -boid.velocity

	# travel_timer += get_process_delta_time()

	var to_target = current_target - boid.global_position
	to_target.y = 0
	
	if to_target.length() < arrival_distance:
		pause_timer = randf_range(pause_min, pause_max)
		pick_new_target()
		return boid.seek_force(current_target)
	
	#if travel_timer > max_travel_time:
		#print("Stuck - Pick new target")
		#pick_new_target()
		#return Vector3.ZERO
	
	return boid.arrive_force(current_target)
	
func pick_new_target() -> void:
	var min_target_distance: float = arrival_distance * 4.0
	var distance = randf_range(min_target_distance, wander_radius)
	
	var forward = boid.global_transform.basis.z
	var forward_angle = atan2(forward.x, forward.z)
	
	var angle: float
	if randf() < 0.8:
		angle = forward_angle + randf_range(-PI / 3.0, PI / 3.0)
	else:
		angle = randf() * TAU
	
	var offset := Vector3(sin(angle) * distance, 0, cos(angle) * distance)
	current_target = boid.global_position + offset
	print("New target picked : ", current_target)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
