extends Area2D

@export var station_type: String = "Oven"   # "Oven" | "Forge" | "Workbench"

@onready var sprite: Sprite2D = $Sprite2D  # Make sure you have a Sprite2D as a child

# Preload textures for different station types
const STATION_TEXTURES := {
	"Oven": preload("res://UI/Icons/otteria_skill_icons.png"),
	"Forge": preload("res://UI/Art/Forge.png"),
	"Workbench": preload("res://UI/Icons/otteria_skill_icons.png")
}

func _ready() -> void:
	# Set the sprite depending on station type
	if station_type in STATION_TEXTURES:
		sprite.texture = STATION_TEXTURES[station_type]
	else:
		print("[CraftingStation] Unknown station type:", station_type)

func on_interact() -> void:
	# Find CraftingUI in the scene (grouped)
	var ui := get_tree().get_first_node_in_group("CraftingUI")
	if ui:
		ui.call("open_for_station", station_type)
