class_name Wander extends SteeringBehavior

@export var wander_radius: float = 5.0 # How far the targets can be picked
@export var arrival_distnace: float = 0.5 # How close before picking a new target
@export var pause_min: float = 0.3 # Minimum time to pause at target
@export var pause_max: float = 1.2 # Maximum time to pause at target

var current_target: Vector3
var pause_timer: float = 0.0
var has_target: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boid = get_parent().get_parent()
	pick_new_target()

func calculate() -> Vector3:
	if pause_timer > 0.0:
		pause_timer -= get_process_delta_time()
		return Vector3.ZERO

	var to_target = current_target - boid.global_position
	to_target.y = 0
	
	if to_target.length() < arrival_distnace:
		pause_timer = randf_range(pause_min, pause_max)
		pick_new_target()
		return Vector3.ZERO
		
	return boid.seek_force(current_target)
	
func pick_new_target() -> void:
	var angle = randf() * TAU
	var distance = randf_range(wander_radius * 0.3, wander_radius)
	var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	current_target = boid.global_position + offset
	print("New target picked : ", current_target)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
