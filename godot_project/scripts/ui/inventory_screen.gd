extends Control

## Tela de Inventário Completa do Fallout 2
## Grid de itens, slots de equipamento, info de peso

signal closed()

var player: Node = null
var inventory_system: Node = null

# Referências
var items_grid: GridContainer = null
var equipment_slots: Dictionary = {}
var weight_label: Label = null

func _ready():
	visible = false
	inventory_system = get_node_or_null("/root/InventorySystem")
	_setup_ui()
	
	# Conectar ao inventário
	if inventory_system:
		inventory_system.inventory_changed.connect(_on_inventory_changed)
		inventory_system.weight_changed.connect(_on_weight_changed)

func _setup_ui():
	"""Configura elementos da UI"""
	# Layout principal
	var main_hbox = HBoxContainer.new()
	main_hbox.name = "MainHBox"
	main_hbox.anchors_preset = Control.PRESET_FULL_RECT
	add_child(main_hbox)
	
	# Painel esquerdo - Grid de itens
	var items_panel = VBoxContainer.new()
	items_panel.name = "ItemsPanel"
	items_panel.custom_minimum_size = Vector2(400, 500)
	main_hbox.add_child(items_panel)
	
	var items_title = Label.new()
	items_title.text = "INVENTORY"
	items_panel.add_child(items_title)
	
	# Grid de itens
	items_grid = GridContainer.new()
	items_grid.name = "ItemsGrid"
	items_grid.columns = 4
	items_panel.add_child(items_grid)
	
	# Painel direito - Equipamento
	var equipment_panel = VBoxContainer.new()
	equipment_panel.name = "EquipmentPanel"
	equipment_panel.custom_minimum_size = Vector2(200, 500)
	main_hbox.add_child(equipment_panel)
	
	var equipment_title = Label.new()
	equipment_title.text = "EQUIPMENT"
	equipment_panel.add_child(equipment_title)
	
	# Slots de equipamento
	_create_equipment_slot(equipment_panel, "Armor", "armor")
	_create_equipment_slot(equipment_panel, "Left Hand", "left_hand")
	_create_equipment_slot(equipment_panel, "Right Hand", "right_hand")
	
	# Info de peso
	var weight_container = HBoxContainer.new()
	weight_label = Label.new()
	weight_label.name = "WeightLabel"
	weight_label.text = "Weight: 0/150"
	weight_container.add_child(weight_label)
	equipment_panel.add_child(weight_container)
	
	# Botão fechar
	var close_button = Button.new()
	close_button.text = "Close (I)"
	close_button.pressed.connect(_on_close)
	equipment_panel.add_child(close_button)

func _create_equipment_slot(parent: Control, label_text: String, slot_name: String):
	"""Cria um slot de equipamento"""
	var slot_container = VBoxContainer.new()
	slot_container.name = slot_name + "Slot"
	
	var label = Label.new()
	label.text = label_text
	slot_container.add_child(label)
	
	var slot_button = Button.new()
	slot_button.name = "SlotButton"
	slot_button.custom_minimum_size = Vector2(80, 80)
	slot_button.text = "Empty"
	slot_button.pressed.connect(func(): _on_equipment_slot_clicked(slot_name))
	slot_container.add_child(slot_button)
	
	equipment_slots[slot_name] = slot_button
	parent.add_child(slot_container)

func open():
	"""Abre a tela de inventário"""
	visible = true
	_update_display()

func close():
	"""Fecha a tela de inventário"""
	visible = false
	closed.emit()

func _on_close():
	"""Callback do botão fechar"""
	close()

func _on_inventory_changed():
	"""Atualiza quando inventário muda"""
	_update_display()

func _on_weight_changed(current: int, max_weight: int):
	"""Atualiza quando peso muda"""
	if weight_label:
		weight_label.text = "Weight: %d/%d" % [current, max_weight]

func _update_display():
	"""Atualiza display do inventário"""
	if not inventory_system:
		return
	
	# Limpar grid
	for child in items_grid.get_children():
		child.queue_free()
	
	# Adicionar itens
	var items = inventory_system.get_all_items()
	for item in items:
		var item_button = Button.new()
		item_button.text = item.get("name", "Unknown")
		if item.get("quantity", 1) > 1:
			item_button.text += " x" + str(item.get("quantity", 1))
		item_button.custom_minimum_size = Vector2(80, 80)
		item_button.pressed.connect(func(): _on_item_clicked(item))
		items_grid.add_child(item_button)
	
	# Atualizar slots de equipamento
	_update_equipment_slots()
	
	# Atualizar peso
	var weight_info = inventory_system.get_weight_info()
	if weight_label:
		weight_label.text = "Weight: %d/%d" % [weight_info.current, weight_info.max]

func _update_equipment_slots():
	"""Atualiza slots de equipamento"""
	if not inventory_system:
		return
	
	for slot_name in equipment_slots:
		var slot_button = equipment_slots[slot_name]
		var equipped = inventory_system.get_equipped(slot_name)
		
		if not equipped.is_empty():
			slot_button.text = equipped.get("name", "Equipped")
		else:
			slot_button.text = "Empty"

func _on_item_clicked(item: Dictionary):
	"""Callback quando item é clicado"""
	print("InventoryScreen: Item clicado: ", item.get("name", "Unknown"))
	# TODO: Mostrar opções (usar, equipar, descartar)

func _on_equipment_slot_clicked(slot_name: String):
	"""Callback quando slot de equipamento é clicado"""
	print("InventoryScreen: Slot clicado: ", slot_name)
	# TODO: Mostrar opções de equipamento

func _input(event: InputEvent):
	"""Processa input para fechar tela"""
	if visible and event.is_action_pressed("ui_cancel"):
		close()
	if visible and event.is_action_pressed("inventory"):
		close()

