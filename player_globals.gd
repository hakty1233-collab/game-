# PlayerGlobals.gd
extends Node

var instance: CharacterBody2D = null

func get_player() -> CharacterBody2D:
	return instance
