class_name  SeekTarget extends SteeringBehavior

var target: SlimeNode = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boid = get_parent().get_parent()

func calculate() -> Vector3:
	if target and not is_instance_valid(target):
		target = null
	
	if not target:
		return Vector3.ZERO
	
	return boid.seek_force(target.global_position)

func set_target(slime) -> void:
	target = slime

func clear_target() -> void:
	target = null


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
