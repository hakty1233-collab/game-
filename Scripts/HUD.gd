extends CanvasLayer

# ---------- Node refs ----------
@onready var skills_panel    : Control       = $MainHUD/SkillUI
@onready var skill_grid      : GridContainer = $MainHUD/SkillUI/Slots/GridContainer
@onready var inv_panel       : Control       = $MainHUD/InventoryUI
@onready var inv_grid        : GridContainer = $MainHUD/InventoryUI/GridContainer
@onready var toolbelt_panel  : Control       = $MainHUD/ToolBeltUI
@onready var total_label     : Label         = $MainHUD/TotalLevelLabel
@onready var player_marker   : Node2D        = $MainHUD/MiniMap/Control/Sprite2D

@onready var btn_inv         : BaseButton    = $ToggleInventory
@onready var btn_toolbelt    : BaseButton    = $ToggleToolBelt
@onready var btn_skills      : BaseButton    = $ToggleSkills
@onready var btn_map         : BaseButton    = $OpenMap

# ---------- Movable panels ----------
var _dragging_panel : Control = null
var _drag_offset    : Vector2 = Vector2.ZERO

# ---------- Minimap ----------
const MINIMAP_SCALE : float = 0.08
var minimap_origin : Vector2 = Vector2.ZERO

# ---------- Skill tiles ----------
const TILE_WOODCUTTING := preload("res://UI/Skills/SkillTile_Woodcutting.tscn")
const TILE_FISHING     := preload("res://UI/Skills/SkillTile_Fishing.tscn")
const TILE_MINING      := preload("res://UI/Skills/SkillTile_Mining.tscn")
var _skills_built := false

# ---------- XP popups ----------
var _xp_popup_layer: Control = null

# ---------- Skill panel layout (tune to your art) ----------
@export var SKILL_COLS := 3
@export var SKILL_ROWS := 2
@export var SKILL_MARGIN_LEFT  := 55
@export var SKILL_MARGIN_RIGHT := 55
@export var SKILL_MARGIN_TOP   := -35
@export var SKILL_MARGIN_BOTTOM:= -35
@export var SKILL_BAR_H := 40
@export var SKILL_BAR_V := 25

func _ready() -> void:
	add_to_group("hud")

	# Buttons
	btn_inv.pressed.connect(_toggle_inventory)
	btn_toolbelt.pressed.connect(_toggle_toolbelt)
	btn_skills.pressed.connect(_toggle_skills)
	btn_map.pressed.connect(_open_map)

	# Skill signals
	if SkillManager.has_signal("skill_updated"):
		SkillManager.skill_updated.connect(_on_skill_updated)
	if SkillManager.has_signal("level_up"):
		SkillManager.level_up.connect(_on_level_up)
	if SkillManager.has_signal("xp_gained"):
		SkillManager.xp_gained.connect(_on_xp_gained)

	# Auto-refresh inventory when items change
	if PlayerInventory.has_signal("inventory_changed"):
		PlayerInventory.inventory_changed.connect(_load_inventory)

	# Layout base
	skills_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	skill_grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	skill_grid.columns = 3
	skill_grid.add_theme_constant_override("h_separation", 6)
	skill_grid.add_theme_constant_override("v_separation", 6)
	skills_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skills_panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	skill_grid.size_flags_horizontal   = Control.SIZE_EXPAND_FILL
	skill_grid.size_flags_vertical     = Control.SIZE_EXPAND_FILL

	# Re-layout grid when the panel resizes
	skills_panel.resized.connect(_layout_skill_grid)

	_ensure_xp_popup_layer()

	# Start panels hidden
	skills_panel.visible = false
	inv_panel.visible = false
	if toolbelt_panel:
		toolbelt_panel.visible = false

	_load_inventory()
	_update_total_level()

	# Make panels draggable
	_make_panel_draggable(skills_panel)
	_make_panel_draggable(inv_panel)
	if toolbelt_panel:
		_make_panel_draggable(toolbelt_panel)

func _process(_dt: float) -> void:
	var p: Node2D = PlayerGlobals.instance as Node2D
	if p == null:
		p = get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(player_marker) and is_instance_valid(p):
		player_marker.position = (p.global_position - minimap_origin) * MINIMAP_SCALE

