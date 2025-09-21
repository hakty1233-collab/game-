extends Node

# Preload all item textures
const ICONS := {
	"raw_fish": preload("res://UI/Items/raw_fish.png"),
	"stone": preload("res://UI/Items/stone.png"),
	# add more items here
}

# Normalize name to safe key
func normalize_name(name: String) -> String:
	return name.to_lower().replace(" ", "_")

func has_icon(name: String) -> bool:
	return ICONS.has(normalize_name(name))

func get_icon(name: String) -> Texture2D:
	var key := normalize_name(name)
	if ICONS.has(key):
		return ICONS[key]
	return null
