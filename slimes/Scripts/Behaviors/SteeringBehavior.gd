class_name SteeringBehavior extends Node

@export var weight: float = 1.0
@export var enabled: bool = true

var boid

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boid = get_parent().get_parent() 
	# SlimeNode will be the grandparent assuming its attached as SlimeNode/SteeringBehaviors/Behavior

func calculate() -> Vector3:
	return Vector3.ZERO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
