extends Node2D

func _ready() -> void:
	CycleManager.register_world(self)
