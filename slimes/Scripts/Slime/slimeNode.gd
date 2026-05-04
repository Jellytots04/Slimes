class_name SlimeNode extends CharacterBody3D

@onready var stats: Statistics = $Stats
# Debugging tools
@onready var debug_label: Label3D = $DebugLabel
@export var debug_visible: bool = true

@export var slowing_radius: float = 2.0
@export var damping: float = 1.0

const DETECTION_RANGE: float = 10.0
const DETECTION_INTERVAL: float = 0.3
const SLIME_SCENE = preload("res://Scenes/Slime/SlimeScene.tscn")

var nearby_slimes: Array = []
var nearest_other_slime: SlimeNode = null
var time_since_last_repro: float = 0.0
@export var speed_multiplier: float = 1.0

func _ready() -> void:
	add_to_group("slimes")
	stats.current_health = stats.max_health * Statistics.SPAWN_HEALTH_PERCENT
	print("HP Spawned in with : ", stats.current_health, " / ", stats.max_health)
	stats.level = 1
	stats.time_alive = 0.0
	if debug_label:
		debug_label.visible = debug_visible

func _process(delta: float) -> void:
	stats.time_alive += delta
	if stats.level >= 3:
		time_since_last_repro += delta
	check_level_up()
	update_debug_label()
	pass

func _physics_process(delta: float) -> void:
	var total_force := Vector3.ZERO
	var steering_root := $SteeringBehaviors
	for behavior in steering_root.get_children():
		if behavior is SteeringBehavior and behavior.enabled:
			total_force += behavior.calculate() * behavior.weight
			# print(total_force)
	
	total_force.y = 0
	
	velocity += total_force * delta
	# velocity = velocity.lerp(Vector3.ZERO, damping * delta)
	velocity.y = 0
	
	var effective_max_speed = stats.speed * speed_multiplier
	if velocity.length() > effective_max_speed:
		velocity = velocity.normalized() * effective_max_speed
	
	move_and_slide()
	
	if velocity.length() > 0.1:
		look_at(global_position - velocity, Vector3.UP)

func seek_force(target_pos) -> Vector3:
	var desired = (target_pos - global_position).normalized() * stats.speed
	return desired - velocity

func arrive_force(target_pos) -> Vector3:
	var to_target = target_pos - global_position
	to_target.y = 0
	var distance = to_target.length()
	
	if distance < 0.01:
		return -velocity * 10.0
		
	var desired_speed: float
	if distance >= slowing_radius:
		desired_speed = stats.speed
	else:
		desired_speed = stats.speed * 0.2
	
	var desired = to_target.normalized() * desired_speed
	return desired - velocity

func eat(health_value: int) -> void:
	var cap = stats.max_health * stats.max_overeat_multiplier
	stats.current_health = min(stats.current_health + health_value, cap)
	print("Ate food HP now : ", stats.current_health)

func take_damage(amount: int, attacker: SlimeNode = null) -> void:
	var actual = max(0, amount - stats.defense)
	stats.current_health -= actual
	if stats.current_health <= 0:
		die()
		return
		
	if attacker:
		react_to_attack(attacker)

func react_to_attack(attacker: SlimeNode) -> void:
	var hp_pct = stats.current_health / stats.max_health
	var should_fight = not should_stop_combat()
	
	var sm = $StateMachine
	
	print(name, " hit. HP%: ", hp_pct, " | defensive_type: ", stats.defensive_type, " | fight: ", should_fight)
	if should_fight:
		var combat_state = sm.get_node("../states/CombatState")
		if sm.current_state != combat_state:
			combat_state.set_target(attacker)
			sm.change_state(combat_state)
	else:
		var flee_state = sm.get_node("../states/FleeState")
		if sm.current_state != flee_state:
			flee_state.set_threat(attacker)
			sm.change_state(flee_state)

func should_stop_combat() -> bool:
	var hp_pct = stats.current_health / stats.max_health
	
	match stats.defensive_type:
		0: return get_nearby_flocker().size() == 0
		1: return hp_pct <= 0.5
		2: return hp_pct <= 0.75
		3: return false
		-1: 
			if stats.aggression_type == 2:
				return hp_pct <= 0.25
			return false
	return false

func die() -> void:
	queue_free()

func _decay_timer_timeout() -> void:
	var decay_rate: float
	if stats.current_health > stats.max_health:
		decay_rate = Statistics.OVEREAT_DECAY_RATE
	else:
		decay_rate = Statistics.HEALTH_DECAY_RATE

	stats.current_health -= Statistics.HEALTH_DECAY_RATE
	# stats.current_health -= decay_rate * delta
	print("HP: ", stats.current_health, " : From : ", self)

	if stats.current_health <= 0:
		print("DIED")
		die()
		return

func _on_deteciton_timer_timeout() -> void:
	update_nearby_slimes()

