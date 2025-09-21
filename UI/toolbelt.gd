extends Control

var equipped_tools: Dictionary = {
	"Woodcutting": null,
	"Fishing": null,
	"Mining": null
}

@onready var wood_slot   : Control = $ToolBeltSlots/WoodcuttingSlot
@onready var fish_slot   : Control = $ToolBeltSlots/FishingSlot
@onready var mining_slot : Control = $ToolBeltSlots/MiningSlot

# Equip a tool (accepts full item dictionary)
func equip_tool(skill: String, item_data: Dictionary) -> void:
	if not equipped_tools.has(skill):
		print("[ToolBelt] Unknown skill:", skill)
		return

	equipped_tools[skill] = item_data

	# Update UI slot
	var slot_node: Control = get_toolbelt_slot(skill)
	if slot_node:
		if slot_node.has_method("set_item"):
			slot_node.set_item(item_data)
		if slot_node.has_method("set_tooltip_text") and item_data and item_data.has("name"):
			slot_node.set_tooltip_text(str(item_data.get("name","")))
	print("[ToolBelt] Equipped", skill, "→", item_data.get("name","EMPTY"))

func clear_tool(skill: String) -> void:
	if not equipped_tools.has(skill): return
	equipped_tools[skill] = null

	var slot_node: Control = get_toolbelt_slot(skill)
	if slot_node:
		if slot_node.has_method("set_item"):
			slot_node.set_item(null)
		if slot_node.has_method("set_tooltip_text"):
			slot_node.set_tooltip_text("")
	print("[ToolBelt] Cleared", skill)

func get_toolbelt_slot(skill: String) -> Control:
	match skill:
		"Woodcutting": return wood_slot
		"Fishing": return fish_slot
		"Mining": return mining_slot
	return null

func get_equipped_tool(skill: String):
	if equipped_tools.has(skill):
		return equipped_tools[skill]
	return null
