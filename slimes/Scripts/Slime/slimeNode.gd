class_name SlimeNode extends CharacterBody3D

@onready var stats: Statistics = $Stats

@export var slowing_radius: float = 2.0
@export var damping: float = 3.0

var current_force: Vector3 = Vector3.ZERO

func _ready() -> void:
	stats.current_health = stats.max_health * Statistics.SPAWN_HEALTH_PERCENT
	print("HP Spawned in with : ", stats.current_health, " / ", stats.max_health)

func _process(delta: float) -> void:
	print(global_position)

func _physics_process(delta: float) -> void:
	var decay_rate: float
	if stats.current_health > stats.max_health:
		decay_rate = Statistics.OVEREAT_DECAY_RATE
	else:
		decay_rate = Statistics.HEALTH_DECAY_RATE

	if stats.current_health <= 0:
		die()
		return

	var total_force := Vector3.ZERO
	var steering_root := $SteeringBehaviors
	for behavior in steering_root.get_children():
		if behavior is SteeringBehavior and behavior.enabled:
			total_force += behavior.calculate() * behavior.weight
			# print(total_force)
	
	total_force.y = 0
	
	velocity += total_force * delta
	velocity = velocity.lerp(Vector3.ZERO, damping * delta)
	velocity.y = 0
	
	if velocity.length() > stats.speed:
		velocity = velocity.normalized() * stats.speed
	
	move_and_slide()
	
	if velocity.length() > 0.1:
		look_at(global_position - velocity, Vector3.UP)
	

func seek_force(target_pos) -> Vector3:
	var desired = (target_pos - global_position).normalized() * stats.speed
	return desired - velocity

func arrive_force(target_pos) -> Vector3:
	var to_target = target_pos - global_position
	to_target.y = 0
	var distance = to_target.length()
	
	if distance < 0.01:
		return -velocity
		
	var ramped_speed: float = stats.speed * (distance / slowing_radius)
	var clipped_speed: float = min(ramped_speed, stats.speed)
	
	var desired = to_target.normalized() * clipped_speed
	return desired - velocity

func eat(health_value: int) -> void:
	var cap = stats.max_health * stats.max_overeat_multiplier
	stats.current_health = min(stats.current_health + health_value, cap)

func take_damage(amount: int) -> void:
	var actual = max(0, amount - stats.defense)
	stats.current_health -= actual
	if stats.current_health <= 0:
		die()

func die() -> void:
	queue_free()
