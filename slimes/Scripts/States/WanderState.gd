class_name WanderState extends State

@onready var wander_behavior: SteeringBehavior = boid.get_node("SteeringBehaviors/Wander")

func _enter() -> void:
	if not wander_behavior:
		wander_behavior = boid.get_node("SteeringBehaviors/Wander")
	wander_behavior.enabled = true

func _exit() -> void:
	if wander_behavior:
		wander_behavior.enabled = false

func _think() -> void:
	# Should check hunger and check for danger
	pass
