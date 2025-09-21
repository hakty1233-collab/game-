extends BaseGatherNode

@onready var Ore_sprite: Sprite2D = $Sprite2D
@onready var stump_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	super._ready()
	skill_name = "Mining"

	if drops.is_empty() or String(drops[0].get("name", "")) == "Item":
		drops = [{"name":"Copper Ore", "min":1, "max":2}]
		
# Override the base respawn visuals
func _on_depleted() -> void:
	Ore_sprite.visible = false
	stump_sprite.visible = true

func _on_respawned() -> void:
	Ore_sprite.visible = true
	stump_sprite.visible = false
