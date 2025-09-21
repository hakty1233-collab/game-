extends Control

@export var skill_name: String = "Woodcutting"
signal hovered(skill: String, global_pos: Vector2)
signal unhovered()

@onready var icon = $Icon
@onready var level_label = $Level

func _ready() -> void:
	_update_tile()
	SkillManager.skill_updated.connect(_on_skill_changed)
	SkillManager.level_up.connect(_on_skill_changed)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func _update_tile() -> void:
	if skill_name in SkillManager.skills:
		var lvl: int = int(SkillManager.skills[skill_name]["level"])
		level_label.text = str(lvl)
		# Icon atlas example
		var tex_path = "res://UI/Icons/Woodcutting_Icon.png"
		if ResourceLoader.exists(tex_path):
			icon.texture = load(tex_path)

func _on_skill_changed(_skill: String, _lvl: int, _xp: int) -> void:
	if _skill == skill_name:
		_update_tile()

func _on_mouse_entered() -> void:
	hovered.emit(skill_name, get_global_mouse_position())

func _on_mouse_exited() -> void:
	unhovered.emit()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		hovered.emit(skill_name, get_global_mouse_position())
	elif event is InputEventScreenTouch and not event.pressed:
		unhovered.emit()
