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

func on_interact() -> void:
	if not _available:
		print("[%s] Not available yet (respawning)" % skill_name)
		return

	# Tool gate - IMPROVED CHECK
	if not _has_required_tool():
		_show_tool_required_message()
		return

	# Level gate
	var level := int((SkillManager.skills.get(skill_name, {"level":1}) as Dictionary).get("level", 1))
	if level < required_level:
		print("[%s] You need %s level %d (you have %d)" % [skill_name, skill_name, required_level, level])
		return

	await _do_action_and_reward()

# IMPROVED: Better tool checking
func _has_required_tool() -> bool:
	# Check if ToolBelt exists
	if not has_node("/root/ToolBelt"):
		print("[%s] ToolBelt autoload not found!" % skill_name)
		return false
	
	var toolbelt = get_node("/root/ToolBelt")
	
	# Check if has_tool_for method exists
	if not toolbelt.has_method("has_tool_for"):
		print("[%s] ToolBelt missing has_tool_for method!" % skill_name)
		return false
	
	# Check if player has the required tool equipped
	var has_tool = toolbelt.has_tool_for(skill_name)
	print("[%s] Tool check - has_tool: %s" % [skill_name, has_tool])
	
	return has_tool

# IMPROVED: Show helpful message about which tool is needed
func _show_tool_required_message() -> void:
	var tool_needed = ""
	match skill_name:
		"Woodcutting":
			tool_needed = "an axe (like Bronze Axe)"
		"Mining":
			tool_needed = "a pickaxe (like Bronze Pickaxe)"
		"Fishing":
			tool_needed = "a fishing rod (like Basic Rod)"
		_:
			tool_needed = "the proper tool"
	
	print("[%s] You need %s equipped! Check your inventory and left-click a tool to equip it." % [skill_name, tool_needed])

func _do_action_and_reward() -> void:
	_available = false
	print("[%s] Starting action..." % skill_name)

	# "work" time
	await get_tree().create_timer(max(action_time, 0.05)).timeout

	# XP
	SkillManager.add_xp(skill_name, xp_reward)
	print("[%s] Gained %d XP" % [skill_name, xp_reward])

	# Loot
	for d in drops:
		var name := String(d.get("name", "Item"))
		var mn := int(d.get("min", 1))
		var mx := int(d.get("max", 1))
		var qty := randi_range(mn, mx)
		if qty > 0:
			PlayerInventory.add_item({"name": name, "quantity": qty})
			print("[%s] Received %d x %s" % [skill_name, qty, name])

	# Call depletion hook
	_on_depleted()
	monitoring = false

	# Wait for respawn
	print("[%s] Respawning in %.1f seconds..." % [skill_name, respawn_time])
	await get_tree().create_timer(respawn_time).timeout

	# Call respawn hook
	_on_respawned()
	monitoring = true
	_available = true
	print("[%s] Respawned!" % skill_name)

# ---------- Hooks (default = hide/show node) ----------
func _on_depleted() -> void:
	visible = false

func _on_respawned() -> void:
	visible = true
