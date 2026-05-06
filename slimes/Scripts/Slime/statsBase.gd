# Statistics.gd
class_name Statistics extends Node

# Constants for tuning
const HEALTH_DECAY_RATE := 0.5
const OVEREAT_DECAY_RATE := 3.0
const LEVEL_2_TIME := 5.0
const LEVEL_3_TIME := 15.0
const RECURRING_OFFSPRING_INTERVAL := 20.0
const SPAWN_HEALTH_PERCENT := 0.75

# Per-slime statistics
@export var slimeName: String = "Jane Doe"
@export var max_health: float
@export var damage: int
@export var defense: int
@export var speed: float
@export var attack_range: float
@export var attack_cooldown: int
@export var max_overeat_multiplier: float = 1.5

# Personality type 
@export var food_preference: int # 0, 1, 2: Three different food types
@export var aggression_type: int # 0, 1, 2: Different aggression type to define AI style
@export var defensive_type: int = -1 # -1, 0, 1, 2, 3: Defensive types to define how it responds to attacks

# Super special personality
@export var kill_heal_only: bool = false

# Runtime state
var current_health: int
var level: int = 1 # 1, 2, 3
var time_alive: float = 0.0 # For levelling
var time_since_last_offspring: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_health = max_health * SPAWN_HEALTH_PERCENT

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
