extends Node3D

const SLIME_SCENE = preload("res://Scenes/Slime/SlimeScene.tscn")
const FRUIT_TREE_SCENE = preload("res://Scenes/SpawnerScenes/FruitFoodSpawnerScene.tscn")
const MEAT_BIN_SCENE = preload("res://Scenes/SpawnerScenes/MeatFoodSpawnerScene.tscn")
const MULTI_BIN_SCENE = preload("res://Scenes/SpawnerScenes/MultiFoodSpawnerScene.tscn")

enum Mode { NONE, PLACE_SLIME, PLACE_FRUIT_TREE, PLACE_MEAT_BIN, PLACE_MULTI_BIN }

@export var camSpeed: float = 10
@onready var marker: Marker3D = $RotationPoint
@onready var camera_3d: Camera3D = $Camera3D
@onready var hud: Control = $Camera3D/PCUI

var current_mode: Mode = Mode.NONE
var pending_slime_aggression: int = 0
var pending_slime_defensive: int = -1
var pending_slime_food_pref: int = 0
var pending_slime_body_color: Color = Color.WHITE

@onready var placement_preview = get_tree().current_scene.get_node("PlacementPreview")

func _ready() -> void:
	hud.slime_spawn_requested.connect(_on_slime_spawn_requested)
	hud.fruit_tree_spawn_requested.connect(_on_fruit_tree_requested)
	hud.meat_bin_spawn_requested.connect(_on_meat_bin_requested)
	hud.multi_bin_spawn_requested.connect(_on_multi_bin_requested)
	placement_preview.hide()

func _process(delta: float) -> void:
	if Input.is_action_pressed("Forward"):
		forwardMotion(delta)
	if Input.is_action_pressed("Backward"):
		backwardMotion(delta)
	if Input.is_action_pressed("Left"):
		leftMotion(delta)
	if Input.is_action_pressed("Right"):
		rightMotion(delta)
	if Input.is_action_just_pressed("LeftTurn"):
		turnLeft()
	if Input.is_action_just_pressed("RightTurn"):
		turnRight()
	update_placement_preview()

func update_placement_preview() -> void:
	if current_mode == Mode.NONE:
		placement_preview.hide()
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var click_result = raycast_from_mouse(mouse_pos)
	
	if click_result == null or click_result.is_empty():
		placement_preview.hide()
		return
	
	placement_preview.show()
	placement_preview.global_position = click_result.position
	placement_preview.global_position.y += 0.05

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Right-click cancels placement mode
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if current_mode != Mode.NONE:
				current_mode = Mode.NONE
				print("Placement cancelled")
			hud.reset_after_placement()
			return
		
		# Left-click handles placement
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Left click. Mode: ", Mode.keys()[current_mode])
			if current_mode == Mode.NONE:
				print("  No mode active, ignoring")
				return
			
			var click_result = raycast_from_mouse(event.position)
			print("  Raycast result: ", click_result)
			
			if click_result == null or click_result.is_empty():
				print("  No collision hit")
				return
			
			print("  Hit position: ", click_result.position)
			print("  Hit collider: ", click_result.collider)
			
			match current_mode:
				Mode.PLACE_SLIME:
					spawn_slime(click_result.position)
				Mode.PLACE_FRUIT_TREE:
					spawn_entity(FRUIT_TREE_SCENE, click_result.position + Vector3(0,.3,0))
				Mode.PLACE_MEAT_BIN:
					spawn_entity(MEAT_BIN_SCENE, click_result.position + Vector3(0,.8,0))
				Mode.PLACE_MULTI_BIN:
					spawn_entity(MULTI_BIN_SCENE, click_result.position + Vector3(0,.3,0))
			
			current_mode = Mode.NONE
			hud.reset_after_placement()

func raycast_from_mouse(screen_pos: Vector2) -> Variant:
	var from = camera_3d.project_ray_origin(screen_pos)
	var to = from + camera_3d.project_ray_normal(screen_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	return space_state.intersect_ray(query)

func spawn_slime(pos: Vector3) -> void:
	var slime = SLIME_SCENE.instantiate()
	var stats_node = slime.get_node("Stats")
	stats_node.aggression_type = pending_slime_aggression
	stats_node.defensive_type = pending_slime_defensive
	stats_node.food_preference = pending_slime_food_pref
	
	get_tree().current_scene.add_child(slime)
	slime.global_position = pos
	slime.global_position.y += 0.5
	
	var slime_mesh = slime.get_node("SlimeMesh")
	if slime_mesh:
		var body_mat = StandardMaterial3D.new()
		body_mat.albedo_color = pending_slime_body_color
		slime_mesh.set_surface_override_material(0, body_mat)

func spawn_entity(scene: PackedScene, pos: Vector3) -> void:
	var entity = scene.instantiate()
	get_tree().current_scene.add_child(entity)
	entity.global_position = pos

# HUD signal handlers
func _on_slime_spawn_requested(aggression: int, defensive: int, food_pref: int, body_color: Color) -> void:
	pending_slime_aggression = aggression
	pending_slime_defensive = defensive
	pending_slime_food_pref = food_pref
	pending_slime_body_color = body_color
	current_mode = Mode.PLACE_SLIME
	print("Slime placement mode active. Click floor to place.")


func _on_fruit_tree_requested() -> void:
	current_mode = Mode.PLACE_FRUIT_TREE
	print("Fruit tree placement mode active.")


func _on_meat_bin_requested() -> void:
	current_mode = Mode.PLACE_MEAT_BIN
	print("Meat bin placement mode active.")


func _on_multi_bin_requested() -> void:
	current_mode = Mode.PLACE_MULTI_BIN
	print("Multi bin placement mode active.")


# Camera movement
func forwardMotion(delta):
	var dir = -transform.basis.z
	dir.y = 0
	dir = dir.normalized()
	position += dir * camSpeed * delta


func backwardMotion(delta):
	var dir = transform.basis.z
	dir.y = 0
	dir = dir.normalized()
	position += dir * camSpeed * delta


func leftMotion(delta):
	var dir = -transform.basis.x
	dir.y = 0
	dir = dir.normalized()
	position += dir * camSpeed * delta


func rightMotion(delta):
	var dir = transform.basis.x
	dir.y = 0
	dir = dir.normalized()
	position += dir * camSpeed * delta


func turnLeft():
	var angle = -90
	var pivotPoint = marker.global_position
	var offset = global_position - pivotPoint
	var rotated_offset = offset.rotated(Vector3.UP, angle)
	global_position = pivotPoint + rotated_offset
	rotation_degrees.y = rotation_degrees.y + angle


func turnRight():
	var angle = 90
	var pivotPoint = marker.global_position
	var offset = global_position - pivotPoint
	var rotated_offset = offset.rotated(Vector3.UP, angle)
	global_position = pivotPoint + rotated_offset
	rotation_degrees.y = rotation_degrees.y + angle
