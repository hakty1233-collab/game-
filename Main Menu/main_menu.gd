extends Control

@onready var start_button: Button = $UILayer/Start
@onready var load_button: Button = $UILayer/Load
@onready var options_button: Button = $UILayer/Options
@onready var exit_button: Button = $UILayer/Exit

@export var game_scene_path: String = "res://World.tscn"
@export var loading_screen_path: String = "res://Loading screen/LoadingScreen.tscn"

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	print("[MainMenu] Main menu ready")

func _on_start_pressed():
	print("[MainMenu] Starting new game...")
	# Pass the target game scene path to the loading screen via autoload or scene data
	var loading_screen = load(loading_screen_path).instantiate()
	loading_screen.load_scene(game_scene_path)
	get_tree().root.add_child(loading_screen)
	queue_free() # remove main menu

func _on_load_pressed():
	print("[MainMenu] Loading game...")

func _on_options_pressed():
	print("[MainMenu] Options pressed...")

func _on_exit_pressed():
	print("[MainMenu] Exiting...")
	get_tree().quit()
