extends Node

signal inventory_changed
signal item_added(name: String, quantity: int)
signal item_removed(name: String, quantity: int)

# Store items as { "name": display_name, "key": normalized_key, "quantity": int }
var items: Array[Dictionary] = []

# ---------- Queries ----------
func get_items() -> Array:
	return items.duplicate(true)

func get_count(key_or_name: String) -> int:
	var total: int = 0
	for d in items:
		if String(d.get("key","")) == key_or_name or String(d.get("name","")) == key_or_name:
			total += int(d.get("quantity", 0))
	return total

func has_at_least(key_or_name: String, qty: int) -> bool:
	return get_count(key_or_name) >= max(0, qty)

# ---------- Add ----------
func add_item(item_data: Dictionary) -> void:
	var display_name: String = String(item_data.get("name", "")).strip_edges()
	if display_name == "":
		return
	var key: String = display_name.to_lower().replace(" ", "_")
	var qty: int = int(item_data.get("quantity", 0))
	if qty <= 0:
		return

	# Stack if already exists
	for i in range(items.size()):
		var d: Dictionary = items[i]
		if String(d.get("key","")) == key:
			d["quantity"] = int(d.get("quantity", 0)) + qty
			items[i] = d
			item_added.emit(display_name, qty)
			inventory_changed.emit()
			return

	# Add new item
	items.append({"name": display_name, "key": key, "quantity": qty})
	item_added.emit(display_name, qty)
	inventory_changed.emit()

# ---------- Remove ----------
func remove_item(key_or_name: String, qty: int) -> int:
	if qty <= 0:
		return 0
	var remaining: int = qty
	for i in range(items.size()):
		var d: Dictionary = items[i]
		if String(d.get("key","")) != key_or_name and String(d.get("name","")) != key_or_name:
			continue
		var have: int = int(d.get("quantity", 0))
		if have <= 0:
			continue
		var take: int = min(have, remaining)
		have -= take
		remaining -= take
		d["quantity"] = have
		items[i] = d
		if remaining <= 0:
			break

	for i in range(items.size()-1, -1, -1):
		if int((items[i] as Dictionary).get("quantity", 0)) <= 0:
			items.remove_at(i)

	var removed := qty - remaining
	if removed > 0:
		item_removed.emit(key_or_name, removed)
		inventory_changed.emit()
	return removed

# ---------- NEW: Take 1 item (for equipping) ----------
func take_one(key_or_name: String) -> Dictionary:
	for i in range(items.size()):
		var d: Dictionary = items[i]
		if String(d.get("key","")) == key_or_name or String(d.get("name","")) == key_or_name:
			# Make a copy with quantity = 1
			var taken := d.duplicate(true)
			taken["quantity"] = 1

			# Reduce stack
			remove_item(key_or_name, 1)
			return taken
	return {}

# ---------- Save / Load ----------
func get_save_data() -> Array:
	return items.duplicate(true)

func load_from_data(arr: Array) -> void:
	items.clear()
	for rec in arr:
		var display_name := String((rec as Dictionary).get("name", ""))
		var key := String((rec as Dictionary).get("key", display_name.to_lower().replace(" ","_")))
		var qty := int((rec as Dictionary).get("quantity", 0))
		if display_name != "" and qty > 0:
			items.append({"name": display_name, "key": key, "quantity": qty})
	inventory_changed.emit()

func clear() -> void:
	items.clear()
	inventory_changed.emit()

# ---------- Loot helper ----------
func loot_item(display_name: String, qty: int = 1) -> void:
	if display_name == "" or qty <= 0:
		return
	var key: String = display_name.to_lower().replace(" ", "_")
	add_item({"name": display_name, "key": key, "quantity": qty})
