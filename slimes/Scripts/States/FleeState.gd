class_name FleeState extends State

const FLEE_DURATION: float = 4.0
const FLEE_DISTANCE: float = 15.0

var flee_behavior: Flee
var wander_state: State
var threat: SlimeNode = null
var flee_timer: Timer

func _enter() -> void:
	if not flee_behavior:
		flee_behavior = boid.get_node("SteeringBehaviors/Flee")
	if not wander_state:
		wander_state = state_machine.get_node("../states/WanderState")
	if not flee_timer:
		flee_timer = boid.get_node("FleeTimer")
		flee_timer.timeout.connect(_on_flee_timer_timeout)

	flee_behavior.set_threat(threat)
	flee_behavior.enabled = true
	flee_timer.start(FLEE_DURATION)

func _exit() -> void:
	if flee_behavior:
		flee_behavior.enabled = false
		flee_behavior.clear_threat()
	if flee_timer:
		flee_timer.stop()
	threat = null

func _think() -> void:
	if not threat or not is_instance_valid(threat):
		state_machine.change_state(wander_state)
		return
	
	var distance = boid.global_position.distance_to(threat.global_position)
	if distance > FLEE_DISTANCE:
		state_machine.change_state(wander_state)
		return

func _on_flee_timer_timeout() -> void:
	if state_machine.current_state == self:
		state_machine.change_state(wander_state)

func set_threat(slime: SlimeNode) -> void:
	threat = slime

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