# ---------- Panel dragging ----------
func _make_panel_draggable(panel: Control) -> void:
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.connect("gui_input", Callable(self, "_on_panel_input").bind(panel))

func _on_panel_input(event: InputEvent, panel: Control) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging_panel = panel
				_drag_offset = panel.get_global_position() - event.position
			else:
				if _dragging_panel == panel:
					_dragging_panel = null
	elif event is InputEventMouseMotion:
		if _dragging_panel == panel:
			panel.global_position = event.position + _drag_offset

# ---------- Panel toggles (mutually exclusive) ----------
func _toggle_inventory() -> void:
	inv_panel.visible = !inv_panel.visible
	if inv_panel.visible:
		skills_panel.visible = false
		if toolbelt_panel: toolbelt_panel.visible = false
		_load_inventory()

func _toggle_toolbelt() -> void:
	if toolbelt_panel == null:
		push_warning("[HUD] ToolBeltUI not found at $MainHUD/ToolBeltUI")
		return
	toolbelt_panel.visible = !toolbelt_panel.visible
	if toolbelt_panel.visible:
		inv_panel.visible = false
		skills_panel.visible = false

func _toggle_skills() -> void:
	skills_panel.visible = !skills_panel.visible
	if skills_panel.visible:
		inv_panel.visible = false
		if toolbelt_panel: toolbelt_panel.visible = false
		if not _skills_built:
			_build_skill_tiles_once()
		_layout_skill_grid()

# ---------- Skills ----------
func _build_skill_tiles_once() -> void:
	_clear_grid(skill_grid)
	var tiles := [
		TILE_WOODCUTTING.instantiate(),
		TILE_FISHING.instantiate(),
		TILE_MINING.instantiate()
	]
	for t in tiles:
		if t is Control:
			t.custom_minimum_size = Vector2(56, 64)
			t.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			t.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
		skill_grid.add_child(t)
	_skills_built = true
	_layout_skill_grid()

func _on_skill_updated(_skill: String, _lvl: int, _xp: int) -> void:
	_update_total_level()

func _on_level_up(_skill: String, _new_lvl: int) -> void:
	_update_total_level()

func _update_total_level() -> void:
	var total: int = 0
	for s in SkillManager.skills.values():
		total += int((s as Dictionary).get("level", 1))
	total_label.text = "Total Level: %d" % total

# ---------- Skill panel layout helper ----------
func _layout_skill_grid() -> void:
	if !is_instance_valid(skills_panel) or !is_instance_valid(skill_grid):
		return

	var inner_pos  := Vector2(SKILL_MARGIN_LEFT, SKILL_MARGIN_TOP)
	var inner_size := Vector2(
		max(0.0, skills_panel.size.x - SKILL_MARGIN_LEFT - SKILL_MARGIN_RIGHT),
		max(0.0, skills_panel.size.y - SKILL_MARGIN_TOP - SKILL_MARGIN_BOTTOM)
	)

	skill_grid.columns = SKILL_COLS
	skill_grid.add_theme_constant_override("h_separation", SKILL_BAR_H)
	skill_grid.add_theme_constant_override("v_separation", SKILL_BAR_V)

	skill_grid.anchor_left = 0
	skill_grid.anchor_right = 0
	skill_grid.anchor_top = 0
	skill_grid.anchor_bottom = 0
	skill_grid.position = inner_pos
	skill_grid.size     = inner_size
	skill_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skill_grid.size_flags_vertical   = Control.SIZE_SHRINK_CENTER

	var cell_w := 0
	var cell_h := 0
	if SKILL_COLS > 0:
		cell_w = int((inner_size.x - (SKILL_COLS - 1) * SKILL_BAR_H) / SKILL_COLS)
	if SKILL_ROWS > 0:
		cell_h = int((inner_size.y - (SKILL_ROWS - 1) * SKILL_BAR_V) / SKILL_ROWS)

	for c in skill_grid.get_children():
		if c is Control:
			c.custom_minimum_size = Vector2(max(0, cell_w), max(0, cell_h))

	skill_grid.queue_sort()

# ---------- XP popups ----------
func _ensure_xp_popup_layer() -> void:
	if has_node("MainHUD/XP_Popups"):
		_xp_popup_layer = $MainHUD/XP_Popups
		return
	var layer := Control.new()
	layer.name = "XP_Popups"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	_xp_popup_layer = layer

