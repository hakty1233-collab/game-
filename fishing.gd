extends BaseGatherNode

func _ready() -> void:
	super._ready()
	skill_name = "Fishing"

	if drops.is_empty() or String(drops[0].get("name", "")) == "Item":
		drops = [{"name":"Raw Fish", "min":1, "max":2}]

	# (optional) fishing feels better with a tiny floor on cast time
	action_time = max(action_time, 0.5)
