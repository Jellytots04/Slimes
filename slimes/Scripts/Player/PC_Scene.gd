extends Node3D

const SLIME_SCENE = preload("res://Scenes/Slime/SlimeScene.tscn")
const FRUIT_TREE_SCENE = preload("res://Scenes/SpawnerScenes/FruitFoodSpawnerScene.tscn")
const MEAT_BIN_SCENE = preload("res://Scenes/SpawnerScenes/MeatFoodSpawnerScene.tscn")
const MULTI_BIN_SCENE = preload("res://Scenes/SpawnerScenes/MultiFoodSpawnerScene.tscn")

enum Mode { NONE, PLACE_SLIME, PLACE_FRUIT_TREE, PLACE_MEAT_BIN, PLACE_MULTI_BIN }

@export var follow_smoothness: float = 8.0  # higher = snappier follow
@export var inspect_distance: float = 3  # how far in front of slime
@export var inspect_angle_degrees: float = 35.0  # downward angle
@export var camSpeed: float = 10
@onready var marker: Marker3D = $RotationPoint
@onready var camera_3d: Camera3D = $Camera3D
@onready var hud: Control = $Camera3D/PCUI

var current_mode: Mode = Mode.NONE
var pending_slime_aggression: int = 0
var pending_slime_defensive: int = -1
var pending_slime_food_pref: int = 0
var pending_slime_body_color: Color = Color.WHITE
var pending_slime_name: String = "Jane Doe"

@onready var placement_preview = get_tree().current_scene.get_node("PlacementPreview")

var inspected_entity: Node3D = null
var saved_camera_position: Vector3
var saved_camera_rotation: Vector3
var saved_inner_camera_rotation: Vector3

@export var zoom_speed: float = 0.5
@export var min_zoom_factor: float = 5.0  # 0.5 = zoomed in 2x (was your "1.5" max-in inverted)
@export var max_zoom_factor: float = 10.0  # zoomed out 3x

var current_zoom_y: float

func _ready() -> void:
	hud.slime_spawn_requested.connect(_on_slime_spawn_requested)
	hud.fruit_tree_spawn_requested.connect(_on_fruit_tree_requested)
	hud.meat_bin_spawn_requested.connect(_on_meat_bin_requested)
	hud.multi_bin_spawn_requested.connect(_on_multi_bin_requested)
	hud.remove_requested.connect(_on_remove_requested)
	placement_preview.hide()
	saved_camera_rotation = rotation
	current_zoom_y = global_position.y
	hud.teleport_requested.connect(_on_teleport_requested)

func _process(delta: float) -> void:
	if inspected_entity:
		if is_instance_valid(inspected_entity):
			follow_inspected_entity(delta)
		else:
			exit_inspection()
		return
	
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
	if current_mode == Mode.NONE or inspected_entity:
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
	if not (event is InputEventMouseButton and event.pressed):
		return
	
	# Scroll wheel zoom
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_camera(-zoom_speed)
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_camera(zoom_speed)
		return
	
	# Right-click cancels mode or exits inspection
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if inspected_entity:
			exit_inspection()
			return
		if current_mode != Mode.NONE:
			current_mode = Mode.NONE
		hud.reset_after_placement()
		return
	
	# Left-click handles placement or inspection
	if event.button_index == MOUSE_BUTTON_LEFT:
		if inspected_entity:
			return
		
		var click_result = raycast_from_mouse(event.position)
		if click_result == null or click_result.is_empty():
			return
		
		if current_mode != Mode.NONE:
			match current_mode:
				Mode.PLACE_SLIME:
					spawn_slime(click_result.position - Vector3(0,.5,0))
				Mode.PLACE_FRUIT_TREE:
					spawn_entity(FRUIT_TREE_SCENE, click_result.position + Vector3(0, 0.3, 0))
				Mode.PLACE_MEAT_BIN:
					spawn_entity(MEAT_BIN_SCENE, click_result.position + Vector3(0, 0.8, 0))
				Mode.PLACE_MULTI_BIN:
					spawn_entity(MULTI_BIN_SCENE, click_result.position + Vector3(0, 0.3, 0))
			
			current_mode = Mode.NONE
			hud.reset_after_placement()
		else:
			try_inspect(click_result.collider)

