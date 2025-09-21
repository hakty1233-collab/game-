extends CharacterBody2D

@export var speed: float = 80.0
@export var wander_radius: float = 200.0
@export var detect_radius: float = 150.0
@export var npc_personality: String = "friendly villager"

# === NEW: Simple gift settings ===
@export var gives_gifts: bool = true
@export var gift_items: Array[String] = ["Bronze Axe", "Basic Rod", "Bronze Pickaxe"]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var grok_api: Node = get_node("/root/GrokAPI")

var target_position: Vector2
var player: Node2D
var busy_talking: bool = false
var last_position: Vector2
var stuck_timer: float = 0.0
var last_direction: Vector2 = Vector2.DOWN
var conversation_count: int = 0
var has_given_gift: bool = false  # NEW: Track if gift was given

signal said_to_player(message: String)

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("No player found in 'player' group!")
	_set_random_target()
	last_position = global_position
	
	print("[NPC] === NPC READY DEBUG ===")
	print("[NPC] NPC name: ", name)
	print("[NPC] Children:")
	for child in get_children():
		print("  - ", child.name, " (", child.get_class(), ")")
		if child.name == "CollisionShape2D":
			for subchild in child.get_children():
				print("    - ", subchild.name, " (", subchild.get_class(), ")")
	
	# Check if Area2D exists and has the script
	var area = find_child("Area2D", true, false)
	if area:
		print("[NPC] Found Area2D at: ", area.get_path())
		if area.get_script():
			print("[NPC] Area2D has script attached")
		else:
			print("[NPC] WARNING: Area2D has no script!")
	else:
		print("[NPC] ERROR: No Area2D found!")

func _physics_process(delta: float) -> void:
	if busy_talking:
		velocity = Vector2.ZERO
	else:
		# Just wander - no more auto-talking when player approaches
		_move_towards_target()

	_update_animation()
	move_and_slide()

	# ---- Wander reset if stuck ----
	if global_position.distance_to(last_position) < 2.0:
		stuck_timer += delta
		if stuck_timer > 0.5:
			_set_random_target()
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0

	last_position = global_position

# ---------- Movement ----------
func _set_random_target():
	var angle = randf() * TAU
	var offset = Vector2(cos(angle), sin(angle)) * wander_radius
	target_position = global_position + offset

func _move_towards_target():
	var dir = (target_position - global_position)
	if dir.length() < 1.0:
		_set_random_target()
		dir = target_position - global_position

	velocity = dir.normalized() * speed

# ---------- Animation ----------
func _update_animation():
	if velocity.length() < 1.0:
		# Idle facing last movement direction
		if last_direction.x > 0:
			sprite.play("idle_right")
		elif last_direction.x < 0:
			sprite.play("idle_left")
		elif last_direction.y > 0:
			sprite.play("idle_down")
		else:
			sprite.play("idle_top")
	else:
		# Walking animations and update last direction
		if abs(velocity.x) > abs(velocity.y):
			if velocity.x > 0:
				sprite.play("walk_right")
				last_direction = Vector2.RIGHT
			else:
				sprite.play("walk_left")
				last_direction = Vector2.LEFT
		else:
			if velocity.y > 0:
				sprite.play("walk_down")
				last_direction = Vector2.DOWN
			else:
				sprite.play("walk_top")
				last_direction = Vector2.UP

# ---------- Interaction (NEW) ----------
func on_interact():
	print("[NPC] === ON_INTERACT CALLED ===")
	
	# Stop any existing timers/busy states
	busy_talking = false
	
	# Give gift on first interaction
	if gives_gifts and not has_given_gift and not gift_items.is_empty():
		print("[NPC] Giving gift...")
		_give_gift()
	else:
		print("[NPC] No gift, starting dialogue...")
		_talk_to_player()

# ---------- Gift System (NEW) ----------
func _give_gift():
	print("[NPC] === GIVING GIFT ===")
	busy_talking = true
	has_given_gift = true
	
	# Pick random gift
	var gift_name = gift_items[randi() % gift_items.size()]
	print("[NPC] Selected gift: ", gift_name)
	
	# Add to inventory
	PlayerInventory.loot_item(gift_name, 1)
	print("[NPC] Added to inventory")
	
	# Show message
	_show_dialogue("Here, take this " + gift_name + "! Check your inventory and click it to equip.")
	
	print("[NPC] Gave " + gift_name + " to player")
	
	# Cooldown
	var timer := Timer.new()
	timer.wait_time = 4.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()
	
	busy_talking = false

# ---------- AI Dialogue ----------
func _talk_to_player():
	if busy_talking:
		return
	busy_talking = true

	conversation_count += 1
	
	# Create context for the AI
	var context = ""
	if conversation_count == 1:
		context = "A player just approached you for the first time. Greet them as a " + npc_personality + "."
	else:
		context = "This is the " + str(conversation_count) + " time talking to this player. Be a " + npc_personality + " and vary your response."

	# Show "thinking" message while waiting for AI
	_show_dialogue("...")

	# Query the AI
	if grok_api:
		grok_api.query(context, _on_ai_response)
	else:
		# Fallback if no AI available
		_on_ai_response("Hello, traveler!")

func _on_ai_response(message: String):
	# Replace the "thinking" bubble with actual response
	_show_dialogue(message)
	
	# Cooldown before talking again
	var timer := Timer.new()
	timer.wait_time = 4.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()

	busy_talking = false

func _show_dialogue(message: String):
	# Remove any existing dialogue bubbles from this NPC
	var existing_bubbles = get_tree().get_nodes_in_group("dialogue_bubbles")
	for bubble in existing_bubbles:
		if bubble.has_meta("npc_owner") and bubble.get_meta("npc_owner") == self:
			bubble.queue_free()

	# Instance a new speech bubble
	var bubble_scene = preload("res://dialogue_box.tscn")
	var bubble = bubble_scene.instantiate()
	bubble.add_to_group("dialogue_bubbles")
	bubble.set_meta("npc_owner", self)
	get_tree().current_scene.add_child(bubble)
	bubble.show_message(message, self)
