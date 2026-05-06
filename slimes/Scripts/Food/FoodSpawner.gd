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

const FRUIT_SCENE_PATH := "res://Scenes/FoodScenes/FruitScene.tscn"
const MEAT_SCENE_PATH := "res://Scenes/FoodScenes/MeatScene.tscn"

@onready var spawn_timer: Timer = $SpawnTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var spawned_food: Array = []  # track what we spawned

func _ready() -> void:
	# print(name, " spawner _ready, type: ", spawner_type)
	add_to_group("spawners")
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	if animation_player and animation_player.has_animation("Idle"):
		animation_player.play("Idle")
		
	# Burst once on spawner placement so the scene starts with food
	burst_spawn()

func _on_spawn_timer_timeout() -> void:
	burst_spawn()

func burst_spawn() -> void:
	# print(name, " burst_spawn called. Current count: ", spawned_food.size(), "/", max_food)
	# Clean up freed references first
	spawned_food = spawned_food.filter(func(f): return is_instance_valid(f))
	
	# Already at cap?
	if spawned_food.size() >= max_food:
		# print(name, " at cap, skipping")
		return
	
	var burst_count = randi_range(burst_min, burst_max)
	var available_slots = max_food - spawned_food.size()
	burst_count = min(burst_count, available_slots)
	# print(name, " spawning ", burst_count, " food this burst")
	
	# Play spawn animation
	if animation_player and animation_player.has_animation("Spawn"):
		animation_player.play("Spawn")
		await animation_player.animation_finished
		# Return to idle
		if animation_player.has_animation("Idle"):
			animation_player.play("Idle")
	
	for i in range(burst_count):
		spawn_one_food()

func spawn_one_food() -> void:
	# Determine food type first based on spawner type
	var food_type: int
	match spawner_type:
		SpawnerType.MEAT:
			food_type = 1
		SpawnerType.FRUIT:
			food_type = 2
		SpawnerType.MULTI:
			food_type = 1 if randf() < 0.5 else 2
	
	# Load the matching scene
	var scene_path = MEAT_SCENE_PATH if food_type == 1 else FRUIT_SCENE_PATH
	var food_scene = load(scene_path)
	if not food_scene:
		# push_error("Couldn't load food scene at " + scene_path)
		print(name, " FAILED to load scene at: ", scene_path)
		return
	
	var food = food_scene.instantiate()
	
	var food_stats = food.get_node("Stats")
	food_stats.food_type = food_type
	food_stats.nutrition = meat_nutrition if food_type == 1 else fruit_nutrition
	
	var angle := randf() * TAU
	var distance := randf_range(0, spawn_radius)
	var offset := Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	
	# print("Adding food. spawner parent: ", get_parent().name, " | spawner: ", name)
	get_tree().current_scene.add_child(food)
	food.global_position = global_position + offset
	food.global_position.y = 0.10
	spawned_food.append(food)
	# print(name, " spawned food at ", food.position, " type ", food_type)
	
