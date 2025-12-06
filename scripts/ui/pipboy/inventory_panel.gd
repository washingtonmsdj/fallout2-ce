extends Control
class_name InventoryPanel
## Painel de inventário do Pipboy

signal item_selected(item: Item)
signal item_used(item: Item)

var player: Critter = null

var items_container: ItemList = null
var weight_label: Label = null
var value_label: Label = null
var item_details_label: Label = null

# Categorias de itens
enum ItemCategory {
	ALL,
	WEAPONS,
	ARMOR,
	AMMO,
	DRUGS,
	FOOD,
	MISC
}

var current_category: ItemCategory = ItemCategory.ALL

func _ready() -> void:
	_setup_ui()

## Define o jogador
func set_player(player_critter: Critter) -> void:
	player = player_critter
	refresh()

## Atualiza o conteúdo do painel
func refresh() -> void:
	if not player:
		return
	
	_refresh_items()
	_refresh_totals()

## Atualiza a lista de itens
func _refresh_items() -> void:
	if not items_container:
		return
	
	items_container.clear()
	
	if not player or not player.inventory:
		return
	
	# Filtrar itens por categoria
	var filtered_items = _get_filtered_items()
	
	# Adicionar itens à lista
	for item in filtered_items:
		if item:
			var display_text = _get_item_display_text(item)
			items_container.add_item(display_text)
			items_container.set_item_metadata(items_container.get_item_count() - 1, item)

## Obtém itens filtrados por categoria
func _get_filtered_items() -> Array[Item]:
	if not player or not player.inventory:
		return []
	
	if current_category == ItemCategory.ALL:
		return player.inventory
	
	var filtered: Array[Item] = []
	
	for item in player.inventory:
		if not item:
			continue
		
		match current_category:
			ItemCategory.WEAPONS:
				if item is Weapon:
					filtered.append(item)
			ItemCategory.ARMOR:
				if item is Armor:
					filtered.append(item)
			ItemCategory.AMMO:
				# TODO: Implementar quando sistema de munição estiver pronto
				pass
			ItemCategory.DRUGS:
				# TODO: Implementar quando sistema de drogas estiver pronto
				pass
			ItemCategory.FOOD:
				# TODO: Implementar quando sistema de comida estiver pronto
				pass
			ItemCategory.MISC:
				if not (item is Weapon or item is Armor):
					filtered.append(item)
	
	return filtered

## Obtém texto de exibição para um item
func _get_item_display_text(item: Item) -> String:
	if not item:
		return "Unknown Item"
	
	var text = item.item_name
	if item.stackable and item.stack_count > 1:
		text += " x%d" % item.stack_count
	
	# Adicionar informações adicionais
	if item is Weapon:
		var weapon = item as Weapon
		text += " [DMG: %d]" % weapon.damage
	elif item is Armor:
		var armor = item as Armor
		text += " [AC: %d]" % armor.armor_class
	
	return text

## Atualiza totais (peso e valor)
func _refresh_totals() -> void:
	if not player or not player.stats:
		return
	
	# Peso total
	var total_weight = 0.0
	if player.inventory:
		for item in player.inventory:
			if item:
				var quantity = item.stack_count if item.stackable else 1
				total_weight += item.weight * quantity
	
	if weight_label:
		weight_label.text = "Weight: %.1f / %.1f" % [total_weight, player.stats.max_carry_weight]
	
	# Valor total
	var total_value = 0
	if player.inventory:
		for item in player.inventory:
			if item:
				var quantity = item.stack_count if item.stackable else 1
				total_value += item.value * quantity
	
	if value_label:
		value_label.text = "Value: %d caps" % total_value

## Quando um item é selecionado
func _on_item_selected(index: int) -> void:
	if not items_container:
		return
	
	var item = items_container.get_item_metadata(index) as Item
	if item:
		item_selected.emit(item)
		_show_item_details(item)

## Mostra detalhes do item
func _show_item_details(item: Item) -> void:
	if not item_details_label:
		return
	
	var details = item.item_name + "\n"
	details += "Weight: %.1f\n" % item.weight
	details += "Value: %d caps\n" % item.value
	
	if item.description:
		details += "\n" + item.description
	
	item_details_label.text = details

## Usa um item selecionado
func use_selected_item() -> void:
	if not items_container:
		return
	
	var selected = items_container.get_selected_items()
	if selected.is_empty():
		return
	
	var index = selected[0]
	var item = items_container.get_item_metadata(index) as Item
	
	if item:
		_use_item(item)

## Usa um item
func _use_item(item: Item) -> void:
	if not item or not player:
		return
	
	# Tentar usar o item
	var use_result = item.use(player)
	
	# Emitir sinal
	item_used.emit(item)
	
	# Se o item foi usado com sucesso e é consumível, remover do inventário
	if use_result:
		# Verificar se é um item consumível (stackable ou quantidade > 1)
		if item.stackable:
			# Remover uma unidade do stack
			item.remove_from_stack(1)
			if item.stack_count <= 0:
				# Se o stack acabou, remover do inventário
				player.inventory.erase(item)
		else:
			# Item não stackable - remover completamente
			player.inventory.erase(item)
		
		# Atualizar inventário
		refresh()
		
		# Atualizar painel de status se necessário
		# (para mostrar mudanças em HP, stats, etc)
		if get_parent() and get_parent() is PipboyUI:
			var pipboy = get_parent() as PipboyUI
			pipboy.refresh_current_tab()

## Configura a UI
func _setup_ui() -> void:
	if not items_container:
		_create_basic_ui()

## Cria UI básica
func _create_basic_ui() -> void:
	var vbox = VBoxContainer.new()
	vbox.name = "ContentVBox"
	add_child(vbox)
	
	# Labels de totais
	var totals_hbox = HBoxContainer.new()
	vbox.add_child(totals_hbox)
	
	weight_label = Label.new()
	weight_label.name = "WeightLabel"
	totals_hbox.add_child(weight_label)
	
	value_label = Label.new()
	value_label.name = "ValueLabel"
	totals_hbox.add_child(value_label)
	
	# Lista de itens
	items_container = ItemList.new()
	items_container.name = "ItemsList"
	items_container.item_selected.connect(_on_item_selected)
	items_container.item_activated.connect(func(index): use_selected_item())
	vbox.add_child(items_container)
	
	# Detalhes do item
	item_details_label = Label.new()
	item_details_label.name = "ItemDetailsLabel"
	item_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(item_details_label)
