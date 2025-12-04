extends Node

## Sistema de Inventario do Fallout 2
## Baseado no codigo original (src/inventory.cc)

signal item_added(item: Dictionary)
signal item_removed(item: Dictionary)
signal item_equipped(item: Dictionary, slot: String)
signal item_unequipped(item: Dictionary, slot: String)
signal inventory_changed()

# Slots de equipamento (igual ao original)
enum EquipSlot { ARMOR, LEFT_HAND, RIGHT_HAND }

# Tipos de item
enum ItemType { WEAPON, ARMOR, AMMO, DRUG, MISC, KEY, CONTAINER }

# Inventario do player
var items: Array[Dictionary] = []
var equipped: Dictionary = {
	"armor": null,
	"left_hand": null,
	"right_hand": null
}

# Peso atual e maximo
var current_weight: int = 0
var max_weight: int = 150  # Sera atualizado baseado em Strength

# Referencia ao player
var player: Node = null

func _ready():
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.player_spawned.connect(_on_player_spawned)

func _on_player_spawned(p: Node):
	player = p
	if player.has_method("get"):
		# Carry Weight = 25 + (Strength * 25)
		max_weight = 25 + (player.strength * 25)

# === GERENCIAMENTO DE ITENS ===

func add_item(item: Dictionary, quantity: int = 1) -> bool:
	"""Adiciona item ao inventario"""
	# Verificar peso
	var item_weight = item.get("weight", 0) * quantity
	if current_weight + item_weight > max_weight:
		print("InventorySystem: Peso excedido!")
		return false
	
	# Verificar se item ja existe (stackable)
	if item.get("stackable", false):
		for existing in items:
			if existing.get("id") == item.get("id"):
				existing["quantity"] = existing.get("quantity", 1) + quantity
				current_weight += item_weight
				inventory_changed.emit()
				item_added.emit(item)
				return true
	
	# Adicionar novo item
	var new_item = item.duplicate()
	new_item["quantity"] = quantity
	items.append(new_item)
	current_weight += item_weight
	
	inventory_changed.emit()
	item_added.emit(new_item)
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	"""Remove item do inventario"""
	for i in range(items.size()):
		if items[i].get("id") == item_id:
			var item = items[i]
			var current_qty = item.get("quantity", 1)
			
			if current_qty <= quantity:
				# Remover completamente
				current_weight -= item.get("weight", 0) * current_qty
				items.remove_at(i)
				item_removed.emit(item)
			else:
				# Reduzir quantidade
				item["quantity"] = current_qty - quantity
				current_weight -= item.get("weight", 0) * quantity
			
			inventory_changed.emit()
			return true
	
	return false

func has_item(item_id: String, quantity: int = 1) -> bool:
	"""Verifica se tem item no inventario"""
	for item in items:
		if item.get("id") == item_id:
			return item.get("quantity", 1) >= quantity
	return false

func get_item(item_id: String) -> Dictionary:
	"""Retorna item do inventario"""
	for item in items:
		if item.get("id") == item_id:
			return item
	return {}

func get_item_count(item_id: String) -> int:
	"""Retorna quantidade de um item"""
	for item in items:
		if item.get("id") == item_id:
			return item.get("quantity", 1)
	return 0

# === EQUIPAMENTO ===

func equip_item(item_id: String, slot: String) -> bool:
	"""Equipa item em um slot"""
	var item = get_item(item_id)
	if item.is_empty():
		return false
	
	# Verificar se item pode ser equipado no slot
	var item_type = item.get("type", ItemType.MISC)
	
	match slot:
		"armor":
			if item_type != ItemType.ARMOR:
				return false
		"left_hand", "right_hand":
			if item_type != ItemType.WEAPON and item_type != ItemType.MISC:
				return false
	
	# Desequipar item atual se houver
	if equipped[slot] != null:
		unequip_item(slot)
	
	# Equipar novo item
	equipped[slot] = item
	item_equipped.emit(item, slot)
	inventory_changed.emit()
	
	# Aplicar bonus se for armadura
	if slot == "armor" and player:
		var ac_bonus = item.get("armor_class", 0)
		if player.has_method("get"):
			player.armor_class += ac_bonus
	
	return true

