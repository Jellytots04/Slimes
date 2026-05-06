extends Control

signal slime_spawn_requested(slime_name: String, aggression: int, defensive: int, food_pref: int, body_color: Color)
signal fruit_tree_spawn_requested
signal meat_bin_spawn_requested
signal multi_bin_spawn_requested

@onready var slime_attributes: Control = %SlimeAttributes
@onready var color_picker: ColorPicker = %ColorPicker
@onready var color_button: Button = %ColorButton

@onready var defense_vbox: Control = %DefenseType
@onready var aggression_vbox: Control = %AggressionType
@onready var food_vbox: Control = %FoodType
@onready var name_input: LineEdit = %LineEdit

var current_color: Color = Color.WHITE

func _ready() -> void:
	slime_attributes.hide()
	color_picker.hide()
	color_picker.color_changed.connect(_on_color_changed)
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
