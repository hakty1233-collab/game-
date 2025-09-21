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
	"copper_ore": preload("res://UI/Items/copper_ore.png")
	# Add more items here
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

# ---------- Set item ----------
func set_item(d: Dictionary) -> void:
	item = d.duplicate(true)
	
	# Quantity label
	var qty_node: Label = get_node_or_null("Qty")
	if qty_node:
		qty_node.text = "x%d" % int(item.get("quantity", 1))
	else:
		print("[ItemSlot] Qty node not found!")
	
	# Icon assignment: find TextureRect dynamically
	var icon_node: TextureRect = find_icon_node()
	if icon_node:
		var key: String = item.get("key","")
		var tex: Texture2D = get_icon(key) as Texture2D
		if tex != null:
			icon_node.texture = tex
			print("[ItemSlot] Icon assigned for key:", key)
		else:
			icon_node.texture = null
			print("[ItemSlot] No icon found for key:", key)
			print("Available ICONS keys:", ICONS.keys())
	else:
		print("[ItemSlot] Icon node not found! Children:")
		for c in get_children():
			print(" - ", c.name)
	
	# Tooltip
	tooltip_text = "%s x%d" % [ String(item.get("name","?")), int(item.get("quantity",1)) ]

# ---------- Find icon node safely ----------
func find_icon_node() -> TextureRect:
	# First try direct child named "Icon"
	var node: TextureRect = get_node_or_null("Icon")
	if node:
		return node
	# Last resort: search all children recursively
	return get_node_or_null_recursive(self)

# ---------- Recursive search helper ----------
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
		qty_node.text = "x%d" % new_qty
