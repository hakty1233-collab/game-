extends Node2D

@export var required_level := 1
@export var xp_reward := 10
@export var chop_time: float = 1.2

var is_chopping := false

func _ready() -> void:
	add_to_group("Mining")

func get_chop_time() -> float:
	return chop_time

func on_interact():
	if is_chopping:
		return

	var level = SkillManager.skills["Mining"]["level"]
	if level < required_level:
		print("You need Woodcutting level %s to chop this tree." % required_level)
		return

	print("Chopping tree...")
	is_chopping = true
	await get_tree().create_timer(chop_time).timeout

	SkillManager.add_xp("Mining", xp_reward)
	queue_free() # Or play a falling animation before freeing
