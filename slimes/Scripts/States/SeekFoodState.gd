class_name SeekFoodState extends State

const FULL_THRESHOLD: float = 0.85 # Exit state when health >= 95% of max health

var seek_food_behavior: SeekFood
var wander_behavior: SteeringBehavior
var wander_state: State

func _enter() -> void:
	if not seek_food_behavior:
		seek_food_behavior = boid.get_node("SteeringBehaviors/SeekFood")
	if not wander_behavior:
		wander_behavior = boid.get_node("SteeringBehaviors/Wander")
	if not wander_state:
		wander_state = state_machine.get_node("../states/WanderState")
	seek_food_behavior.enabled = true

func _exit() -> void:
	if seek_food_behavior:
		seek_food_behavior.enabled = false
		seek_food_behavior.clear_target() # Forget the current target upon exiting
	if wander_behavior:
		wander_behavior.enabled = false
	
	var flee = boid.get_node("SteeringBehaviors/Flee")
	if flee:
		flee.enabled = false
		flee.clear_threat()

func _think() -> void:
	# Switch to wandering state once health is restored
	if boid.stats.current_health >= boid.stats.max_health * FULL_THRESHOLD:
		state_machine.change_state(wander_state)
		return
	
	var has_food = seek_food_behavior.find_nearest_food() != null
	wander_behavior.enabled = not has_food

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
