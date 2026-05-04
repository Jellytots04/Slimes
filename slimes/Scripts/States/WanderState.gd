class_name WanderState extends State

const  HUNGER_THRESHOLD: float = 0.6 # Seek food when health < 60% of max

const AGG_FLOCKER := 0
const AGG_ALPHA := 1
const AGG_KILLER := 2

var wander_behavior: SteeringBehavior
var seek_food_state: State
var combat_state: CombatState
var avoidance_behavior: SteeringBehavior
var flocking_behavior: SteeringBehavior

func _enter() -> void:
	if not wander_behavior:
		wander_behavior = boid.get_node("SteeringBehaviors/Wander")
	if not avoidance_behavior:
		avoidance_behavior = boid.get_node("SteeringBehaviors/Avoidance")
	if not flocking_behavior:
		flocking_behavior = boid.get_node("SteeringBehaviors/Flocking")
	if not seek_food_state:
		seek_food_state = state_machine.get_node("../states/SeekFoodState")
	if not combat_state:
		combat_state = state_machine.get_node("../states/CombatState")
	
	wander_behavior.enabled = true

func _exit() -> void:
	if wander_behavior:
		wander_behavior.enabled = false
	if avoidance_behavior:
		avoidance_behavior.enabled = false
	if flocking_behavior:
		flocking_behavior.enabled = false

func _think() -> void:
	if boid.stats.current_health < boid.stats.max_health * HUNGER_THRESHOLD:
		state_machine.change_state(seek_food_state)
		
	if boid.nearest_other_slime:
		# print(boid.name, " sees ", boid.nearest_other_slime.name, " | type: ", boid.stats.aggression_type)
		match boid.stats.aggression_type:
			AGG_KILLER:
				# Hunting, transition into combat
				avoidance_behavior.enabled = false
				combat_state.set_target(boid.nearest_other_slime)
				state_machine.change_state(combat_state)
				return
			
			AGG_ALPHA:
				if not avoidance_behavior.enabled:
				# Avoid everyone, stay wandering
					avoidance_behavior.enabled = true
					wander_behavior.enabled = false
				return
			
			AGG_FLOCKER:
				if not flocking_behavior.enabled:
					flocking_behavior.enabled = true
					avoidance_behavior.enabled = false
				return
	else:
		var was_avoiding = avoidance_behavior.enabled
		avoidance_behavior.enabled = false
		flocking_behavior.enabled = false
		wander_behavior.enabled = true
		if was_avoiding:
			wander_behavior.pick_new_target()
