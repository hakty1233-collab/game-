extends Control

@export var skill_name: String = "Woodcutting"  # set per instance

@onready var bar: TextureProgressBar = $Bar
@onready var text: Label = $Text

func _ready() -> void:
	# visuals (optional; if you haven’t set textures in the inspector)
	# bar.texture_under = load("res://UI/otteria_bar_empty.png")
	# bar.texture_progress = load("res://UI/otteria_bar_fill_xp.png")
	bar.nine_patch_stretch = true

	# connect to updates
	SkillManager.skill_updated.connect(_on_skill_updated)
	SkillManager.level_up.connect(_on_level_up)

	_refresh()

func _xp_to_next(level: int) -> int:
	# match your SkillManager formula!
	return 20 + level * 10

func _refresh() -> void:
	if skill_name not in SkillManager.skills:
		return
	var s = SkillManager.skills[skill_name]
	var lvl: int = int(s["level"])
	var xp: int  = int(s["xp"])
	var needed: int = _xp_to_next(lvl)

	bar.min_value = 0
	bar.max_value = needed
	bar.value = xp

	text.text = "%s — %d/%d (Lv %d)".format([skill_name, xp, needed, lvl])

func _on_skill_updated(skill: String, level: int, xp: int) -> void:
	if skill == skill_name:
		_refresh()

func _on_level_up(skill: String, new_level: int) -> void:
	if skill == skill_name:
		_refresh()
