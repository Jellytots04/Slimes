class_name  SeekTarget extends SteeringBehavior

var target: SlimeNode = null
@export var stop_distance: float = 2.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boid = get_parent().get_parent()

func calculate() -> Vector3:
	if target and not is_instance_valid(target):
		target = null
	
	if not target:
		return Vector3.ZERO
	
	var to_target = target.global_position - boid.global_position
	var distance = to_target.length()
	
	if distance < 0.01:
		return Vector3.ZERO
	
	if distance <= stop_distance:
		return -boid.velocity * 10.0
	
	return boid.arrive_force(target.global_position)

func set_target(slime) -> void:
	target = slime

func clear_target() -> void:
	target = null


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
