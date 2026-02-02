extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

var max_health: int = 5
var current_health: int = 5

func _ready():
	# Add background style to progress bar
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_bg.corner_radius_top_left = 2
	style_bg.corner_radius_top_right = 2
	style_bg.corner_radius_bottom_left = 2
	style_bg.corner_radius_bottom_right = 2
	progress_bar.add_theme_stylebox_override("background", style_bg)
	
	# Add fill style
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0, 0.8, 0.2, 1)
	style_fill.corner_radius_top_left = 2
	style_fill.corner_radius_top_right = 2
	style_fill.corner_radius_bottom_left = 2
	style_fill.corner_radius_bottom_right = 2
	progress_bar.add_theme_stylebox_override("fill", style_fill)
	
	hide()

# Initialize the health bar
func setup(max_hp: int, current_hp: int, resource_name: String):
	max_health = max_hp
	current_health = current_hp
	
	progress_bar.max_value = max_hp
	progress_bar.value = current_hp
	
	label.text = resource_name
	
	show()

# Update the health bar
func update_health(new_health: int):
	current_health = new_health
	progress_bar.value = current_health
	
	# Change color based on health percentage
	var health_percent = float(current_health) / float(max_health)
	
	# Get the fill style and update its color
	var style_fill = progress_bar.get_theme_stylebox("fill")
	if style_fill is StyleBoxFlat:
		if health_percent > 0.5:
			style_fill.bg_color = Color(0, 0.8, 0.2, 1)  # Green
		elif health_percent > 0.25:
			style_fill.bg_color = Color(0.9, 0.9, 0, 1)  # Yellow
		else:
			style_fill.bg_color = Color(0.9, 0.2, 0, 1)  # Red
	
	# Flash effect when hit
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.7, 0.1)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	
	if current_health <= 0:
		hide()

# Hide after delay (called when player stops gathering)
func hide_after_delay(delay: float = 3.0):
	await get_tree().create_timer(delay).timeout
	if current_health > 0:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		await tween.finished
		hide()
		modulate.a = 1.0  # Reset alpha for next time
