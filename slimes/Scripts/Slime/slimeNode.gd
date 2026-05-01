class_name SlimeNode extends CharacterBody3D

@onready var stats: Statistics = $Stats

var current_force: Vector3 = Vector3.ZERO

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _physics_process(delta: float) -> void:
	# Add the gravity.
	var total_force := Vector3.ZERO
	var steering_root := $SteeringBehaviors
	for behavior in steering_root.get_children():
		if behavior is SteeringBehavior and behavior.enabled:
			total_force += behavior.calculate() * behavior.weight
			print(total_force)
	
	velocity += total_force * delta
	
	velocity.y = 0
	
	if velocity.length() > stats.speed:
		velocity = velocity.normalized() * stats.speed
	
	move_and_slide()
	
	if velocity.length() > 0.1:
		look_at(global_position + velocity, Vector3.UP)

func seek_force(target_pos) -> Vector3:
	var desired = (target_pos - global_position).normalized() * stats.speed
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
