class_name SpawnerManager extends Node3D

const FRUIT_TREE_SCENE = preload("res://Scenes/SpawnerScenes/FruitFoodSpawnerScene.tscn")
const MEAT_BIN_SCENE = preload("res://Scenes/SpawnerScenes/MeatFoodSpawnerScene.tscn")
const MULTI_BIN_SCENE = preload("res://Scenes/SpawnerScenes/MultiFoodSpawnerScene.tscn")

@export var spawn_floor: MeshInstance3D
@export var fruit_tree_count: int = 4
@export var meat_bin_count: int = 4
@export var multi_bin_count: int = 2
@export var min_spacing: float = 3.0
@export var fruit_y_offset: float = 0.3
@export var meat_y_offset: float = 0.8
@export var multi_y_offset: float = 0.3

var placed_positions: Array = []

func _ready() -> void:
	if not spawn_floor:
		push_error("SpawnerManager needs a spawn_floor MeshInstance3D assigned!")
		return
	
	_spawn_all.call_deferred()

func _spawn_all() -> void:
	for i in range(fruit_tree_count):
		spawn_random(FRUIT_TREE_SCENE, fruit_y_offset)
	for i in range(meat_bin_count):
		spawn_random(MEAT_BIN_SCENE, meat_y_offset)
	for i in range(multi_bin_count):
		spawn_random(MULTI_BIN_SCENE, multi_y_offset)

func spawn_random(scene: PackedScene, y_offset: float) -> void:
	var pos = get_random_floor_position()
	if pos == null:
		push_warning("Couldn't find a valid spawn position with enough spacing")
		return
	
	pos.y = y_offset
	
	var instance = scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = pos
	placed_positions.append(pos)

func get_random_floor_position(max_attempts: int = 30) -> Variant:
	var aabb = spawn_floor.mesh.get_aabb()
	var global_origin = spawn_floor.global_transform.origin
	var scale = spawn_floor.global_transform.basis.get_scale()
	
	# Account for the floor's scale so AABB matches the visible area
	var min_x = global_origin.x + aabb.position.x * scale.x
	var max_x = global_origin.x + (aabb.position.x + aabb.size.x) * scale.x
	var min_z = global_origin.z + aabb.position.z * scale.z
	var max_z = global_origin.z + (aabb.position.z + aabb.size.z) * scale.z
	
	for attempt in range(max_attempts):
		var x = randf_range(min_x, max_x)
		var z = randf_range(min_z, max_z)
		var candidate = Vector3(x, 0, z)
		
		if _is_position_clear(candidate):
			return candidate
	
	return null

func _is_position_clear(pos: Vector3) -> bool:
	for existing in placed_positions:
		var dist_xz = Vector2(pos.x - existing.x, pos.z - existing.z).length()
		if dist_xz < min_spacing:
			return false
	return true
