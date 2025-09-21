extends Control

@export var skill_name: String = "Woodcutting"
@export var icon_path: NodePath
@export var level_path: NodePath

@onready var icon_rect: TextureRect = get_node_or_null(icon_path) as TextureRect
@onready var level_label: Label     = get_node_or_null(level_path) as Label

func _ready() -> void:
	# Fallback to common child names if paths not set
	if icon_rect == null:  icon_rect  = get_node_or_null("Icon") as TextureRect
	if level_label == null: level_label = get_node_or_null("Level") as Label

	# Set icon (per-skill file or placeholder)
	var icon := _get_skill_icon(skill_name)
	if icon_rect and icon: icon_rect.texture = icon

	# Initial level text
	_refresh_tile()

	# Listen for updates just once (this tile only updates when its skill changes)
	SkillManager.skill_updated.connect(_on_skill_updated)
	SkillManager.level_up.connect(_on_level_up)

func _exit_tree() -> void:
	# (Godot auto-disconnects on free, but this is safe if you reuse tiles)
	if SkillManager.is_connected("skill_updated", Callable(self, "_on_skill_updated")):
		SkillManager.skill_updated.disconnect(Callable(self, "_on_skill_updated"))
	if SkillManager.is_connected("level_up", Callable(self, "_on_level_up")):
		SkillManager.level_up.disconnect(Callable(self, "_on_level_up"))

func _on_skill_updated(name: String, lvl: int, xp: int) -> void:
	if name == skill_name:
		_refresh_tile()

func _on_level_up(name: String, new_level: int) -> void:
	if name == skill_name:
		_refresh_tile()
		_flash_level() # small feedback

func _refresh_tile() -> void:
	if not level_label: return
	var data = SkillManager.skills.get(skill_name, null)
	if data:
		level_label.text = "Lv %d" % int(data["level"])
		tooltip_text = "%s — Lv %d\nXP: %d" % [skill_name, int(data["level"]), int(data["xp"])]

func _get_skill_icon(skill_name: String) -> Texture2D:
	var p := "res://UI/Skills/%s.png" % skill_name
	if ResourceLoader.exists(p):
		return load(p) as Texture2D
		var fallback := "res://UI/Skills/placeholder.png"
		if ResourceLoader.exists(fallback):
			return load(fallback) as Texture2D
			return Texture2D.new()  # <- guaranteed return


func _flash_level() -> void:
	# simple visual feedback on level up
	if not level_label: return
	level_label.modulate = Color(1, 1, 0.5) # warm tint
	await get_tree().create_timer(0.2).timeout
	level_label.modulate = Color(1, 1, 1)
