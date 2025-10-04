extends Control

@onready var shop_panel: Panel = $ShopPanel
@onready var close_button: Button = $ShopPanel/CloseButton
@onready var vendor_name_label: Label = $ShopPanel/VendorName
@onready var currency_label: Label = $ShopPanel/CurrencyLabel
@onready var item_container: VBoxContainer = $ShopPanel/ItemContainer

var current_vendor: VendorNPC = null

func _ready():
	visible = false
	close_button.pressed.connect(_close_shop)
	
	# Connect all pre-made buy buttons
	_connect_buy_buttons()

func _connect_buy_buttons():
	var items = item_container.get_children()
	for i in range(items.size()):
		var item_row = items[i]
		if not item_row is HBoxContainer:
			continue
		
		var buy_button = item_row.get_node_or_null("BuyButton")
		if buy_button:
			buy_button.pressed.connect(func(): _on_buy_pressed(i))
			print("[ShopUI] Connected button ", i)

func open_shop(vendor: VendorNPC):
	if not vendor:
		return
	
	current_vendor = vendor
	vendor_name_label.text = vendor.vendor_name
	
	# Update pre-made item rows with vendor's items
	var items = item_container.get_children()
	for i in range(items.size()):
		var item_row = items[i]
		if not item_row is HBoxContainer:
			continue
		
		if i < vendor.shop_items.size():
			var item_data = vendor.shop_items[i]
			var name_label = item_row.get_node_or_null("NameLabel")
			var price_label = item_row.get_node_or_null("PriceLabel")
			var buy_button = item_row.get_node_or_null("BuyButton")
			
			if name_label:
				name_label.text = item_data.get("name", "?")
			if price_label:
				price_label.text = str(item_data.get("price", 0)) + " coins"
			if buy_button:
				buy_button.disabled = false
			
			item_row.visible = true
		else:
			# Hide unused rows
			item_row.visible = false
	
	_update_currency_display()
	visible = true
	print("[ShopUI] Shop opened")

func _on_buy_pressed(item_index: int):
	print("[ShopUI] Buy pressed for index: ", item_index)
	
	if not current_vendor:
		return
	
	if item_index >= current_vendor.shop_items.size():
		return
	
	var item = current_vendor.shop_items[item_index]
	var price = item.get("price", 0)
	
	if current_vendor.purchase_item(item_index):
		print("[ShopUI] Purchase successful!")
		_update_currency_display()

func _close_shop():
	visible = false
	current_vendor = null

func _update_currency_display():
	currency_label.text = "Coins: 999999"
