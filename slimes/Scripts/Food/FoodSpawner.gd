class_name FoodSpawner extends StaticBody3D

enum SpawnerType { MEAT, FRUIT, MULTI }

@export var spawner_type: SpawnerType = SpawnerType.FRUIT
@export var spawn_interval: float = 5.0
@export var burst_min: int = 3
@export var burst_max: int = 5
@export var max_food: int = 10
@export var spawn_radius: float = 8.0
@export var fruit_nutrition: int = 25
@export var meat_nutrition: int = 30

const FOOD_SCENE_PATH := "res://Scenes/Food/Food.tscn"  # adjust to your actual path

var spawn_timer: Timer
var spawned_food: Array = []  # track what we spawned


func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	# Burst once on spawner placement so the scene starts with food
	burst_spawn()


func _on_spawn_timer_timeout() -> void:
	burst_spawn()


func burst_spawn() -> void:
	# Clean up freed references first
	spawned_food = spawned_food.filter(func(f): return is_instance_valid(f))
	
	# Already at cap?
	if spawned_food.size() >= max_food:
		return
	
	var burst_count = randi_range(burst_min, burst_max)
	var available_slots = max_food - spawned_food.size()
	burst_count = min(burst_count, available_slots)
	
	for i in range(burst_count):
		spawn_one_food()


func spawn_one_food() -> void:
	var food_scene = load(FOOD_SCENE_PATH)
	if not food_scene:
		push_error("Couldn't load food scene at " + FOOD_SCENE_PATH)
		return
	
	var food = food_scene.instantiate()
	
	# Configure stats based on spawner type
	var food_stats = food.get_node("Stats")
	var food_type: int
	
	match spawner_type:
		SpawnerType.MEAT:
			food_type = 1
		SpawnerType.FRUIT:
			food_type = 2
		SpawnerType.MULTI:
			food_type = 1 if randf() < 0.5 else 2
	
	food_stats.food_type = food_type
	food_stats.nutrition = meat_nutrition if food_type == 1 else fruit_nutrition
	
	# Random position in radius around spawner
	var angle := randf() * TAU
	var distance := randf_range(0, spawn_radius)
	var offset := Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	food.position = position + offset
	
	get_parent().add_child(food)
	spawned_food.append(food)
