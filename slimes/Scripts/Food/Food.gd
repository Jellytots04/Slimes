class_name Food extends StaticBody3D

@onready var stats: FoodStatistics = %Stats

var consumed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("food")

func consume() -> int:
	if consumed:
		return 0
	consumed = true
	
	var nutrition = stats.nutrition
	queue_free()
	return nutrition
	
func get_food_type() -> int:
	return stats.food_type

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
