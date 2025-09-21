extends BaseGatherNode

@onready var tree_sprite: Sprite2D = $Sprite2D
@onready var stump_sprite: AnimatedSprite2D = $StumpSprite

func _ready() -> void:
	super._ready()
	skill_name = "Woodcutting"

	# Default drops if nothing set in inspector
	if drops.is_empty() or String(drops[0].get("name", "")) == "Item":
		drops = [{"name":"Log", "min":1, "max":2}]

# Override the base respawn visuals
func _on_depleted() -> void:
	tree_sprite.visible = false
	stump_sprite.visible = true

func _on_respawned() -> void:
	tree_sprite.visible = true
	stump_sprite.visible = false
