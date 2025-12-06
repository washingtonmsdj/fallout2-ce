extends Control
class_name PartyManagementUI
## UI para gerenciamento de party e companheiros

signal companion_selected(companion: Critter)
signal equipment_changed(companion: Critter)
signal behavior_changed(companion: Critter)

var party_system: PartySystem = null
var selected_companion: Critter = null

# UI Elements
var companions_list: ItemList = null
var companion_details: VBoxContainer = null
var equipment_panel: VBoxContainer = null
var behavior_panel: VBoxContainer = null

func _ready() -> void:
	_setup_ui()

## Define o sistema de party
func set_party_system(system: PartySystem) -> void:
	party_system = system
	refresh()

## Atualiza a UI
func refresh() -> void:
	if not party_system:
		return
	
	_refresh_companions_list()
	_refresh_selected_companion()

## Atualiza lista de companheiros
func _refresh_companions_list() -> void:
	if not companions_list or not party_system:
		return
	
	companions_list.clear()
	
	for companion in party_system.party_members:
		if companion:
			var display_text = companion.critter_name
			if companion.stats:
				display_text += " (HP: %d/%d)" % [companion.stats.current_hp, companion.stats.max_hp]
			companions_list.add_item(display_text)
			companions_list.set_item_metadata(companions_list.get_item_count() - 1, companion)

## Atualiza detalhes do companheiro selecionado
func _refresh_selected_companion() -> void:
	if not selected_companion or not companion_details:
		return
	
	# Limpar detalhes anteriores
	for child in companion_details.get_children():
		child.queue_free()
	
	# Mostrar stats
	var stats_label = Label.new()
	stats_label.text = "Stats:\n"
	if selected_companion.stats:
		stats_label.text += "HP: %d/%d\n" % [selected_companion.stats.current_hp, selected_companion.stats.max_hp]
		stats_label.text += "AP: %d/%d\n" % [selected_companion.stats.current_ap, selected_companion.stats.max_ap]
		stats_label.text += "Level: %d\n" % selected_companion.level
	companion_details.add_child(stats_label)
	
	# Mostrar equipamento
	_refresh_equipment_panel()
	
	# Mostrar configurações de comportamento
	_refresh_behavior_panel()

## Atualiza painel de equipamento
func _refresh_equipment_panel() -> void:
	if not equipment_panel or not selected_companion:
		return
	
	# Limpar painel
	for child in equipment_panel.get_children():
		child.queue_free()
	
	var equipment_label = Label.new()
	equipment_label.text = "Equipment:"
	equipment_panel.add_child(equipment_label)
	
	# Arma equipada
	var weapon_label = Label.new()
	if selected_companion.equipped_weapon:
		weapon_label.text = "Weapon: %s" % selected_companion.equipped_weapon.item_name
	else:
		weapon_label.text = "Weapon: None"
	equipment_panel.add_child(weapon_label)
	
	# Armadura equipada
	var armor_label = Label.new()
	if selected_companion.equipped_armor:
		armor_label.text = "Armor: %s" % selected_companion.equipped_armor.item_name
	else:
		armor_label.text = "Armor: None"
	equipment_panel.add_child(armor_label)
	
	# Botão para gerenciar equipamento (TODO: implementar quando sistema de inventário estiver completo)
	var equip_button = Button.new()
	equip_button.text = "Manage Equipment"
	equip_button.pressed.connect(func(): _on_manage_equipment_pressed())
	equipment_panel.add_child(equip_button)

## Atualiza painel de comportamento
func _refresh_behavior_panel() -> void:
	if not behavior_panel or not selected_companion or not party_system:
		return
	
	# Limpar painel
	for child in behavior_panel.get_children():
		child.queue_free()
	
	var behavior_label = Label.new()
	behavior_label.text = "Behavior Settings:"
	behavior_panel.add_child(behavior_label)
	
	# Obter configurações atuais
	var behavior = party_system.get_companion_behavior(selected_companion)
	
	# Checkbox para agressivo
	var aggressive_check = CheckBox.new()
	aggressive_check.text = "Aggressive"
	aggressive_check.button_pressed = behavior.get("aggressive", false)
	aggressive_check.toggled.connect(func(pressed): _on_behavior_changed("aggressive", pressed))
	behavior_panel.add_child(aggressive_check)
	
	# Checkbox para usar itens
	var use_items_check = CheckBox.new()
	use_items_check.text = "Use Items"
	use_items_check.button_pressed = behavior.get("use_items", true)
	use_items_check.toggled.connect(func(pressed): _on_behavior_changed("use_items", pressed))
	behavior_panel.add_child(use_items_check)
	
	# Checkbox para fugir quando HP baixo
	var flee_check = CheckBox.new()
	flee_check.text = "Flee When Low HP"
	flee_check.button_pressed = behavior.get("flee_when_low_hp", true)
	flee_check.toggled.connect(func(pressed): _on_behavior_changed("flee_when_low_hp", pressed))
	behavior_panel.add_child(flee_check)

## Quando um companheiro é selecionado
func _on_companion_selected(index: int) -> void:
	if not companions_list:
		return
	
	var companion = companions_list.get_item_metadata(index) as Critter
	if companion:
		selected_companion = companion
		companion_selected.emit(companion)
		_refresh_selected_companion()

## Handler para mudança de comportamento
func _on_behavior_changed(setting: String, value: bool) -> void:
	if not selected_companion or not party_system:
		return
	
	var behavior = {setting: value}
	party_system.set_companion_behavior(selected_companion, behavior)
	behavior_changed.emit(selected_companion)

## Handler para gerenciar equipamento
func _on_manage_equipment_pressed() -> void:
	if not selected_companion:
		return
	
	# TODO: Abrir interface de inventário do companheiro
	# Por enquanto, apenas emitir sinal
	equipment_changed.emit(selected_companion)

## Configura a UI
func _setup_ui() -> void:
	if not companions_list:
		_create_basic_ui()

## Cria UI básica
func _create_basic_ui() -> void:
	var hbox = HBoxContainer.new()
	hbox.name = "ContentHBox"
	add_child(hbox)
	
	# Lista de companheiros
	var list_vbox = VBoxContainer.new()
	hbox.add_child(list_vbox)
	
	var list_label = Label.new()
	list_label.text = "Companions"
	list_label.add_theme_font_size_override("font_size", 18)
	list_vbox.add_child(list_label)
	
	companions_list = ItemList.new()
	companions_list.name = "CompanionsList"
	companions_list.item_selected.connect(_on_companion_selected)
	list_vbox.add_child(companions_list)
	
	# Painel de detalhes
	var details_vbox = VBoxContainer.new()
	hbox.add_child(details_vbox)
	
	var details_label = Label.new()
	details_label.text = "Companion Details"
	details_label.add_theme_font_size_override("font_size", 18)
	details_vbox.add_child(details_label)
	
	companion_details = VBoxContainer.new()
	companion_details.name = "CompanionDetails"
	details_vbox.add_child(companion_details)
	
	# Painel de equipamento
	equipment_panel = VBoxContainer.new()
	equipment_panel.name = "EquipmentPanel"
	details_vbox.add_child(equipment_panel)
	
	# Painel de comportamento
	behavior_panel = VBoxContainer.new()
	behavior_panel.name = "BehaviorPanel"
	details_vbox.add_child(behavior_panel)