func raycast_from_mouse(screen_pos: Vector2) -> Variant:
	var from = camera_3d.project_ray_origin(screen_pos)
	var to = from + camera_3d.project_ray_normal(screen_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	return space_state.intersect_ray(query)

func spawn_slime(pos: Vector3) -> void:
	var slime = SLIME_SCENE.instantiate()
	var stats_node = slime.get_node("Stats")
	
	# User-defined attributes
	stats_node.slimeName = pending_slime_name
	stats_node.aggression_type = pending_slime_aggression
	stats_node.defensive_type = pending_slime_defensive
	stats_node.food_preference = pending_slime_food_pref
	
	# Randomised body stats
	match pending_slime_aggression:
		0:  # Flocker
			stats_node.max_health = randi_range(80, 120)
			stats_node.damage = randi_range(5, 15)
			stats_node.defense = randi_range(0, 5)
			stats_node.speed = randf_range(2.5, 4.0)
		1:  # Alpha
			stats_node.max_health = randi_range(130, 180)
			stats_node.damage = randi_range(3, 12)
			stats_node.defense = randi_range(5, 10)
			stats_node.speed = randf_range(3.5, 4.0)
		2:  # Killer
			stats_node.max_health = randi_range(100, 150)
			stats_node.damage = randi_range(8, 20)
			stats_node.defense = randi_range(0, 3)
			stats_node.speed = randf_range(2.5, 4.0)
	
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
func _on_slime_spawn_requested(slime_name: String, aggression: int, defensive: int, food_pref: int, body_color: Color) -> void:
	pending_slime_name = slime_name
	pending_slime_aggression = aggression
	pending_slime_defensive = defensive
	pending_slime_food_pref = food_pref
	pending_slime_body_color = body_color
	current_mode = Mode.PLACE_SLIME
	# print("Slime placement mode active. Name: ", slime_name)

func _on_fruit_tree_requested() -> void:
	current_mode = Mode.PLACE_FRUIT_TREE
	# print("Fruit tree placement mode active.")

func _on_meat_bin_requested() -> void:
	current_mode = Mode.PLACE_MEAT_BIN
	# print("Meat bin placement mode active.")

func _on_multi_bin_requested() -> void:
	current_mode = Mode.PLACE_MULTI_BIN
	# print("Multi bin placement mode active.")

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

func try_inspect(clicked_node: Node) -> void:
	var node = clicked_node
	while node:
		if node.is_in_group("slimes"):
			inspect_entity(node)
			return
		if node.is_in_group("spawners"):
			inspect_entity(node)
			return
		node = node.get_parent()

func inspect_entity(entity: Node3D) -> void:
	# print("Inspecting: ", entity.name)
	inspected_entity = entity
	
	# Save current camera state
	saved_camera_position = global_position
	saved_camera_rotation = rotation
	saved_inner_camera_rotation = camera_3d.rotation
	camera_3d.rotation = Vector3.ZERO
	
	# Initial cinematic approach
	var slime_forward = entity.global_transform.basis.z
	var height_offset = inspect_distance * tan(deg_to_rad(inspect_angle_degrees))
	var initial_target = entity.global_position + slime_forward * inspect_distance + Vector3(0, height_offset, 0)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", initial_target, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_face_during_approach, 0.0, 1.0, 1.0)
	
	hud.show_inspection(entity)

func _face_during_approach(_progress: float) -> void:
	if inspected_entity:
		look_at(inspected_entity.global_position, Vector3.UP)

func _face_inspected_entity(_progress: float) -> void:
	if inspected_entity:
		look_at(inspected_entity.global_position, Vector3.UP)

func exit_inspection() -> void:
	inspected_entity = null
	hud.hide_inspection()
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", saved_camera_position, 2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", saved_camera_rotation, 2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Restore inner camera tilt at the end of the tween
	tween.chain().tween_callback(_restore_inner_camera)

func follow_inspected_entity(delta: float) -> void:
	var slime_pos = inspected_entity.global_position
	var slime_forward = inspected_entity.global_transform.basis.z
	
	var height_offset = inspect_distance * tan(deg_to_rad(inspect_angle_degrees))
	var target_pos = slime_pos + slime_forward * inspect_distance + Vector3(0, height_offset, 0)
	
	global_position = global_position.lerp(target_pos, follow_smoothness * delta)
	look_at(slime_pos, Vector3.UP)

func _restore_inner_camera() -> void:
	camera_3d.rotation = saved_inner_camera_rotation

func _on_remove_requested() -> void:
	if inspected_entity and is_instance_valid(inspected_entity):
		var entity_to_remove = inspected_entity
		exit_inspection()
		await get_tree().create_timer(0.5).timeout
		entity_to_remove.queue_free()

func zoom_camera(amount: float) -> void:
	current_zoom_y = clamp(current_zoom_y + amount, min_zoom_factor, max_zoom_factor)
	global_position.y = current_zoom_y

func _on_teleport_requested(world_pos: Vector3) -> void:
	var target = world_pos
	target.y = global_position.y
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", target, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
