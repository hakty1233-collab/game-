extends CharacterBody2D
class_name VendorNPC

@export var vendor_name: String = "Tool Merchant"
@export var greeting_message: String = "Welcome to my shop!"

# Shop inventory - what this vendor sells
@export var shop_items: Array[Dictionary] = [
	{"name": "Bronze Axe", "price": 50, "type": "tool", "skill": "Woodcutting"},
	{"name": "Bronze Pickaxe", "price": 50, "type": "tool", "skill": "Mining"},
	{"name": "Basic Rod", "price": 50, "type": "tool", "skill": "Fishing"},
	{"name": "Log", "price": 5, "type": "item"},
	{"name": "Copper Ore", "price": 10, "type": "item"}
]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D
var busy_talking: bool = false

signal shop_opened(vendor: VendorNPC)

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("vendors")
	print("[Vendor] ", vendor_name, " ready with ", shop_items.size(), " items")

# Called when player interacts
func on_interact():
	if busy_talking:
		return
	
	busy_talking = true
	print("[Vendor] Player interacting with ", vendor_name)
	
	# Show greeting
	_show_dialogue(greeting_message)
	
	# Wait a moment then open shop
	await get_tree().create_timer(1.0).timeout
	_open_shop()
	
	busy_talking = false

func _open_shop():
	print("[Vendor] Opening shop UI")
	
	# Find the shop UI in the scene
	var shop_ui = get_tree().get_first_node_in_group("shop_ui")
	if not shop_ui:
		# Try to find it in HUD
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			shop_ui = hud.get_node_or_null("ShopUI")
	
	if shop_ui and shop_ui.has_method("open_shop"):
		shop_ui.open_shop(self)
	else:
		print("[Vendor] No shop UI found, using fallback")
		_show_simple_shop()

func _show_simple_shop():
	# This is a placeholder - you'll want a proper shop UI later
	print("[Vendor] === SHOP MENU ===")
	for i in range(shop_items.size()):
		var item = shop_items[i]
		print("%d. %s - %d coins" % [i + 1, item.get("name", "?"), item.get("price", 0)])

# Function to handle purchase
func purchase_item(item_index: int) -> bool:
	if item_index < 0 or item_index >= shop_items.size():
		print("[Vendor] Invalid item index")
		return false
	
	var item = shop_items[item_index]
	var item_name = item.get("name", "Unknown")
	var price = item.get("price", 0)
	
	# Check if player has enough money
	# For now we'll assume player always has money
	# Later you can add: if PlayerInventory.get_currency() < price: return false
	
	print("[Vendor] Selling %s for %d coins" % [item_name, price])
	
	# Add item to player inventory
	PlayerInventory.loot_item(item_name, 1)
	
	# Deduct currency (implement when you add currency system)
	# PlayerInventory.remove_currency(price)
	
	_show_dialogue("Thank you for your purchase!")
	
	return true

func _show_dialogue(message: String):
	# Remove existing bubbles
	var existing_bubbles = get_tree().get_nodes_in_group("dialogue_bubbles")
	for bubble in existing_bubbles:
		if bubble.has_meta("npc_owner") and bubble.get_meta("npc_owner") == self:
			bubble.queue_free()
	
	# Create new bubble
	var bubble_scene = preload("res://dialogue_box.tscn")
	var bubble = bubble_scene.instantiate()
	bubble.add_to_group("dialogue_bubbles")
	bubble.set_meta("npc_owner", self)
	get_tree().current_scene.add_child(bubble)
	bubble.show_message(message, self)

# Helper functions for shop management
func add_shop_item(item_name: String, price: int, item_type: String = "item", skill: String = ""):
	var new_item = {
		"name": item_name,
		"price": price,
		"type": item_type
	}
	if skill != "":
		new_item["skill"] = skill
	shop_items.append(new_item)

func remove_shop_item(item_name: String):
	for i in range(shop_items.size() - 1, -1, -1):
		if shop_items[i].get("name", "") == item_name:
			shop_items.remove_at(i)

func get_item_price(item_name: String) -> int:
	for item in shop_items:
		if item.get("name", "") == item_name:
			return item.get("price", 0)
	return -1
