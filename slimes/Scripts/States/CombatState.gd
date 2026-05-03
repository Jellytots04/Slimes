class_name CombatState extends State

var seek_target: SeekTarget
var target: SlimeNode = null
var attack_cooldown_timer: float = 0.0

func _enter() -> void:
	print(boid.name, " entered combat targeting ", target.name if target else "NULL")
	if not seek_target:
		seek_target = boid.get_node("SteeringBehaviors/SeekTarget")
	
	seek_target.set_target(target)
	seek_target.enabled = true
	attack_cooldown_timer = 0.0

func _exit() -> void:
	if seek_target:
		seek_target.enabled = false
		seek_target.clear_target()
	target = null

func _think() -> void:
	var delta = get_process_delta_time()
	attack_cooldown_timer -= delta
	
	if not target or not is_instance_valid(target):
		return_to_wander()
		return
	
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
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
