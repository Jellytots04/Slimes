extends Control

@onready var subviewport: SubViewport = $SubViewportContainer/SubViewport
@onready var minimap_camera: Camera3D = $SubViewportContainer/SubViewport/MinimapCamera

signal teleport_requested(world_pos: Vector3)


func _ready() -> void:
	subviewport.world_3d = get_tree().root.world_3d
	gui_input.connect(_on_minimap_clicked)


func _on_minimap_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_pos = minimap_to_world(event.position)
		teleport_requested.emit(world_pos)


func minimap_to_world(click_pos: Vector2) -> Vector3:
	var size_pixels = self.size
	
	var u = click_pos.x / size_pixels.x
	var v = click_pos.y / size_pixels.y
	
	var cam_pos = minimap_camera.global_position
	var minimap_size_world = minimap_camera.size
	
	var world_x = cam_pos.x + (u - 0.5) * minimap_size_world
	var world_z = cam_pos.z + (v - 0.5) * minimap_size_world
	
	return Vector3(-world_x, 0, -world_z)
