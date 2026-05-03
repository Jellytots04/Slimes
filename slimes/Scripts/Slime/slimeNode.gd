class_name SlimeNode extends CharacterBody3D

@onready var stats: Statistics = $Stats

@export var slowing_radius: float = 2.0
@export var damping: float = 1.0

const DETECTION_RANGE: float = 10.0
const DETECTION_INTERVAL: float = 0.3

var nearest_other_slime: SlimeNode = null

func _ready() -> void:
	add_to_group("slimes")
	stats.current_health = stats.max_health * Statistics.SPAWN_HEALTH_PERCENT
	# print("HP Spawned in with : ", stats.current_health, " / ", stats.max_health)

func _process(delta: float) -> void:
	# print(global_position)
	pass

func _physics_process(delta: float) -> void:
	var total_force := Vector3.ZERO
	var steering_root := $SteeringBehaviors
	for behavior in steering_root.get_children():
		if behavior is SteeringBehavior and behavior.enabled:
			total_force += behavior.calculate() * behavior.weight
			# print(total_force)
	
	total_force.y = 0
	
	velocity += total_force * delta
	# velocity = velocity.lerp(Vector3.ZERO, damping * delta)
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
	print("Ate food HP now : ", stats.current_health)

func take_damage(amount: int) -> void:
	var actual = max(0, amount - stats.defense)
	stats.current_health -= actual
	if stats.current_health <= 0:
		die()

func die() -> void:
	queue_free()

func _decay_timer_timeout() -> void:
	var decay_rate: float
	if stats.current_health > stats.max_health:
		decay_rate = Statistics.OVEREAT_DECAY_RATE
	else:
		decay_rate = Statistics.HEALTH_DECAY_RATE

	stats.current_health -= Statistics.HEALTH_DECAY_RATE
	# stats.current_health -= decay_rate * delta
	print("HP: ", stats.current_health)

	if stats.current_health <= 0:
		print("DIED")
		die()
		return

func _on_deteciton_timer_timeout() -> void:
	update_nearest_slime()

func update_nearest_slime() -> void:
	var all_slimes = get_tree().get_nodes_in_group("slimes")
	# print(name, " — group size: ", all_slimes.size())
	var nearest: SlimeNode = null
	var nearest_distance = DETECTION_RANGE
	
	for slime in all_slimes:
		if slime == self:
			continue
		if not is_instance_valid(slime):
			continue
			
		var distance: float = slime.global_position.distance_to(global_position)
		print(name, " checking ", slime.name, " at distance ", distance, " (range ", DETECTION_RANGE, ")")
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = slime
	
	nearest_other_slime = nearest
	
	print(name, " : sees : ", nearest_other_slime)
