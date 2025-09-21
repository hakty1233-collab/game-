extends TextureRect

@onready var minimap_viewport : SubViewport = $MinimapViewport
@onready var minimap_camera   : Camera2D    = $MinimapViewport/MinimapCamera
@onready var mini_world       : Node2D      = $MinimapViewport/MiniMapWorld

var player : Node2D
var player_icon : Sprite2D
var loot_icons := []

# Reference to main TileMapLayer
@export var main_tilemap_path : NodePath
var main_tilemap : TileMapLayer
var mini_tilemap : TileMapLayer

# Scaling factor for minimap (used for TileMap, not icons anymore)
@export var scale_factor : float = 0.25

func _ready():
	# Display the SubViewport in this TextureRect
	texture = minimap_viewport.get_texture()
	minimap_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# Find player node
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().root.find_child("Player", true, false)
	
	# Player icon in minimap
	player_icon = Sprite2D.new()
	player_icon.texture = load("res://UI/Icons/otteria_skill_icons.png")  # replace with your icon
	player_icon.centered = true
	mini_world.add_child(player_icon)
	
	# Find the TileMapLayer in the current scene tree
	# This will search the entire tree for a TileMapLayer
	main_tilemap = get_tree().get_first_node_in_group("Player")
	if not main_tilemap:
		# Fallback: search by node type
		main_tilemap = get_tree().root.find_child("TileMapLayer", true, false)
	
	if main_tilemap:
		print("Found main tilemap: ", main_tilemap.name)
		print("Used cells: ", main_tilemap.get_used_cells().size())
		create_minimap_tilemap()
	else:
		print("Could not find TileMapLayer in scene tree")

func _process(delta: float) -> void:
	if not player or not minimap_camera or not visible:
		return
	
	# Camera follows player -> player always centered
	minimap_camera.global_position = player.global_position
	
	# Player marker (world position)
	player_icon.global_position = player.global_position
	
	# Loot markers (world positions)
	for icon_data in loot_icons:
		var loot_node = icon_data["node"]
		if is_instance_valid(loot_node):
			icon_data["icon"].global_position = loot_node.global_position

# Create a lightweight TileMapLayer referencing the main TileMapLayer data
func create_minimap_tilemap():
	mini_tilemap = TileMapLayer.new()
	mini_tilemap.tile_set = main_tilemap.tile_set  # reference same TileSet
	# Don't scale cell_size, scale the whole tilemap instead
	mini_tilemap.scale = Vector2(scale_factor, scale_factor)
	mini_tilemap.position = Vector2.ZERO
	mini_world.add_child(mini_tilemap)
	
	# Initial copy of all cells
	update_minimap()

# Update minimap cells from main TileMapLayer
func update_minimap():
	if not main_tilemap or not mini_tilemap:
		return
	
	mini_tilemap.clear()
	
	# Make sure we're copying all tile data properly
	for cell in main_tilemap.get_used_cells():
		var source_id = main_tilemap.get_cell_source_id(cell)
		var atlas_coords = main_tilemap.get_cell_atlas_coords(cell)
		var alternative_tile = main_tilemap.get_cell_alternative_tile(cell)
		
		if source_id != -1:
			mini_tilemap.set_cell(cell, source_id, atlas_coords, alternative_tile)

# Call this whenever main TileMap changes
func refresh_minimap():
	update_minimap()

# Add a loot icon dynamically
func add_loot_icon(node: Node2D, texture: Texture2D):
	var icon = Sprite2D.new()
	icon.texture = texture
	icon.centered = true
	mini_world.add_child(icon)
	loot_icons.append({"node": node, "icon": icon})

# Remove loot icon
func remove_loot_icon(node: Node2D):
	for i in range(loot_icons.size() - 1, -1, -1):
		if loot_icons[i]["node"] == node:
			if is_instance_valid(loot_icons[i]["icon"]):
				loot_icons[i]["icon"].queue_free()
			loot_icons.remove_at(i)