func update_nearby_slimes() -> void:
	nearby_slimes.clear()
	nearest_other_slime = null
	var nearest_distance = DETECTION_RANGE
	
	var all_slimes = get_tree().get_nodes_in_group("slimes")
	for slime in all_slimes:
		if slime == self:
			continue
		if not is_instance_valid(slime):
			continue
		
		var distance: float = slime.global_position.distance_to(global_position)
		if distance > DETECTION_RANGE:
			continue
		
		nearby_slimes.append(slime)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_other_slime = slime

func get_nearby_flocker() -> Array:
	var result = []
	for other in nearby_slimes:
		if not is_instance_valid(other):
			continue
		if other.stats.aggression_type == 0:
			result.append(other)
	return result

# Level up functions
func check_level_up() -> void:
	if stats.level == 1 and stats.time_alive >= Statistics.LEVEL_2_TIME:
		stats.level = 2
		on_level_up()
	elif stats.level == 2 and stats.time_alive >= Statistics.LEVEL_3_TIME:
		stats.level = 3
		on_level_up()
	elif stats.level >= 3:
		check_recurring_reproduction()

func check_recurring_reproduction() -> void:
	if time_since_last_repro >= Statistics.RECURRING_OFFSPRING_INTERVAL:
		time_since_last_repro = 0.0
		print(name, " rolling for recurring reproduction")
		if randf() < 0.5:
			reproduce()

func on_level_up() -> void:
	print(name, " leveled up to ", stats.level)
	var chance: float = 0.0
	if stats.level == 2:
		chance = 0.5
	elif stats.level == 3:
		chance = 1.0
		time_since_last_repro = 0.0 # Start the recurring timer
	
	if randf() < chance:
		reproduce()

func reproduce() -> void:
	print(name, " reproduces!")
	
	var offspring = SLIME_SCENE.instantiate()
	
	# Position offset
	var offset = Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
	offspring.position = position + offset
	
	# Randomise body stats BEFORE adding to tree (so _ready uses correct max_health)
	var child_stats = offspring.get_node("Stats")
	child_stats.max_health = randi_range(70, 130)
	child_stats.damage = randi_range(5, 20)
	child_stats.defense = randi_range(0, 5)
	child_stats.speed = randf_range(2.5, 4.0)
	child_stats.attack_range = stats.attack_range  # inherit, not randomise
	child_stats.attack_cooldown = stats.attack_cooldown  # inherit
	child_stats.max_overeat_multiplier = stats.max_overeat_multiplier  # inherit
	
	# Mutate personality (mostly inherit from parent)
	child_stats.food_preference = mutate_value(stats.food_preference, [0, 1, 2], 0.2)
	child_stats.aggression_type = mutate_value(stats.aggression_type, [0, 1, 2], 0.1)
	child_stats.defensive_type = mutate_value(stats.defensive_type, [-1, 0, 1, 2, 3], 0.1)
	
	# Add to scene (triggers offspring._ready, which now sees the new max_health)
	get_parent().add_child(offspring)

func mutate_value(parent_value, possible_values: Array, mutation_chance: float):
	if randf() < mutation_chance:
		return possible_values.pick_random()
	return parent_value

# Debugging functions
func update_debug_label() -> void:
	if not debug_label or not debug_visible:
		return
	
	var sm = $StateMachine
	var state_name = "?"
	if sm.current_state:
		var script = sm.current_state.get_script()
		if script:
			state_name = script.resource_path.get_file().get_basename()
	
	var agg_names = ["Pacifist", "Alpha", "Killer"]
	var def_names = {-1: "Default", 0: "Pack", 1: "Healthy", 2: "Runner", 3: "LastStand"}
	
	var agg_str = agg_names[stats.aggression_type] if stats.aggression_type < agg_names.size() else "?"
	var def_str = def_names.get(stats.defensive_type, "?")
	
	var hp_pct = stats.current_health / stats.max_health
	
	# Build XP progress string based on current level
	var xp_str: String
	if stats.level == 1:
		xp_str = "XP: %.1f / %.0f" % [stats.time_alive, Statistics.LEVEL_2_TIME]
	elif stats.level == 2:
		xp_str = "XP: %.1f / %.0f" % [stats.time_alive, Statistics.LEVEL_3_TIME]
	else:
		# Level 3+ — show time since last reproduction roll
		xp_str = "Repro: %.1f / %.0f" % [time_since_last_repro, Statistics.RECURRING_OFFSPRING_INTERVAL]
	
	debug_label.text = "%s\nHP: %d/%d\n%s | %s\nLvl: %d\n%s" % [
		state_name,
		int(stats.current_health),
		int(stats.max_health),
		agg_str,
		def_str,
		stats.level,
		xp_str
	]
	
	if hp_pct < 0.3:
		debug_label.modulate = Color.RED
	elif hp_pct < 0.7:
		debug_label.modulate = Color.YELLOW
	else:
		debug_label.modulate = Color.WHITE
