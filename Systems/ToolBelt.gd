extends Node

const SKILL_AXE     := "Woodcutting"
const SKILL_PICKAXE := "Mining"
const SKILL_ROD     := "Fishing"

var slots: Dictionary = { SKILL_AXE: null, SKILL_PICKAXE: null, SKILL_ROD: null }
signal belt_changed(skill: String, tool_id: String)

func has_tool_for(skill: String) -> bool:
	if not slots.has(skill): return false
	var tool = slots[skill]
	return tool != null and String(tool).strip_edges() != ""

func equip_tool(skill: String, tool_id: String) -> void:
	if not slots.has(skill): return
	slots[skill] = tool_id
	belt_changed.emit(skill, tool_id)

func unequip_tool(skill: String) -> void:
	if not slots.has(skill): return
	slots[skill] = null
	belt_changed.emit(skill, "")

func get_save_data() -> Dictionary:
	var d: Dictionary = {}
	for k in slots.keys(): d[String(k)] = slots[k]
	return d

func load_from_data(data: Dictionary) -> void:
	for k in slots.keys():
		if data.has(k): slots[k] = data[k]
	belt_changed.emit("", "")
