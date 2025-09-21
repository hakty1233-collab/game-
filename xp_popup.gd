extends Control

@onready var skill_icon: TextureRect = $TextureRect
@onready var xp_label: Label = $Label
@onready var xp_bar: TextureProgressBar = $TextureProgressBar

var life_time := 2.0  # seconds before fade out

func setup(skill_name: String, xp_gain: int, current_xp: int, xp_for_next: int, icon: Texture2D):
	skill_icon.texture = icon
	xp_label.text = "+%d" % xp_gain
	xp_bar.value = float(current_xp) / float(xp_for_next) * 100.0

	modulate = Color(1, 1, 1, 1) # reset alpha
	show()

	# fade after life_time
	await get_tree().create_timer(life_time).timeout
	_fade_out()

func _fade_out():
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.finished.connect(queue_free)
