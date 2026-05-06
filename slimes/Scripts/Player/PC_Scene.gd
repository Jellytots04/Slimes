extends Node3D

@onready var hotbarUI: Control = $Camera3D/GameUI

# Camera Variables
@export var camSpeed: float = 10
@onready var marker: Marker3D = $RotationPoint # Unused and not added in yet

func _ready() -> void:
	# hotbarUI = $Camera3D/GameUI
	# hotbarUI.connect("buildingRequest", Callable(self, "placeBuilding"))
	# mapListener.connect("takeFunds", Callable(self, "moneyChange"))
	pass

# Add in the top down mouse camera movement.
func _process(delta: float) -> void:
	
	# Camera Inputs
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


# Camera functions
func forwardMotion(delta): # Should move at an angle 45 between negative x and z
	#var dir = Vector3(-1, 0, -1).normalized()
	var dir = -transform.basis.z 
	dir.y = 0
	dir = dir.normalized()
	position += dir * camSpeed * delta
		
func backwardMotion(delta): # Should move at an angle 45 between positive x and z
	var dir = transform.basis.z
	dir.y = 0
	dir = dir.normalized()
	position += dir * camSpeed * delta
	
func leftMotion(delta): # Should move at an angle 45 between negative x and positive z
	var dir = -transform.basis.x
	dir.y = 0
	dir = dir.normalized()
	position += dir * camSpeed * delta
	
func rightMotion(delta): # Should move at an angle 45 between positive x and negative z
	var dir = transform.basis.x
	dir.y = 0
	dir = dir.normalized()
	position += dir * camSpeed * delta

func turnLeft(): # Should rotate around a specific point

	var angle = -90
	var pivotPoint = marker.global_position
	var offset = global_position - pivotPoint
	var rotated_offset = offset.rotated(Vector3.UP, angle)

	global_position = pivotPoint + rotated_offset
	#print(global_position)
	rotation_degrees.y = rotation_degrees.y + angle

func turnRight():

	var angle = 90
	var pivotPoint = marker.global_position
	var offset = global_position - pivotPoint
	var rotated_offset = offset.rotated(Vector3.UP, angle)

	global_position = pivotPoint + rotated_offset
	#print(global_position)
	rotation_degrees.y = rotation_degrees.y + angle

# UI Logic requests
# Place a building request on the selected node, send signal to
# map to then place object on current selected node
