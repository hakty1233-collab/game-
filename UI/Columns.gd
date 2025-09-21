extends Control

# Drag the nodes in the Inspector so paths are correct
@export var slots_path: NodePath           # a MarginContainer under this Panel
@export var grid_path: NodePath            # a GridContainer inside the slots

@onready var slots: MarginContainer = get_node_or_null(slots_path) as MarginContainer
@onready var grid : GridContainer   = get_node_or_null(grid_path)  as GridContainer

# --- tune to your art ---
@export var cols := 3
@export var rows := 2
@export var margin_left := 22
@export var margin_right := 22
@export var margin_top := 22
@export var margin_bottom := 22
@export var bar_h := 12        # vertical bar thickness between columns
@export var bar_v := 12        # horizontal bar thickness between rows
# -------------------------

func _ready() -> void:
	if slots == null:
		push_error("[SkillGrid] 'slots' (MarginContainer) not set or not found.")
		return
	if grid == null:
		push_error("[SkillGrid] 'grid' (GridContainer) not set or not found.")
		return

	# make the slots container inset the inner area
	slots.add_theme_constant_override("margin_left",   margin_left)
	slots.add_theme_constant_override("margin_right",  margin_right)
	slots.add_theme_constant_override("margin_top",    margin_top)
	slots.add_theme_constant_override("margin_bottom", margin_bottom)

	_layout_grid()
	resized.connect(_layout_grid)

func _layout_grid() -> void:
	# guard again (in case of scene changes)
	if grid == null or slots == null:
		return

	grid.columns = cols
	grid.add_theme_constant_override("h_separation", bar_h)
	grid.add_theme_constant_override("v_separation", bar_v)

	await get_tree().process_frame # ensure sizes are up-to-date

	var inner_size := slots.get_rect().size
	var cell_w := int(floor((inner_size.x - (cols - 1) * bar_h) / cols))
	var cell_h := int(floor((inner_size.y - (rows - 1) * bar_v) / rows))

	for c in grid.get_children():
		if c is Control:
			c.custom_minimum_size = Vector2(cell_w, cell_h)
