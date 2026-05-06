extends Control

signal slime_spawn_requested(slime_name: String, aggression: int, defensive: int, food_pref: int, body_color: Color)
signal fruit_tree_spawn_requested
signal meat_bin_spawn_requested
signal multi_bin_spawn_requested
signal remove_requested

@onready var creation_hud: Control = %UITaskBar
@onready var slime_attributes: Control = %SlimeAttributes
@onready var color_picker: ColorPicker = %ColorPicker
@onready var color_button: Button = %ColorButton

@onready var defense_vbox: Control = %DefenseType
@onready var aggression_vbox: Control = %AggressionType
@onready var food_vbox: Control = %FoodType
@onready var name_input: LineEdit = %LineEdit

@onready var inspection_hud: Control = %InspectionHUD
@onready var inspect_name: Label = %Name
@onready var inspect_aggression: Label = %Aggression
@onready var inspect_defensive: Label = %Defensive
@onready var inspect_food: Label = %Food
@onready var inspect_level: Label = %Lvl
@onready var remove_button: Button = %RemoveButton

@onready var title_aggression: Label = %AggressionTitle
@onready var title_defensive: Label = %DefensiveTitle
@onready var title_food: Label = %FoodTitle
@onready var title_level: Label = %Level

var current_color: Color = Color.WHITE

func _ready() -> void:
	slime_attributes.hide()
	color_picker.hide()
	inspection_hud.hide()
	color_picker.color_changed.connect(_on_color_changed)
	remove_button.pressed.connect(_on_remove_button_pressed)
	_update_button_color()

func reset_after_placement() -> void:
	slime_attributes.hide()

func _on_spawn_slime_button_pressed() -> void:
	if slime_attributes.visible:
		var slime_name = name_input.text.strip_edges()
		if slime_name == "":
			slime_name = "Jane Doe"  # fallback to default
		
		var aggression = _get_dropdown_value(aggression_vbox)
		var defensive = _get_dropdown_value(defense_vbox)
		var food_pref = _get_dropdown_value(food_vbox)
		slime_spawn_requested.emit(slime_name, aggression, defensive, food_pref, current_color)
	else:
		slime_attributes.show()

func _on_spawn_fruit_tree_button_pressed() -> void:
	fruit_tree_spawn_requested.emit()

func _on_spawn_meat_bin_button_pressed() -> void:
	meat_bin_spawn_requested.emit()

func _on_spawn_multi_bin_button_pressed() -> void:
	multi_bin_spawn_requested.emit()

func _on_color_button_pressed() -> void:
	if color_picker.visible:
		color_picker.hide()
		defense_vbox.show()
		aggression_vbox.show()
		food_vbox.show()
	else:
		color_picker.show()
		defense_vbox.hide()
		aggression_vbox.hide()
		food_vbox.hide()

func _on_color_changed(color: Color) -> void:
	current_color = color
	_update_button_color()

func _update_button_color() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = current_color
	color_button.add_theme_stylebox_override("normal", style)
	color_button.add_theme_stylebox_override("hover", style)
	color_button.add_theme_stylebox_override("pressed", style)

func _get_dropdown_value(vbox: Control) -> int:
	for child in vbox.get_children():
		if child is OptionButton:
			return child.get_selected_id()
	return 0

func show_inspection(entity: Node3D) -> void:
	creation_hud.hide()
	inspection_hud.show()
	populate_inspection(entity)

func hide_inspection() -> void:
	inspection_hud.hide()
	creation_hud.show()

func populate_inspection(entity: Node3D) -> void:
	if entity.is_in_group("slimes"):
		populate_slime_stats(entity)
	elif entity.is_in_group("spawners"):
		populate_spawner_stats(entity)

func populate_slime_stats(slime: Node3D) -> void:
	var stats = slime.get_node("Stats")
	
	var agg_names = ["Pacifist", "Alpha", "Killer"]
	var def_names = {-1: "Default", 0: "Pack", 1: "Healthy", 2: "Runner", 3: "LastStand"}
	var food_names = ["Any", "Meat", "Fruit"]
	
	# Set slime-appropriate titles
	title_aggression.text = "Aggression Type"
	title_defensive.text = "Defensive Type"
	title_food.text = "Food Preference"
	title_level.text = "Level"
	
	# Set values
	inspect_name.text = stats.slimeName
	inspect_aggression.text = agg_names[stats.aggression_type] if stats.aggression_type < agg_names.size() else "?"
	
	var def_str = def_names.get(stats.defensive_type, "?")
	if stats.kill_heal_only:
		def_str += " ⚔"
	inspect_defensive.text = def_str
	
	inspect_food.text = food_names[stats.food_preference] if stats.food_preference < food_names.size() else "?"
	inspect_level.text = "%d" % stats.level

func populate_spawner_stats(spawner: Node3D) -> void:
	var type_names = ["Meat", "Fruit", "Multi"]
	
	title_aggression.text = "Spawner Type"
	title_defensive.text = "Spawn Interval"
	title_food.text = "Food Count"
	title_level.text = "Spawn Radius"
	
	inspect_name.text = spawner.name
	inspect_aggression.text = type_names[spawner.spawner_type] if spawner.spawner_type < type_names.size() else "?"
	inspect_defensive.text = "%.1fs" % spawner.spawn_interval
	inspect_food.text = "%d / %d" % [spawner.spawned_food.size(), spawner.max_food]
	inspect_level.text = "%dm" % int(spawner.spawn_radius)

func _on_remove_button_pressed() -> void:
	remove_requested.emit()
