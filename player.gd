# Player.gd
extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var speed: float = 100.0

var nearby_object: Node = null
var is_busy: bool = false
var _last_dir: Vector2 = Vector2.DOWN

func _ready() -> void:
	PlayerGlobals.instance = self
	add_to_group("player")
	$InteractArea.connect("area_entered", _on_area_entered)
	$InteractArea.connect("area_exited", _on_area_exited)

func _physics_process(_delta: float) -> void:
	if is_busy:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_vector: Vector2 = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	velocity = input_vector * speed
	move_and_slide()

	if input_vector != Vector2.ZERO:
		_last_dir = input_vector
		if abs(input_vector.x) > abs(input_vector.y):
			sprite.play("walk_Right" if input_vector.x > 0 else "walk_Left")
		else:
			sprite.play("walk_Bottom" if input_vector.y > 0 else "walk_Top")
	else:
		if abs(_last_dir.x) > abs(_last_dir.y):
			sprite.play("Idle_Right" if _last_dir.x > 0 else "Idle_Left")
		else:
			sprite.play("Idle_Bottom" if _last_dir.y > 0 else "Idle_Top")

# ---------- Area detection ----------
func _on_area_entered(area: Area2D) -> void:
	if area.has_method("on_interact"):
		nearby_object = area

func _on_area_exited(area: Area2D) -> void:
	if nearby_object == area:
		nearby_object = null

# ---------- Input ----------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and nearby_object != null and !is_busy:
		if _is_tree(nearby_object):
			call_deferred("_do_activity", nearby_object, "chop")
		elif _is_mineable(nearby_object):
			call_deferred("_do_activity", nearby_object, "mine")
		elif _is_fishable(nearby_object):
			call_deferred("_do_activity", nearby_object, "fish")
		elif nearby_object.has_method("on_interact"):
			nearby_object.on_interact()

# ---------- Activity checks ----------
func _is_tree(node: Node) -> bool:
	return node != null and (node.is_in_group("trees") or node.has_method("get_chop_time"))

func _is_mineable(node: Node) -> bool:
	return node != null and (node.is_in_group("mining") or node.has_method("get_mine_time") or node.name.to_lower().contains("ore"))

func _is_fishable(node: Node) -> bool:
	return node != null and (node.is_in_group("fishing") or node.has_method("get_fish_time") or node.name.to_lower().contains("fish"))

# ---------- Activity times ----------
func _get_chop_time(node: Node) -> float:
	if node != null and node.has_method("get_chop_time"):
		var v = node.get_chop_time()
		if typeof(v) in [TYPE_INT, TYPE_FLOAT]:
			return float(v)
	return 1.0

func _get_mine_time(node: Node) -> float:
	if node != null and node.has_method("get_mine_time"):
		var v = node.get_mine_time()
		if typeof(v) in [TYPE_INT, TYPE_FLOAT]:
			return float(v)
	return 1.0

func _get_fish_time(node: Node) -> float:
	if node != null and node.has_method("get_fish_time"):
		var v = node.get_fish_time()
		if typeof(v) in [TYPE_INT, TYPE_FLOAT]:
			return float(v)
	return 1.0

# ---------- Animation ----------
func _play_activity_anim(activity: String) -> void:
	var anim: String
	match activity:
		"chop":
			if abs(_last_dir.x) > abs(_last_dir.y):
				anim = "chop_right" if _last_dir.x > 0 else "chop_Left"
			else:
				anim = "chop_Bottom" if _last_dir.y > 0 else "chop_Top"
		"mine":
			if abs(_last_dir.x) > abs(_last_dir.y):
				anim = "mine_right" if _last_dir.x > 0 else "mine_Left"
			else:
				anim = "mine_bottom" if _last_dir.y > 0 else "mine_top"
		"fish":
			anim = "fish"  # single fishing animation
		_:
			return

	if !sprite.sprite_frames.has_animation(anim):
		print("[Player] Activity animation not found:", anim)
		return

	sprite.play(anim)
	sprite.speed_scale = 1.0

# ---------- Activity action ----------
func _do_activity(target: Node, activity: String) -> void:
	is_busy = true
	velocity = Vector2.ZERO

	_play_activity_anim(activity)

	# wait a frame so animation actually starts
	await get_tree().process_frame

	# wait activity duration
	var t: float
	match activity:
		"chop": t = _get_chop_time(target)
		"mine": t = _get_mine_time(target)
		"fish": t = _get_fish_time(target)
		_: t = 1.0

	await get_tree().create_timer(max(t, 0.1)).timeout

	# Trigger target interaction
	if target.has_method("on_interact"):
		target.on_interact()

	is_busy = false

	# Return to idle facing
	if abs(_last_dir.x) > abs(_last_dir.y):
		sprite.play("Idle_Right" if _last_dir.x > 0 else "Idle_Left")
	else:
		sprite.play("Idle_Bottom" if _last_dir.y > 0 else "Idle_Top")
