extends Control
class_name TradeUI
## Interface de comércio

signal trade_confirmed
signal trade_cancelled

var economy_system: EconomySystem = null
var player: Critter = null
var trader: Critter = null

# UI Elements
var player_inventory_list: ItemList = null
var trader_inventory_list: ItemList = null
var player_trade_list: ItemList = null
var trader_trade_list: ItemList = null
var player_caps_label: Label = null
var trader_caps_label: Label = null
var trade_value_label: Label = null
var confirm_button: Button = null
var cancel_button: Button = null

# Trade state
var player_trade_items: Array[Item] = []
var trader_trade_items: Array[Item] = []

func _ready() -> void:
	_setup_ui()

## Inicia trade com um trader
func start_trade(economy: EconomySystem, player_critter: Critter, trader_critter: Critter) -> void:
	economy_system = economy
	player = player_critter
	trader = trader_critter
	
	player_trade_items.clear()
	trader_trade_items.clear()
	
	refresh()
	visible = true

## Atualiza a UI
func refresh() -> void:
	if not player or not trader or not economy_system:
		return
	
	_refresh_inventories()
	_refresh_trade_lists()
	_refresh_caps_display()
	_update_trade_value()

## Atualiza listas de inventário
func _refresh_inventories() -> void:
	if not player_inventory_list or not trader_inventory_list:
		return
	
	player_inventory_list.clear()
	trader_inventory_list.clear()
	
	# Inventário do player
	for item in player.inventory:
		if item:
			var display_text = _get_item_display_text(item)
			player_inventory_list.add_item(display_text)
			player_inventory_list.set_item_metadata(player_inventory_list.get_item_count() - 1, item)
	
	# Inventário do trader
	for item in trader.inventory:
		if item:
			var display_text = _get_item_display_text(item)
			trader_inventory_list.add_item(display_text)
			trader_inventory_list.set_item_metadata(trader_inventory_list.get_item_count() - 1, item)

## Atualiza listas de trade
func _refresh_trade_lists() -> void:
	if not player_trade_list or not trader_trade_list:
		return
	
	player_trade_list.clear()
	trader_trade_list.clear()
	
	# Itens do player para trade
	for item in player_trade_items:
		if item:
			var display_text = _get_item_display_text(item)
			player_trade_list.add_item(display_text)
			player_trade_list.set_item_metadata(player_trade_list.get_item_count() - 1, item)
	
	# Itens do trader para trade
	for item in trader_trade_items:
		if item:
			var display_text = _get_item_display_text(item)
			trader_trade_list.add_item(display_text)
			trader_trade_list.set_item_metadata(trader_trade_list.get_item_count() - 1, item)

## Atualiza display de caps
func _refresh_caps_display() -> void:
	if player_caps_label:
		player_caps_label.text = "Caps: %d" % player.caps
	
	if trader_caps_label:
		trader_caps_label.text = "Caps: %d" % trader.caps

## Atualiza valor do trade
func _update_trade_value() -> void:
	if not trade_value_label or not economy_system:
		return
	
	var player_value = economy_system.calculate_total_value(player_trade_items, trader, player, false)
	var trader_value = economy_system.calculate_total_value(trader_trade_items, player, trader, true)
	
	var difference = trader_value - player_value
	
	if difference > 0:
		trade_value_label.text = "You pay: %d caps" % difference
		trade_value_label.modulate = Color.RED
	elif difference < 0:
		trade_value_label.text = "You receive: %d caps" % (-difference)
		trade_value_label.modulate = Color.GREEN
	else:
		trade_value_label.text = "Even trade"
		trade_value_label.modulate = Color.WHITE

## Quando item do player é selecionado
func _on_player_item_selected(index: int) -> void:
	if not player_inventory_list:
		return
	
	var item = player_inventory_list.get_item_metadata(index) as Item
	if item and not item in player_trade_items:
		player_trade_items.append(item)
		refresh()

## Quando item do trader é selecionado
func _on_trader_item_selected(index: int) -> void:
	if not trader_inventory_list:
		return
	
	var item = trader_inventory_list.get_item_metadata(index) as Item
	if item and not item in trader_trade_items:
		# Verificar se player pode comprar
		if economy_system.can_afford_item(item, player, trader):
			trader_trade_items.append(item)
			refresh()
		else:
			# TODO: Mostrar mensagem de erro
			push_warning("Cannot afford item")

