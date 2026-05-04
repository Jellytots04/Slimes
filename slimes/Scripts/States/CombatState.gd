class_name CombatState extends State

const KILLER_HEALTH_THRESHOLD: float = 0.25

var seek_target: SeekTarget
var flee_behavior: Flee
var target: SlimeNode = null
var attack_cooldown_timer: float = 0.0

func _enter() -> void:
	# print(boid.name, " entered combat targeting ", target.name if target else "NULL")
	if not seek_target:
		seek_target = boid.get_node("SteeringBehaviors/SeekTarget")
	if not flee_behavior:
		flee_behavior = boid.get_node("SteeringBehaviors/Flee")
	
	seek_target.set_target(target)
	seek_target.enabled = true
	attack_cooldown_timer = 0.0

func _exit() -> void:
	if seek_target:
		seek_target.enabled = false
		seek_target.clear_target()
	if flee_behavior:
		flee_behavior.enabled = false
		flee_behavior.clear_threat()
	target = null

func _think() -> void:
	var delta = get_process_delta_time()
	attack_cooldown_timer -= delta
	
	if not target or not is_instance_valid(target):
		return_to_wander()
		return
	
	if boid.stats.aggression_type == 2:
		if boid.stats.current_health > boid.stats.max_health * KILLER_HEALTH_THRESHOLD:
			flee_behavior.set_threat(target)
			flee_behavior.enabled = true
			seek_target.enabled = false
			
			var seek_food_state = state_machine.get_node("../states/seekFoodState")
			state_machine.change_state(seek_food_state)
			return
	
	var direction_target = target.global_position - boid.global_position
	direction_target.y = 0
	var opposite_point = boid.global_position - direction_target
	boid.look_at(opposite_point, Vector3.UP)
	
	var distance: float = boid.global_position.distance_to(target.global_position)
	if distance <= boid.stats.attack_range:
		if attack_cooldown_timer <= 0.0:
			target.take_damage(boid.stats.damage)
			attack_cooldown_timer = boid.stats.attack_cooldown

func set_target(slime) -> void:
	target = slime

func return_to_wander() -> void:
	var wander_state = state_machine.get_node("../states/WanderState")
	state_machine.change_state(wander_state)
