class_name SlimeNode extends CharacterBody3D

@onready var stats: Statistics = $Stats

@export var slowing_radius: float = 2.0

func _ready() -> void:
	stats.current_health = stats.max_health * Statistics.SPAWN_HEALTH_PERCENT

func _physics_process(delta: float) -> void:
	var decay_rate: float
	if stats.current_health > stats.max_health:
		decay_rate = Statistics.OVEREAT_DECAY_RATE
	else:
		decay_rate = Statistics.HEALTH_DECAY_RATE
	
	
	if stats.current_health <= 0:
		die()
		return

	# Add the gravity.
	var total_force := Vector3.ZERO
	var steering_root := $SteeringBehaviors
	for behavior in steering_root.get_children():
		if behavior is SteeringBehavior and behavior.enabled:
			total_force += behavior.calculate() * behavior.weight
			# print(total_force)
	
	velocity += total_force * delta
	
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
		return -velocity * 10.0
		
	var desired_speed: float
	if distance >= slowing_radius:
		desired_speed = stats.speed
	else:
		desired_speed = stats.speed * 0.2
	
	var desired = to_target.normalized() * desired_speed
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
