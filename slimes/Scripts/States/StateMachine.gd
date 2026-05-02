class_name StateMachine extends Node

@export var initial_state: NodePath

var current_state: State
var boid

func _ready()-> void:
	boid = get_parent() # Assuming its SlimeNode/StateMachine

	var states_root = boid.get_node("states")
	for state in states_root.get_children():
		if state is State:
			state.boid = boid
			state.state_machine = self
			
	if initial_state:
		current_state = get_node(initial_state)
		current_state._enter()

func change_state(new_state) -> void:
	if new_state == current_state:
		return
	
	if current_state:
		current_state._exit()
	
	current_state = new_state
	
	if current_state:
		print(current_state)
		current_state._enter()
		
func _process(delta: float) -> void:
	if current_state:
		current_state._think()
