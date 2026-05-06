class_name SlimeNode extends CharacterBody3D

@onready var stats: Statistics = $Stats
# Debugging tools
@onready var debug_label: Label3D = $DebugLabel
@export var debug_visible: bool = true

@export var slowing_radius: float = 2.0
@export var damping: float = 1.0
@export var gravity: float = 1.2

const DETECTION_RANGE: float = 10.0
const DETECTION_INTERVAL: float = 0.3
const SLIME_SCENE = preload("res://Scenes/Slime/SlimeScene.tscn")
const LEFT_EYE_SURFACE_INDEX := 1
const RIGHT_EYE_SURFACE_INDEX := 2

const AGG_COLORS = {
	0: Color(0.3, 0.8, 0.3), # Pacifist green
	1: Color(0.3, 0.5, 0.9), # Alpha blue
	2: Color(0.9, 0.3, 0.3)  # Killer red
}

const DEF_COLORS := {
	-1: Color(1.0, 1.0, 1.0),  # Default white
	0: Color(0.3, 0.9, 0.9),   # Pack cyan
	1: Color(1.0, 0.9, 0.2),   # Healthy yellow
	2: Color(1.0, 0.5, 0.1),   # Runner orange
	3: Color(0.0, 0.0, 0.0),   # Last Stand black (override anyway)
}

const COLOR_LAST_STAND := Color(0.0, 0.0, 0.0)

var nearby_slimes: Array = []
var nearest_other_slime: SlimeNode = null
var time_since_last_repro: float = 0.0
@export var speed_multiplier: float = 1.0

var last_attacker: SlimeNode = null

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func play_animation(anim_name: String) -> void:
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func _ready() -> void:
	add_to_group("slimes")
	stats.current_health = stats.max_health * Statistics.SPAWN_HEALTH_PERCENT
	print("HP Spawned in with : ", stats.current_health, " / ", stats.max_health)
	stats.level = 1
	stats.time_alive = 0.0
	if debug_label:
		debug_label.visible = debug_visible
	apply_eye_colors()

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
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
	
	var effective_max_speed = stats.speed * speed_multiplier
	var is_oneshot_playing = animation_player.current_animation in ["Eat", "Attack", "Death", "LevelUp", "Reproduce"]
	if velocity.length() > effective_max_speed:
		velocity = velocity.normalized() * effective_max_speed
		if not is_oneshot_playing:
			if animation_player.current_animation != "SlimeWalking":
				play_animation("SlimeWalking")
	else:
		if not is_oneshot_playing:
			if animation_player.current_animation != "Idle":
				play_animation("Idle")

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
	play_animation("Eat")
	if stats.kill_heal_only:
		print(name, " : kill heal only, cannot eat")
		# Last stand quirk: food will not help you
		return
	var cap = stats.max_health * stats.max_overeat_multiplier
	stats.current_health = min(stats.current_health + health_value, cap)
	
	print("Ate food HP now : ", stats.current_health)

func take_damage(amount: int, attacker: SlimeNode = null) -> void:
	var actual = max(0, amount - stats.defense)
	stats.current_health -= actual
	if stats.current_health <= 0:
		if attacker and is_instance_valid(attacker):
			attacker.gain_kill_health(self)
		die()
		return
		
	if attacker:
		react_to_attack(attacker)

func gain_kill_health(victim: SlimeNode) -> void:
	var heal_amount: float
	if stats.kill_heal_only:
		heal_amount = victim.stats.max_health * 0.5
	else:
		heal_amount = victim.stats.max_health * 0.15
	
	var cap = stats.max_health * stats.max_overeat_multiplier
	stats.current_health = min(stats.current_health + heal_amount, cap)
	print(name, " gained ", heal_amount, " HP from killing ", victim.name)

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
	$SteeringBehaviors.process_mode = Node.PROCESS_MODE_DISABLED
	$StateMachine.set_process(false)
	
	if animation_player.has_animation("Death"):
		animation_player.play("Death")
		await animation_player.animation_finished
	
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
	
	play_animation("LevelUp")
	await animation_player.animation_finished
	
	if randf() < chance:
		reproduce()

func reproduce() -> void:
	print(name, " reproduces!")

	if animation_player.has_animation("Reproduce"):
		animation_player.play("Reproduce")
		await animation_player.animation_finished

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
	child_stats.attack_range = stats.attack_range
	child_stats.attack_cooldown = stats.attack_cooldown
	child_stats.max_overeat_multiplier = stats.max_overeat_multiplier
	child_stats.slimeName = stats.slimeName + " Jr."
	
	# Mutate personality (mostly inherit from parent)
	child_stats.food_preference = mutate_value(stats.food_preference, [0, 1, 2], 0.2)
	child_stats.aggression_type = mutate_value(stats.aggression_type, [0, 1, 2], 0.1)
	child_stats.defensive_type = mutate_value(stats.defensive_type, [-1, 0, 1, 2, 3], 0.1)
	
	# Inherit kill_heal_only quirk (only Last Stand parents can pass it on)
	if stats.defensive_type == 3:
		if stats.kill_heal_only:
			# Already quirked — high chance to pass it on
			child_stats.kill_heal_only = randf() < 0.7
		else:
			# Last Stand but normal — small mutation chance
			child_stats.kill_heal_only = randf() < 0.1
	else:
		child_stats.kill_heal_only = false
	
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
	
	# Append quirk indicator
	if stats.kill_heal_only:
		def_str += "⚔"
	
	var hp_pct = stats.current_health / stats.max_health
	
	# Build XP progress string based on current level
	var xp_str: String
	if stats.level == 1:
		xp_str = "XP: %.1f / %.0f" % [stats.time_alive, Statistics.LEVEL_2_TIME]
	elif stats.level == 2:
		xp_str = "XP: %.1f / %.0f" % [stats.time_alive, Statistics.LEVEL_3_TIME]
	else:
		xp_str = "Repro: %.1f / %.0f" % [time_since_last_repro, Statistics.RECURRING_OFFSPRING_INTERVAL]
	
	debug_label.text = "%s — %s\nHP: %d/%d\n%s | %s\nLvl: %d\n%s" % [
		stats.slimeName,
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

func apply_eye_colors() -> void:
	var slime_mesh = get_node_or_null("SlimeMesh")
	if not slime_mesh:
		push_warning(name + " missing SlimeMesh")
		return
	
	var left_color: Color
	var right_color: Color
	
	if stats.defensive_type == 3:
		left_color = COLOR_LAST_STAND
		right_color = COLOR_LAST_STAND
	else:
		left_color = AGG_COLORS.get(stats.aggression_type, Color.WHITE)
		right_color = DEF_COLORS.get(stats.defensive_type, Color.WHITE)
	
	var left_mat = StandardMaterial3D.new()
	left_mat.albedo_color = left_color
	slime_mesh.set_surface_override_material(LEFT_EYE_SURFACE_INDEX, left_mat)
	
	var right_mat = StandardMaterial3D.new()
	right_mat.albedo_color = right_color
	slime_mesh.set_surface_override_material(RIGHT_EYE_SURFACE_INDEX, right_mat)	