## Remove item do trade do player
func _on_player_trade_item_selected(index: int) -> void:
	if not player_trade_list:
		return
	
	var item = player_trade_list.get_item_metadata(index) as Item
	if item:
		player_trade_items.erase(item)
		refresh()

## Remove item do trade do trader
func _on_trader_trade_item_selected(index: int) -> void:
	if not trader_trade_list:
		return
	
	var item = trader_trade_list.get_item_metadata(index) as Item
	if item:
		trader_trade_items.erase(item)
		refresh()

## Confirma trade
func _on_confirm_pressed() -> void:
	if not economy_system or not player or not trader:
		return
	
	var success = economy_system.execute_trade(player_trade_items, trader_trade_items, player, trader)
	
	if success:
		player_trade_items.clear()
		trader_trade_items.clear()
		refresh()
		trade_confirmed.emit()
		# TODO: Mostrar mensagem de sucesso
	else:
		# TODO: Mostrar mensagem de erro
		push_warning("Trade failed")

## Cancela trade
func _on_cancel_pressed() -> void:
	player_trade_items.clear()
	trader_trade_items.clear()
	visible = false
	trade_cancelled.emit()

## Obtém texto de display para item
func _get_item_display_text(item: Item) -> String:
	if not item:
		return ""
	
	var text = item.item_name
	if item.has_method("get_stack_count") and item.get_stack_count() > 1:
		text += " x%d" % item.get_stack_count()
	
	# Adicionar preço se disponível
	if economy_system and player and trader:
		var price = economy_system.calculate_final_price(item, player, trader, true)
		text += " (%d caps)" % price
	
	return text

## Configura UI
func _setup_ui() -> void:
	if not player_inventory_list:
		_create_basic_ui()

## Cria UI básica
func _create_basic_ui() -> void:
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# Título
	var title = Label.new()
	title.text = "Trade"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	# Container principal (inventários lado a lado)
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	# Coluna do player
	var player_vbox = VBoxContainer.new()
	hbox.add_child(player_vbox)
	
	var player_label = Label.new()
	player_label.text = "Your Inventory"
	player_vbox.add_child(player_label)
	
	player_inventory_list = ItemList.new()
	player_inventory_list.item_selected.connect(_on_player_item_selected)
	player_vbox.add_child(player_inventory_list)
	
	var player_trade_label = Label.new()
	player_trade_label.text = "Your Trade"
	player_vbox.add_child(player_trade_label)
	
	player_trade_list = ItemList.new()
	player_trade_list.item_selected.connect(_on_player_trade_item_selected)
	player_vbox.add_child(player_trade_list)
	
	# Coluna do trader
	var trader_vbox = VBoxContainer.new()
	hbox.add_child(trader_vbox)
	
	var trader_label = Label.new()
	trader_label.text = "Trader Inventory"
	trader_vbox.add_child(trader_label)
	
	trader_inventory_list = ItemList.new()
	trader_inventory_list.item_selected.connect(_on_trader_item_selected)
	trader_vbox.add_child(trader_inventory_list)
	
	var trader_trade_label = Label.new()
	trader_trade_label.text = "Trader Trade"
	trader_vbox.add_child(trader_trade_label)
	
	trader_trade_list = ItemList.new()
	trader_trade_list.item_selected.connect(_on_trader_trade_item_selected)
	trader_vbox.add_child(trader_trade_list)
	
	# Informações de caps e valor
	var info_hbox = HBoxContainer.new()
	vbox.add_child(info_hbox)
	
	player_caps_label = Label.new()
	player_caps_label.text = "Caps: 0"
	info_hbox.add_child(player_caps_label)
	
	trade_value_label = Label.new()
	trade_value_label.text = "Even trade"
	info_hbox.add_child(trade_value_label)
	
	trader_caps_label = Label.new()
	trader_caps_label.text = "Caps: 0"
	info_hbox.add_child(trader_caps_label)
	
	# Botões
	var button_hbox = HBoxContainer.new()
	vbox.add_child(button_hbox)
	
	confirm_button = Button.new()
	confirm_button.text = "Confirm Trade"
	confirm_button.pressed.connect(_on_confirm_pressed)
	button_hbox.add_child(confirm_button)
	
	cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_on_cancel_pressed)
	button_hbox.add_child(cancel_button)
