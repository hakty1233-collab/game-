extends Control

# Parallax speeds (slower = further back, faster = closer to camera)
@export var background_speeds: Array[float] = [10.0, 20.0, 30.0, 40.0]  # For layers 1-4
@export var tilemap_speed: float = 60.0
@export var tree_speed: float = 80.0
@export var campfire_speed: float = 80.0  # Same layer as tree
@export var cloud_speeds: Array[float] = [5.0, 7.0, 12.0]  # Very slow for clouds

# Node references - adjust paths to match your scene
@onready var background_layer1: Sprite2D = $Background_layer1
@onready var background_layer2: Sprite2D = $Background_layer2
@onready var background_layer3: Sprite2D = $Background_layer3
@onready var background_layer4: Sprite2D = $Background_layer4
@onready var tilemap_layer: TileMapLayer = $TileMapLayer
@onready var campfire: AnimatedSprite2D = $Campfire
@onready var tree: Sprite2D = $Tree
@onready var cloud1: Sprite2D = $cloud
@onready var cloud2: Sprite2D = $cloud2
@onready var cloud3: Sprite2D = $cloud3

# Arrays to store duplicated sprites for seamless scrolling
var background_sprites: Array[Array] = [[], [], [], []]
var cloud_sprites: Array[Array] = [[], [], []]
var tree_sprites: Array[Sprite2D] = []
var campfire_sprites: Array[AnimatedSprite2D] = []
var tilemap_sprites: Array[TileMapLayer] = []

var screen_width: float = 0.0

func _ready():
	screen_width = get_viewport().get_visible_rect().size.x
	_setup_parallax_layers()

func _setup_parallax_layers():
	# Setup background layers
	var bg_layers = [background_layer1, background_layer2, background_layer3, background_layer4]
	for i in range(bg_layers.size()):
		if bg_layers[i]:
			_setup_layer_scrolling(bg_layers[i], background_sprites[i])
	
	# Setup clouds
	var clouds = [cloud1, cloud2, cloud3]
	for i in range(clouds.size()):
		if clouds[i]:
			_setup_layer_scrolling(clouds[i], cloud_sprites[i])
	
	# Setup tree
	if tree:
		_setup_layer_scrolling(tree, tree_sprites)
	
	# Setup campfire
	if campfire:
		_setup_campfire_scrolling()
	
	# Setup tilemap
	if tilemap_layer:
		_setup_tilemap_scrolling()

func _setup_layer_scrolling(original_sprite: Node2D, sprite_array: Array):
	if not original_sprite:
		return
	
	var sprite_width = 0.0
	
	# Get width based on node type
	if original_sprite is Sprite2D:
		var sprite = original_sprite as Sprite2D
		sprite_width = sprite.texture.get_width() * sprite.scale.x if sprite.texture else 200.0
	elif original_sprite is TileMapLayer:
		sprite_width = 1920.0  # Adjust based on your tilemap width
	
	# Calculate how many copies we need
	var copies_needed = ceil(screen_width / sprite_width) + 2
	
	# Add the original to the array
	sprite_array.append(original_sprite)
	
	# Create duplicates
	for i in range(1, copies_needed):
		var duplicate = original_sprite.duplicate()
		duplicate.position.x = original_sprite.position.x + (sprite_width * i)
		original_sprite.get_parent().add_child(duplicate)
		sprite_array.append(duplicate)

func _setup_campfire_scrolling():
	var campfire_width = 64.0  # Estimate based on your campfire sprite
	var copies_needed = ceil(screen_width / campfire_width) + 2
	
	campfire_sprites.append(campfire)
	
	for i in range(1, copies_needed):
		var duplicate = campfire.duplicate() as AnimatedSprite2D
		duplicate.position.x = campfire.position.x + (campfire_width * i)
		campfire.get_parent().add_child(duplicate)
		campfire_sprites.append(duplicate)

func _setup_tilemap_scrolling():
	var tilemap_width = 1920.0  # Adjust this to your actual tilemap width
	var copies_needed = 2  # Usually just need 2 copies for tilemaps
	
	tilemap_sprites.append(tilemap_layer)
	
	for i in range(1, copies_needed):
		var duplicate = tilemap_layer.duplicate() as TileMapLayer
		duplicate.position.x = tilemap_layer.position.x + (tilemap_width * i)
		tilemap_layer.get_parent().add_child(duplicate)
		tilemap_sprites.append(duplicate)

func _process(delta: float):
	_scroll_background_layers(delta)
	_scroll_clouds(delta)
	_scroll_tree(delta)
	_scroll_campfire(delta)
	_scroll_tilemap(delta)

func _scroll_background_layers(delta: float):
	for i in range(background_sprites.size()):
		if i >= background_speeds.size():
			continue
			
		var speed = background_speeds[i]
		for sprite in background_sprites[i]:
			if sprite and is_instance_valid(sprite):
				sprite.position.x -= speed * delta
				
				# Reset position when off-screen
				if sprite.position.x <= -_get_sprite_width(sprite):
					var rightmost_x = _get_rightmost_position(background_sprites[i])
					sprite.position.x = rightmost_x

func _scroll_clouds(delta: float):
	for i in range(cloud_sprites.size()):
		if i >= cloud_speeds.size():
			continue
			
		var speed = cloud_speeds[i]
		for cloud in cloud_sprites[i]:
			if cloud and is_instance_valid(cloud):
				cloud.position.x -= speed * delta
				
				if cloud.position.x <= -_get_sprite_width(cloud):
					var rightmost_x = _get_rightmost_position(cloud_sprites[i])
					cloud.position.x = rightmost_x

func _scroll_tree(delta: float):
	for tree_sprite in tree_sprites:
		if tree_sprite and is_instance_valid(tree_sprite):
			tree_sprite.position.x -= tree_speed * delta
			
			if tree_sprite.position.x <= -_get_sprite_width(tree_sprite):
				var rightmost_x = _get_rightmost_position(tree_sprites)
				tree_sprite.position.x = rightmost_x

func _scroll_campfire(delta: float):
	for campfire_sprite in campfire_sprites:
		if campfire_sprite and is_instance_valid(campfire_sprite):
			campfire_sprite.position.x -= campfire_speed * delta
			
			if campfire_sprite.position.x <= -64.0:  # Campfire width estimate
				var rightmost_x = _get_rightmost_position(campfire_sprites)
				campfire_sprite.position.x = rightmost_x

func _scroll_tilemap(delta: float):
	for tilemap in tilemap_sprites:
		if tilemap and is_instance_valid(tilemap):
			tilemap.position.x -= tilemap_speed * delta
			
			if tilemap.position.x <= -1920.0:  # Adjust to your tilemap width
				var rightmost_x = _get_rightmost_position(tilemap_sprites)
				tilemap.position.x = rightmost_x

# Helper functions
func _get_sprite_width(sprite: Node2D) -> float:
	if sprite is Sprite2D:
		var s = sprite as Sprite2D
		return s.texture.get_width() * s.scale.x if s.texture else 200.0
	elif sprite is TileMapLayer:
		return 1920.0  # Adjust based on your tilemap
	else:
		return 100.0  # Default fallback

func _get_rightmost_position(sprite_array: Array) -> float:
	var rightmost_x = -999999.0
	for sprite in sprite_array:
		if sprite and is_instance_valid(sprite):
			var sprite_right = sprite.position.x + _get_sprite_width(sprite)
			if sprite_right > rightmost_x:
				rightmost_x = sprite_right
	return rightmost_x
