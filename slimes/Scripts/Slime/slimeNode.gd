class_name SlimeNode extends CharacterBody3D

@onready var stats: Statistics = $Stats

@export var slowing_radius: float = 2.0
@export var damping: float = 1.0

const DETECTION_RANGE: float = 10.0
const DETECTION_INTERVAL: float = 0.3

var nearby_slimes: Array = []
var nearest_other_slime: SlimeNode = null

func _ready() -> void:
	add_to_group("slimes")
	stats.current_health = stats.max_health * Statistics.SPAWN_HEALTH_PERCENT
	print("HP Spawned in with : ", stats.current_health, " / ", stats.max_health)

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

func take_damage(amount: int, attacker: SlimeNode = null) -> void:
	var actual = max(0, amount - stats.defense)
	stats.current_health -= actual
	if stats.current_health <= 0:
		die()
		
	if attacker:
		react_to_attack(attacker)

func react_to_attack(attacker: SlimeNode) -> void:
	var hp_pct = stats.current_health / stats.max_health
	var should_fight: bool
	
	match stats.defensive_type:
		0: # Pack defender - only fights if other flockers are nearby
			should_fight = get_nearby_flocker().size() > 0
		1: # Health fighter - Fights only above 50% HP
			should_fight = hp_pct > 0.5
		2: # Runner - Fights only above 75% HP
			should_fight = hp_pct > 0.75
		3: # Last staand - always fight
			should_fight = true
	
	var sm = $StateMachine
	print(name, " hit. HP%: ", hp_pct, " | defensive_type: ", stats.defensive_type, " | fight: ", should_fight)
	if should_fight:
		var combat_state = sm.get_node("../states/CombatState")
		if sm.current_state != combat_state:
			combat_state.set_target(attacker)
			sm.change_state(combat_state)
	else:
		var flee_state = sm.get_node("../states/FleeState")
		if sm.current_state != flee_state:
			flee_state.set_threat(attacker)
			sm.change_state(flee_state)

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
	print("HP: ", stats.current_health, " : From : ", self)

	if stats.current_health <= 0:
		print("DIED")
		die()
		return

func _on_deteciton_timer_timeout() -> void:
	update_nearby_slimes()

func update_nearby_slimes() -> void:
	nearby_slimes.clear()
	nearest_other_slime = null
	var nearest_distance = DETECTION_RANGE
	
	var all_slimes = get_tree().get_nodes_in_group("slimes")
	for slime in all_slimes:
		if slime == self:
			continue
		if not is_instance_valid(slime):
			continue
		
		var distance: float = slime.global_position.distance_to(global_position)
		if distance > DETECTION_RANGE:
			continue
		
		nearby_slimes.append(slime)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_other_slime = slime

func get_nearby_flocker() -> Array:
	var result = []
	for other in nearby_slimes:
		if not is_instance_valid(other):
			continue
		if other.stats.aggression_type == 0:
			result.append(other)
	return result
