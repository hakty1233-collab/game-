extends Area2D

func on_interact():
	# Get the NPC (grandparent: Area2D -> CollisionShape2D -> NPC)
	var npc = get_parent().get_parent()
	if npc and npc.has_method("on_interact"):
		npc.on_interact()
	else:
		print("[Area2D] Could not find NPC with on_interact method")
