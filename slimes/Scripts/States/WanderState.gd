class_name WanderState extends State

const  HUNGER_THRESHOLD: float = 0.6 # Seek food when health < 60% of max

var wander_behavior: SteeringBehavior
var seek_food_state: State
var combat_state: CombatState


func _enter() -> void:
	if not wander_behavior:
		wander_behavior = boid.get_node("SteeringBehaviors/Wander")
	if not seek_food_state:
		seek_food_state = state_machine.get_node("../states/SeekFoodState")
	if not combat_state:
		combat_state = state_machine.get_node("../states/CombatState")
	wander_behavior.enabled = true

func _exit() -> void:
	if wander_behavior:
		wander_behavior.enabled = false

func _think() -> void:
	if boid.stats.current_health < boid.stats.max_health * HUNGER_THRESHOLD:
		state_machine.change_state(seek_food_state)
		
	if boid.nearest_other_slime:
		print(boid.name, " trying to enter combat with ", boid.nearest_other_slime.name)
		combat_state.set_target(boid.nearest_other_slime)
		state_machine.change_state(combat_state)
