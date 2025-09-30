extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var loading_label: Label = $LoadingLabel
@onready var otter_sprite: AnimatedSprite2D = $Otter

var target_scene_path: String = ""
var progress: float = 0.0
var has_played_stand_animation: bool = false

func _ready():
	print("[LoadingScreen] Loading screen ready")
	
	if not otter_sprite:
		push_warning("[LoadingScreen] Otter sprite not found!")
	
	if target_scene_path != "":
		_start_loading()

func load_scene(scene_path: String):
	target_scene_path = scene_path
	print("[LoadingScreen] Will load: ", scene_path)
	
	if is_node_ready():
		_start_loading()

func _start_loading():
	print("[LoadingScreen] Starting to load: ", target_scene_path)
	
	var error = ResourceLoader.load_threaded_request(target_scene_path)
	if error != OK:
		push_error("[LoadingScreen] Failed to start loading scene: ", target_scene_path)
		return
	
	set_process(true)

func _process(delta):
	if target_scene_path == "":
		return
	
	var progress_array = []
	var load_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress_array)
	
	if progress_array.size() > 0:
		progress = progress_array[0]
	
	if progress_bar:
		progress_bar.value = progress * 100
	
	if loading_label:
		loading_label.text = "Loading... %d%%" % int(progress * 100)
	
	# Play otter stand animation when reaching 100%
	if progress >= 1.0 and not has_played_stand_animation and otter_sprite:
		print("[LoadingScreen] Playing Otter_stand animation")
		otter_sprite.play("Otter_stand")
		has_played_stand_animation = true
	
	# Check if loading is complete
	match load_status:
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)  # FIXED: Stop processing FIRST
			_on_loading_complete()
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("[LoadingScreen] Failed to load scene")
			set_process(false)
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("[LoadingScreen] Invalid resource")
			set_process(false)

func _on_loading_complete():
	print("[LoadingScreen] _on_loading_complete started")
	
	if otter_sprite:
		# Check if animation is set to loop
		var sprite_frames = otter_sprite.sprite_frames
		if sprite_frames and sprite_frames.get_animation_loop("Otter_stand"):
			print("[LoadingScreen] WARNING: Otter_stand animation is set to loop!")
		
		if otter_sprite.is_playing():
			print("[LoadingScreen] Waiting for otter animation...")
			# Add a timeout in case animation never finishes
			var timer = get_tree().create_timer(2.0)
			var animation_done = false
			
			otter_sprite.animation_finished.connect(func(): animation_done = true, CONNECT_ONE_SHOT)
			
			# Wait for either animation to finish OR timeout
			while not animation_done and timer.time_left > 0:
				await get_tree().process_frame
			
			print("[LoadingScreen] Animation wait completed")
	
	print("[LoadingScreen] Waiting 0.5 seconds...")
	await get_tree().create_timer(0.5).timeout
	
	print("[LoadingScreen] Getting loaded scene...")
	var loaded_scene = ResourceLoader.load_threaded_get(target_scene_path)
	
	if loaded_scene == null:
		push_error("[LoadingScreen] loaded_scene is NULL!")
		return
	
	print("[LoadingScreen] Changing scene...")
	get_tree().change_scene_to_packed(loaded_scene)
