# CycleManager.gd
extends Node

@export var day_length: float = 600.0  # full day in seconds

var time: float = 60.0
var overlay: CanvasModulate = null

var times: Array[float] = [0.0, 0.2, 0.35, 0.5, 0.7, 0.85, 1.0]
var colors: Array[Color] = [
	Color(0.05, 0.05, 0.2),   # Midnight
	Color(0.8, 0.4, 0.2),     # Sunrise
	Color(1.0, 1.0, 1.0),     # Day
	Color(0.9, 0.95, 1.0),    # Midday bright
	Color(1.0, 0.6, 0.3),     # Sunset
	Color(0.1, 0.1, 0.3),     # Evening
	Color(0.05, 0.05, 0.2)    # Midnight again
]

func _ready() -> void:
	print("[CycleManager] ready, process enabled")
	set_process(true)

func register_world(world: Node) -> void:
	# look directly for "NightOverlay"
	overlay = world.get_node_or_null("NightOverlay")
	if overlay and overlay is CanvasModulate:
		print("[CycleManager] Found overlay:", overlay.name)
	else:
		push_warning("[CycleManager] No CanvasModulate named 'NightOverlay' found under world!")

func _process(delta: float) -> void:
	if overlay == null:
		return

	time = fmod(time + delta / day_length, 1.0)
	var col := _get_color_for_time(time)
	overlay.color = col

func _get_color_for_time(t: float) -> Color:
	for i in range(times.size() - 1):
		var t0 = times[i]
		var t1 = times[i + 1]
		if t >= t0 and t <= t1:
			var f = (t - t0) / (t1 - t0)
			return colors[i].lerp(colors[i + 1], f)
	return colors[0]
