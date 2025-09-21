extends Control

@onready var text_label: Label = $Panel/Label
@export var lifetime: float = 3.0  # seconds before auto-hide

func show_message(message: String, follow_node: Node2D):
	text_label.text = message
	visible = true
	# Keep following NPC
	set_process(true)
	set_meta("follow", follow_node)

	# Hide after a while
	var timer := Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()
	queue_free()

func _process(_delta):
	var follow_node: Node2D = get_meta("follow")
	if follow_node and is_instance_valid(follow_node):
		global_position = follow_node.global_position + Vector2(0, -40)