func unequip_item(slot: String) -> bool:
	"""Desequipa item de um slot"""
	if equipped[slot] == null:
		return false
	
	var item = equipped[slot]
	
	# Remover bonus se for armadura
	if slot == "armor" and player:
		var ac_bonus = item.get("armor_class", 0)
		if player.has_method("get"):
			player.armor_class -= ac_bonus
	
	equipped[slot] = null
	item_unequipped.emit(item, slot)
	inventory_changed.emit()
	return true

func get_equipped(slot: String) -> Dictionary:
	"""Retorna item equipado em um slot"""
	return equipped.get(slot, {})

func get_active_weapon() -> Dictionary:
	"""Retorna arma ativa (mao direita ou esquerda)"""
	if equipped["right_hand"] != null:
		return equipped["right_hand"]
	if equipped["left_hand"] != null:
		return equipped["left_hand"]
	return {}

# === USO DE ITENS ===

func use_item(item_id: String) -> bool:
	"""Usa um item consumivel"""
	var item = get_item(item_id)
	if item.is_empty():
		return false
	
	var item_type = item.get("type", ItemType.MISC)
	
	match item_type:
		ItemType.DRUG:
			return _use_drug(item)
		ItemType.MISC:
			return _use_misc(item)
		_:
			print("InventorySystem: Item nao pode ser usado")
			return false

func _use_drug(item: Dictionary) -> bool:
	"""Usa um item de droga/medicina"""
	if not player:
		return false
	
	# Aplicar efeitos
	var hp_restore = item.get("hp_restore", 0)
	if hp_restore > 0 and player.has_method("heal"):
		player.heal(hp_restore)
	
	# Remover item
	remove_item(item.get("id", ""), 1)
	return true

func _use_misc(item: Dictionary) -> bool:
	"""Usa item miscelaneo"""
	# Verificar se tem script de uso
	var use_script = item.get("use_script", "")
	if use_script.is_empty():
		return false
	
	# TODO: Executar script
	return true

# === CONTAINERS ===

func transfer_to_container(item_id: String, container: Node, quantity: int = 1) -> bool:
	"""Transfere item para container"""
	if not has_item(item_id, quantity):
		return false
	
	var item = get_item(item_id)
	if container.has_method("add_item"):
		if container.add_item(item, quantity):
			remove_item(item_id, quantity)
			return true
	
	return false

func transfer_from_container(container: Node, item_id: String, quantity: int = 1) -> bool:
	"""Transfere item de container"""
	if container.has_method("get_item") and container.has_method("remove_item"):
		var item = container.get_item(item_id)
		if not item.is_empty():
			if add_item(item, quantity):
				container.remove_item(item_id, quantity)
				return true
	
	return false

# === UTILIDADES ===

func get_all_items() -> Array[Dictionary]:
	"""Retorna todos os itens"""
	return items

func get_items_by_type(type: ItemType) -> Array[Dictionary]:
	"""Retorna itens de um tipo especifico"""
	var result: Array[Dictionary] = []
	for item in items:
		if item.get("type", ItemType.MISC) == type:
			result.append(item)
	return result

func get_weight_info() -> Dictionary:
	"""Retorna informacoes de peso"""
	return {
		"current": current_weight,
		"max": max_weight,
		"percent": float(current_weight) / float(max_weight) * 100.0
	}

func clear_inventory():
	"""Limpa inventario"""
	items.clear()
	equipped = {"armor": null, "left_hand": null, "right_hand": null}
	current_weight = 0
	inventory_changed.emit()

# === CRIACAO DE ITENS (para testes) ===

func create_item(id: String, name: String, type: ItemType, weight: int = 1) -> Dictionary:
	"""Cria um item basico"""
	return {
		"id": id,
		"name": name,
		"type": type,
		"weight": weight,
		"stackable": type == ItemType.AMMO or type == ItemType.DRUG,
		"quantity": 1
	}

func create_weapon(id: String, name: String, damage_min: int, damage_max: int, ap_cost: int = 3) -> Dictionary:
	"""Cria uma arma"""
	return {
		"id": id,
		"name": name,
		"type": ItemType.WEAPON,
		"weight": 3,
		"damage_min": damage_min,
		"damage_max": damage_max,
		"ap_cost": ap_cost,
		"stackable": false
	}

func create_armor(id: String, name: String, armor_class: int, dr: int = 0) -> Dictionary:
	"""Cria uma armadura"""
	return {
		"id": id,
		"name": name,
		"type": ItemType.ARMOR,
		"weight": 10,
		"armor_class": armor_class,
		"damage_resistance": dr,
		"stackable": false
	}
