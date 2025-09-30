extends Control

# ---------- Item ----------
var item: Dictionary = {}

# ---------- Icon dictionary ----------
var ICONS: Dictionary = {
	"raw_fish": preload("res://UI/Items/raw_fish.png"),
	"iron_ore": preload("res://UI/Items/stone.png"),
	"log": preload("res://UI/Items/log.png"),
	"cooked_fish": preload("res://UI/Items/cooked_fish.png"),
	"copper_bar": preload("res://UI/Items/copper_bar.png"),
	"plank": preload("res://UI/Items/plank.png"),
	"copper_ore": preload("res://UI/Items/copper_ore.png"),
	
	# Add tool icons (using placeholders for now)
	"bronze_axe": preload("res://UI/Items/fishing_rod.png"),       # placeholder
	"basic_rod": preload("res://UI/Items/fishing_rod.png"),   # placeholder
	"bronze_pickaxe": preload("res://UI/Items/fishing_rod.png")  # placeholder
}

# Tool to skill mapping
var TOOL_SKILLS: Dictionary = {
	"bronze_axe": "Woodcutting",
	"iron_axe": "Woodcutting",
	"basic_rod": "Fishing", 
	"advanced_rod": "Fishing",
	"bronze_pickaxe": "Mining",
	"iron_pickaxe": "Mining"
}

# ---------- Helpers ----------
func normalize_name(name: String) -> String:
	return name.to_lower().replace(" ", "_")

func has_icon(name: String) -> bool:
	return ICONS.has(normalize_name(name))

func get_icon(name: String) -> Texture2D:
	var key: String = normalize_name(name)
	if ICONS.has(key):
		return ICONS[key] as Texture2D
	return null

func is_tool(item_name: String) -> bool:
	var key = normalize_name(item_name)
	return TOOL_SKILLS.has(key)

func get_tool_skill(item_name: String) -> String:
	var key = normalize_name(item_name)
	return TOOL_SKILLS.get(key, "")

# ---------- Set item ----------
func set_item(d: Dictionary) -> void:
	item = d.duplicate(true)
	
	# Quantity label
	var qty_node: Label = get_node_or_null("Qty")
	if qty_node:
		var qty = int(item.get("quantity", 1))
		if qty > 1:
			qty_node.text = "x%d" % qty
			qty_node.visible = true
		else:
			qty_node.visible = false
	
	# Icon assignment
	var icon_node: TextureRect = find_icon_node()
	if icon_node:
		var key: String = item.get("key","")
		var tex: Texture2D = get_icon(key) as Texture2D
		if tex != null:
			icon_node.texture = tex
		else:
			icon_node.texture = null
			print("[ItemSlot] No icon found for key:", key)
	
	# Update tooltip and make clickable
	_update_tooltip()
	mouse_filter = Control.MOUSE_FILTER_PASS

func _update_tooltip():
	var item_name = String(item.get("name", "?"))
	var quantity = int(item.get("quantity", 1))
	
	tooltip_text = item_name
	if quantity > 1:
		tooltip_text += " x%d" % quantity
	
	# Add tool info
	if is_tool(item_name):
		var skill = get_tool_skill(item_name)
		tooltip_text += "\n[Tool - %s]" % skill
		tooltip_text += "\nClick to equip"

# ---------- Mouse interaction ----------
func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_item_clicked()

func _on_item_clicked():
	if item.is_empty():
		return
	
	var item_name = String(item.get("name", ""))
	print("[ItemSlot] Clicked item: %s" % item_name)
	
	# Check if this is a tool
	if is_tool(item_name):
		_try_equip_tool(item_name)

func _try_equip_tool(tool_name: String):
	var skill = get_tool_skill(tool_name)
	if skill == "":
		print("[ItemSlot] Unknown skill for tool: %s" % tool_name)
		return
	
	print("[ItemSlot] === EQUIPPING TOOL ===")
	print("[ItemSlot] Tool: %s, Skill: %s" % [tool_name, skill])
	
	# Check if we have this tool in inventory
	var has_tool = PlayerInventory.has_at_least(tool_name, 1)
	if not has_tool:
		print("[ItemSlot] Tool not found in inventory: %s" % tool_name)
		return
	
	# Remove tool from inventory
	var removed = PlayerInventory.remove_item(tool_name, 1)
	if removed > 0:
		print("[ItemSlot] Removed %d %s from inventory" % [removed, tool_name])
		
		# Equip the tool
		ToolBelt.equip_tool(skill, tool_name)
		print("[ItemSlot] Called ToolBelt.equip_tool(%s, %s)" % [skill, tool_name])
		print("[ItemSlot] ToolBelt.slots after equip: ", ToolBelt.slots)
		
		# Show feedback
		print("[ItemSlot] Equipped %s for %s skill" % [tool_name, skill])
		_show_equip_feedback(tool_name)
	else:
		print("[ItemSlot] Failed to remove tool from inventory")

func _show_equip_feedback(tool_name: String):
	# Create floating "Equipped!" text
	var feedback_label = Label.new()
	feedback_label.text = "Equipped!"
	feedback_label.modulate = Color.GREEN
	feedback_label.z_index = 100
	feedback_label.position = global_position + Vector2(0, -20)
	
	get_tree().current_scene.add_child(feedback_label)
	
	# Animate the feedback
	var tween = create_tween()
	tween.parallel().tween_property(feedback_label, "position:y", feedback_label.position.y - 30, 1.0)
	tween.parallel().tween_property(feedback_label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(func(): feedback_label.queue_free())

# ---------- Visual feedback ----------
func _on_mouse_entered():
	if not item.is_empty():
		if is_tool(String(item.get("name", ""))):
			modulate = Color(1.2, 1.5, 1.2)  # Green tint for tools
		else:
			modulate = Color(1.2, 1.2, 1.2)  # Normal brighten

func _on_mouse_exited():
	modulate = Color.WHITE

# ---------- Find icon node safely ----------
func find_icon_node() -> TextureRect:
	var node: TextureRect = get_node_or_null("Icon")
	if node:
		return node
	return get_node_or_null_recursive(self)

func get_node_or_null_recursive(parent: Node) -> TextureRect:
	for child in parent.get_children():
		if child is TextureRect:
			return child
		var sub: TextureRect = get_node_or_null_recursive(child)
		if sub:
			return sub
	return null

# ---------- Update quantity ----------
func update_quantity(new_qty: int) -> void:
	item["quantity"] = new_qty
	var qty_node: Label = get_node_or_null("Qty")
	if qty_node:
		if new_qty > 1:
			qty_node.text = "x%d" % new_qty
			qty_node.visible = true
		else:
			qty_node.visible = false
	_update_tooltip()