func _on_xp_gained(skill_name: String, amount: int, lvl: int, xp: int) -> void:
	var needed: int = SkillManager.get_xp_for_next_level(skill_name)
	var icon: Texture2D = _get_skill_icon(skill_name)
	_spawn_xp_popup(skill_name, amount, xp, needed, icon)

func _spawn_xp_popup(skill_name: String, gained: int, current_xp: int, needed: int, icon: Texture2D) -> void:
	if _xp_popup_layer == null:
		return
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size = Vector2(260, 24)

	var icon_rect := TextureRect.new()
	icon_rect.texture = icon
	icon_rect.custom_minimum_size = Vector2(20,20)
	row.add_child(icon_rect)

	var label := Label.new()
	label.text = "+%d %s" % [gained, skill_name]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var bar := TextureProgressBar.new()
	bar.min_value = 0
	bar.max_value = max(1, needed)
	bar.value = clamp(current_xp, 0, int(bar.max_value))
	bar.custom_minimum_size = Vector2(120, 12)
	row.add_child(bar)

	_xp_popup_layer.add_child(row)

	await get_tree().process_frame
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var cam: Camera2D = get_viewport().get_camera_2d()
	var player: Node2D = PlayerGlobals.instance as Node2D
	var mid_y: float = 40.0
	if cam and player:
		var player_screen: Vector2 = (player.global_position - cam.global_position) * cam.zoom + vp_size * 0.5
		mid_y = lerpf(16.0, player_screen.y, 0.5)

	row.position = Vector2(vp_size.x * 0.5 - row.size.x * 0.5, mid_y)

	var tween := create_tween()
	tween.tween_property(row, "position:y", row.position.y - 18.0, 0.25)
	tween.tween_interval(0.9)
	tween.tween_property(row, "modulate:a", 0.0, 0.35)
	tween.finished.connect(Callable(row, "queue_free"))

func _get_skill_icon(skill_name: String) -> Texture2D:
	var per_skill := "res://UI/Skills/%s.png" % skill_name
	if ResourceLoader.exists(per_skill):
		return load(per_skill)
	var fallback := "res://UI/Icons/otteria_skill_icons.png"
	if ResourceLoader.exists(fallback):
		return load(fallback)
	return Texture2D.new()

# ---------- Inventory ----------
func _slot_scene() -> PackedScene:
	var paths := [
		"res://UI/item_slot.tscn",
		"res://UI/Item_Slot.tscn"
	]
	for p in paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null

func _load_inventory() -> void:
	_clear_grid(inv_grid)
	inv_grid.columns = 5
	inv_grid.add_theme_constant_override("h_separation", -19)
	inv_grid.add_theme_constant_override("v_separation", -19)

	var slot_scene := _slot_scene()
	for item in PlayerInventory.get_items():
		if slot_scene:
			var slot: Control = slot_scene.instantiate()
			if slot.has_method("set_item"):
				slot.set_item(item)
			slot.size_flags_horizontal = Control.SIZE_FILL
			slot.size_flags_vertical = Control.SIZE_FILL
			slot.custom_minimum_size = Vector2(64, 64)
			
			# Connect to tool equip signals if this slot supports it
			if slot.has_signal("tool_equipped"):
				slot.tool_equipped.connect(_on_tool_equipped)
			
			inv_grid.add_child(slot)
		else:
			var lbl := Label.new()
			lbl.text = "%s x%d" % [String(item.get("name","?")), int(item.get("quantity",1))]
			inv_grid.add_child(lbl)

# Handle tool equipping from inventory slots
func _on_tool_equipped(tool_name: String, skill: String) -> void:
	print("[HUD] Tool equipped: %s for %s" % [tool_name, skill])
	# Refresh inventory to show updated quantities
	_load_inventory()

# ---------- Map ----------
func _open_map() -> void:
	var mm := $MainHUD/MiniMap
	mm.visible = !mm.visible

# ---------- Utils ----------
func _clear_grid(grid: Control) -> void:
	for c in grid.get_children():
		c.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		if Autoload.save_game():
			print("[HUD] Saved.")
	if event.is_action_pressed("load_game"):
		if Autoload.load_game():
			print("[HUD] Loaded.")
	# Removed auto-equip lines - players now click tools to equip them!
