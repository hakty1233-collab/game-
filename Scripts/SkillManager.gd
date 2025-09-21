extends Node

signal skill_updated(skill_name: String, level: int, xp: int)
signal level_up(skill_name: String, new_level: int)
signal xp_gained(skill_name: String, amount: int, level: int, xp: int) # NEW

var skills: Dictionary = {
	"Woodcutting": {"xp": 0, "level": 1},
	"Fishing":     {"xp": 0, "level": 1},
	"Mining":      {"xp": 0, "level": 1},
}

func add_xp(skill: String, amount: int) -> void:
	if not skills.has(skill):
		return
	var s: Dictionary = skills[skill] as Dictionary
	var xp: int = int(s.get("xp", 0))
	var lvl: int = int(s.get("level", 1))

	# add and process level-ups
	xp += amount
	var needed: int = _xp_to_next(lvl)
	var leveled: bool = false
	while xp >= needed:
		xp -= needed
		lvl += 1
		leveled = true
		level_up.emit(skill, lvl)
		needed = _xp_to_next(lvl)

	# save back
	skills[skill] = {"xp": xp, "level": lvl}

	# emit updates
	xp_gained.emit(skill, amount, lvl, xp)    # NEW: for XP popup
	skill_updated.emit(skill, lvl, xp)        # existing UI updates

func _xp_to_next(level: int) -> int:
	return 20 + level * 10

# --- helpers for HUD ---

func get_xp_for_next_level(skill_name: String) -> int:
	if not skills.has(skill_name):
		return 0
	var lvl: int = int((skills[skill_name] as Dictionary).get("level", 1))
	return _xp_to_next(lvl)

# ----- Save/Load helpers (keep your existing ones if you already have them) -----
func get_save_data() -> Dictionary:
	var out: Dictionary = {}
	for k in skills.keys():
		var key: String = String(k)
		var s: Dictionary = skills[key] as Dictionary
		var xp: int = int(s.get("xp", 0))
		var lvl: int = int(s.get("level", 1))
		out[key] = {"xp": xp, "level": lvl}
	return out

func load_from_data(data: Dictionary) -> void:
	for k in data.keys():
		var key: String = String(k)
		var s: Dictionary = data[key] as Dictionary
		var xp: int = int(s.get("xp", 0))
		var lvl: int = int(s.get("level", 1))
		skills[key] = {"xp": xp, "level": lvl}

	# refresh UI/tiles
	for k in skills.keys():
		var key2: String = String(k)
		var s2: Dictionary = skills[key2] as Dictionary
		var lvl2: int = int(s2.get("level", 1))
		var xp2: int  = int(s2.get("xp", 0))
		skill_updated.emit(key2, lvl2, xp2)
