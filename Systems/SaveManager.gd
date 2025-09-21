extends Node

const SAVE_PATH := "user://savegame.json"

func save_game() -> bool:
	var data: Dictionary = {
		"skills": SkillManager.get_save_data(),
		"inventory": PlayerInventory.get_save_data(),
	}

	# --- Save player position ---
	var p := PlayerGlobals.instance as Node2D
	if p:
		data["player"] = {
			"x": p.global_position.x,
			"y": p.global_position.y
		}

	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var text: String = f.get_as_text()
	f.close()

	var parsed_raw: Variant = JSON.parse_string(text)
	if typeof(parsed_raw) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = parsed_raw

	if d.has("skills") and d["skills"] is Dictionary:
		SkillManager.load_from_data(d["skills"] as Dictionary)

	if d.has("inventory") and d["inventory"] is Array:
		PlayerInventory.load_from_data(d["inventory"] as Array)

	# --- Load player position ---
	if d.has("player") and d["player"] is Dictionary:
		var p := PlayerGlobals.instance as Node2D
		if p:
			p.global_position = Vector2(
				float(d["player"].get("x", 0)),
				float(d["player"].get("y", 0))
			)

	return true
