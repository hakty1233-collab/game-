extends Area2D
class_name BaseGatherNode

@export var skill_name: String = ""          # "Woodcutting" / "Mining" / "Fishing"
@export var required_level: int = 1
@export var action_time: float = 1.2         # time to gather
@export var xp_reward: int = 10
@export var respawn_time: float = 12.0
@export var drops: Array[Dictionary] = [     # [{name:"Log", min:1, max:2}]
	{"name":"Item", "min":1, "max":1}
]

var _can_interact := false
var _available := true

func _ready() -> void:
	add_to_group("interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(b: Node) -> void:
	if b.is_in_group("player"):
		_can_interact = true

func _on_body_exited(b: Node) -> void:
	if b.is_in_group("player"):
		_can_interact = false

func _unhandled_input(event: InputEvent) -> void:
	if _can_interact and event.is_action_pressed("interact"):
		on_interact()

func on_interact() -> void:
	if not _available:
		return

	# Tool gate
	if typeof(ToolBelt) == TYPE_NIL or not ToolBelt.has_tool_for(skill_name):
		print("You need the proper tool equipped for %s." % skill_name)
		return

	# Level gate
	var level := int((SkillManager.skills.get(skill_name, {"level":1}) as Dictionary).get("level", 1))
	if level < required_level:
		print("You need %s level %d." % [skill_name, required_level])
		return

	await _do_action_and_reward()

func _do_action_and_reward() -> void:
	_available = false

	# “work” time
	await get_tree().create_timer(max(action_time, 0.05)).timeout

	# XP
	SkillManager.add_xp(skill_name, xp_reward)

	# Loot
	for d in drops:
		var name := String(d.get("name", "Item"))
		var mn := int(d.get("min", 1))
		var mx := int(d.get("max", 1))
		var qty := randi_range(mn, mx)
		if qty > 0:
			PlayerInventory.add_item({"name": name, "quantity": qty})

	# Call depletion hook
	_on_depleted()
	monitoring = false

	# Wait for respawn
	await get_tree().create_timer(respawn_time).timeout

	# Call respawn hook
	_on_respawned()
	monitoring = true
	_available = true

# ---------- Hooks (default = hide/show node) ----------
func _on_depleted() -> void:
	visible = false

func _on_respawned() -> void:
	visible = true
