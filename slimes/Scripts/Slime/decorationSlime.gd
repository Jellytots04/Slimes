extends CharacterBody3D

@export var wander_speed: float = 1.0
@export var change_target_interval: float = 3.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var walking_sound: AudioStreamPlayer3D = $Audio/WalkingSound

var target_position: Vector3
var time_until_new_target: float = 0.0

func _ready() -> void:
	pick_new_target()
	if animation_player.has_animation("Idle"):
		animation_player.play("Idle")

func _physics_process(delta: float) -> void:
	time_until_new_target -= delta
	if time_until_new_target <= 0:
		pick_new_target()
	
	var direction = (target_position - global_position)
	direction.y = 0
	var distance = direction.length()
	
	if distance > 0.5:
		direction = direction.normalized()
		velocity = direction * wander_speed
		look_at(global_position - direction, Vector3.UP)
		
		if animation_player.current_animation != "SlimeWalking":
			animation_player.play("SlimeWalking")
		if not walking_sound.playing:
			walking_sound.play()
	else:
		velocity = Vector3.ZERO
		if animation_player.current_animation != "Idle":
			animation_player.play("Idle")
		if walking_sound.playing:
			walking_sound.stop()
	
	move_and_slide()

func pick_new_target() -> void:
	var angle = randf() * TAU
	var distance = randf_range(2.0, 5.0)
	target_position = global_position + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	time_until_new_target = change_target_interval + randf_range(-1.0, 1.0)
