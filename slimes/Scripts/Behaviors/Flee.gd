class_name Flee extends SteeringBehavior

@export var flee_range: float = 50.0

var threat: SlimeNode = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boid = get_parent().get_parent()

func calculate() -> Vector3:
	if threat and not is_instance_valid(threat):
		threat = null
	
	if not threat:
		return Vector3.ZERO
	
	var away = boid.global_position - threat.global_position
	away.y = 0
	var distance = away.length()

	if distance > flee_range or distance < 0.01:
		return Vector3.ZERO
	
	var desired = away.normalized() * boid.stats.speed
	return desired - boid.velocity

func set_threat(slime) -> void:
	threat = slime
	
func clear_threat() -> void:
	threat = null
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
