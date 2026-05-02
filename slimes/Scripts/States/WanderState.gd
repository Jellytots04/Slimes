class_name WanderState extends State

const  HUNGER_THRESHOLD: float = 0.6 # Seek food when health < 60% of max

var wander_behavior: SteeringBehavior
var seek_food_state: State


func _enter() -> void:
	if not wander_behavior:
		wander_behavior = boid.get_node("SteeringBehaviors/Wander")
	if not seek_food_state:
		seek_food_state = state_machine.get_node("../states/SeekFoodState")
	wander_behavior.enabled = true

func _exit() -> void:
	if wander_behavior:
		wander_behavior.enabled = false

func _think() -> void:
	if boid.stats.current_health < boid.stats.max_health * HUNGER_THRESHOLD:
		state_machine.change_state(seek_food_state)
