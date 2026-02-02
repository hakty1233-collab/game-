extends Node

const SKILL_AXE     := "Woodcutting"
const SKILL_PICKAXE := "Mining"
const SKILL_ROD     := "Fishing"

# Store full item data, not just tool_id strings
var slots: Dictionary = { SKILL_AXE: null, SKILL_PICKAXE: null, SKILL_ROD: null }
signal belt_changed(skill: String, tool_name: String)

func has_tool_for(skill: String) -> bool:
	if not slots.has(skill): 
		return false
	var tool = slots[skill]
	# Check if we have a valid tool (either string or dict with name)
	if tool == null:
		return false
	if tool is String:
		return tool.strip_edges() != ""
	if tool is Dictionary:
		return tool.get("name", "").strip_edges() != ""
	return false

func equip_tool(skill: String, tool_name: String) -> void:
	if not slots.has(skill): 
		return
	
	print("[ToolBelt] Equipping %s for %s" % [tool_name, skill])
	
	# Store the tool name as a string (simpler and matches your item_slot.gd expectations)
	slots[skill] = tool_name
	
	# Emit with the tool name
	belt_changed.emit(skill, tool_name)
	
	print("[ToolBelt] Current slots: ", slots)

func unequip_tool(skill: String) -> String:
	if not slots.has(skill): 
		return ""
	
	var old_tool = slots[skill]
	var tool_name = ""
	
	# Get the tool name whether it's a string or dict
	if old_tool is String:
		tool_name = old_tool
	elif old_tool is Dictionary:
		tool_name = old_tool.get("name", "")
	
	slots[skill] = null
	belt_changed.emit(skill, "")
	
	return tool_name

func get_equipped_tool(skill: String):
	if not slots.has(skill):
		return null
	return slots[skill]

func get_save_data() -> Dictionary:
	var d: Dictionary = {}
	for k in slots.keys(): 
		var tool = slots[k]
		if tool is String:
			d[String(k)] = tool
		elif tool is Dictionary:
			d[String(k)] = tool.get("name", "")
		else:
			d[String(k)] = null
	return d

func load_from_data(data: Dictionary) -> void:
	for k in slots.keys():
		if data.has(k): 
			slots[k] = data[k]
	belt_changed.emit("", "")
