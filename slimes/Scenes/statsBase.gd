# Statistics.gd
extends Node

@export var max_health: int
@export var current_health: int
@export var damage: int
@export var defense: int
@export var speed: float
@export var food_preference: int # 0, 1, 2: Three different food types
@export var aggression_type: int # 0, 1, 2: Different aggression type to define AI style

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
