extends Control

@onready var list_root   : VBoxContainer = $Panel/ListRoot
@onready var title_lbl   : Label         = $Panel/ListRoot/Title
@onready var recipe_list : ItemList      = $Panel/ListRoot/RecipeList
@onready var craft_one   : Button        = $Panel/CraftOne
@onready var craft_all   : Button        = $Panel/CraftAll
@onready var close_btn   : Button        = $Panel/CloseBtn

var current_station  : String = ""
var current_recipes  : Array[Dictionary] = []

func _ready() -> void:
	add_to_group("CraftingUI")
	visible = false
	craft_one.pressed.connect(_craft_one)
	craft_all.pressed.connect(_craft_all)
	close_btn.pressed.connect(func(): visible = false)

func open_for_station(station_type: String) -> void:
	current_station = station_type
	title_lbl.text = "%s — Crafting" % station_type
	visible = true
	_populate_recipes()

func _populate_recipes() -> void:
	recipe_list.clear()
	current_recipes.clear()

	var recs: Array[Dictionary] = RecipeManager.get_recipes_for_station(current_station)
	for r in recs:
		current_recipes.append(r)
		var inputs: Dictionary = r.get("inputs", {}) as Dictionary
		var inputs_text: String = _inputs_to_string(inputs)
		recipe_list.add_item("%s  (%s)" % [String(r.get("name","Recipe")), inputs_text])

	if recipe_list.get_item_count() > 0:
		recipe_list.select(0)

func _inputs_to_string(inputs: Dictionary) -> String:
	var parts: Array[String] = []
	for k in inputs.keys():
		var name: String = String(k)
		var qty : int    = int(inputs[k])
		parts.append("%s×%d" % [name, qty])
	return ", ".join(parts)

func _get_selected_recipe() -> Dictionary:
	var idxs: PackedInt32Array = recipe_list.get_selected_items()
	if idxs.size() == 0:
		return {}
	var i: int = idxs[0]
	if i >= 0 and i < current_recipes.size():
		return current_recipes[i]
	return {}

func _can_craft(r: Dictionary, times: int) -> bool:
	var need: Dictionary = r.get("inputs", {}) as Dictionary
	for k in need.keys():
		var name: String = String(k)
		var need_qty: int = int(need[name]) * times
		var have_qty: int = int(PlayerInventory.get_count(name))
		if have_qty < need_qty:
			return false
	return true

func _craft(times: int) -> void:
	var r: Dictionary = _get_selected_recipe()
	if r.is_empty():
		return

	if not _can_craft(r, times):
		print("Not enough materials.")
		return

	# remove inputs
	var inputs: Dictionary = r["inputs"] as Dictionary
	for k in inputs.keys():
		var name: String = String(k)
		var qty : int = int(inputs[name]) * times
		PlayerInventory.remove_item(name, qty)

	# add outputs
	var outputs: Dictionary = r["output"] as Dictionary
	for k in outputs.keys():
		var name: String = String(k)
		var qty : int = int(outputs[name]) * times
		PlayerInventory.add_item({"name": name, "quantity": qty})

	# grant XP
	var skill: String = String(r.get("skill",""))
	var xp   : int    = int(r.get("xp", 0)) * times
	if skill != "" and xp > 0:
		SkillManager.add_xp(skill, xp)

	_populate_recipes()

func _craft_one() -> void:
	_craft(1)

func _craft_all() -> void:
	var r: Dictionary = _get_selected_recipe()
	if r.is_empty():
		return
	var need: Dictionary = r.get("inputs", {}) as Dictionary
	var max_times: int = 999999
	for k in need.keys():
		var name    : String = String(k)
		var have    : int    = int(PlayerInventory.get_count(name))
		var per     : int    = int(need[name])
		var possible: int    = int(have / max(1, per))
		max_times = min(max_times, possible)

	if max_times <= 0:
		print("Not enough materials.")
		return

	_craft(max_times)
