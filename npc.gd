extends CharacterBody2D

@export var speed: float = 80.0
@export var wander_radius: float = 200.0
@export var detect_radius: float = 150.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var target_position: Vector2
var player: Node2D
var busy_talking: bool = false
var last_position: Vector2
var stuck_timer: float = 0.0

signal said_to_player(message: String)

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("No player found in 'player' group!")
	_set_random_target()
	last_position = global_position


func _physics_process(delta: float) -> void:
	if busy_talking:
		velocity = Vector2.ZERO
	else:
		if player and global_position.distance_to(player.global_position) <= detect_radius:
			velocity = Vector2.ZERO
			_talk_to_player()
		else:
			_move_towards_target()

	_update_animation()
	move_and_slide()

	# ---- Wander reset if stuck ----
	if global_position.distance_to(last_position) < 2.0:
		stuck_timer += delta
		if stuck_timer > 0.5: # half a second stuck
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
		# Idle facing last movement
		if abs(velocity.x) > abs(velocity.y):
			sprite.play("idle_right" if velocity.x > 0 else "idle_left")
		else:
			sprite.play("idle_down" if velocity.y > 0 else "idle_down")
	else:
		# Walking animations
		if abs(velocity.x) > abs(velocity.y):
			sprite.play("walk_right" if velocity.x > 0 else "walk_left")
		else:
			sprite.play("walk_down" if velocity.y > 0 else "walk_top")


# ---------- Dialogue ----------
func _talk_to_player():
	if busy_talking:
		return
	busy_talking = true

	var response = "Hello, traveler!"

	# Instance a speech bubble
	var bubble_scene = preload("res://dialogue_box.tscn")
	var bubble = bubble_scene.instantiate()
	get_tree().current_scene.add_child(bubble)
	bubble.show_message(response, self)

	# Cooldown before talking again
	var timer := Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()

	busy_talking = false
