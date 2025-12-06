## FactionSystem - Sistema de facções
## Gerencia facções, território e relações
class_name FactionSystem
extends Node

# Enums para tipos de relação
enum RelationType {
	HOSTILE = -2,
	UNFRIENDLY = -1,
	NEUTRAL = 0,
	FRIENDLY = 1,
	ALLIED = 2
}

# Classe para dados de uma facção
class FactionData:
	var id: int
	var name: String
	var color: Color
	var territory: Array = []  # Array de Vector2i
	var reputation: Dictionary = {}  # citizen_id -> reputation (-100 to 100)
	var relations: Dictionary = {}  # faction_id -> RelationType
	var resources: Dictionary = {}  # resource_type -> amount
	var is_player_faction: bool = false
	var leader_id: int = -1
	var members: Array = []  # Array de citizen_id
	
	func _init(p_id: int, p_name: String, p_color: Color = Color.WHITE) -> void:
		id = p_id
		name = p_name
		color = p_color
	
	func _to_string() -> String:
		return "FactionData(id=%d, name=%s, territory=%d, members=%d)" % [
			id, name, territory.size(), members.size()
		]

# Armazenamento de facções
var _factions: Dictionary = {}  # int (id) -> FactionData
var _tile_to_faction: Dictionary = {}  # Vector2i -> int (faction id)
var _next_faction_id: int = 0

var grid_system
var config
var event_bus

func _ready() -> void:
	pass

func set_config(cfg) -> void:
	config = cfg
	if config == null:
		config = CityConfig.new()

func set_systems(grid, bus) -> void:
	"""Define as referências aos sistemas"""
	grid_system = grid
	event_bus = bus

func create_faction(name: String, color: Color = Color.WHITE, is_player: bool = false) -> int:
	"""Cria uma nova facção"""
	var faction = FactionData.new(_next_faction_id, name, color)
	faction.is_player_faction = is_player
	_next_faction_id += 1
	
	_factions[faction.id] = faction
	
	return faction.id

func get_faction(faction_id: int) -> FactionData:
	"""Obtém uma facção"""
	return _factions.get(faction_id)

func get_all_factions() -> Array:
	"""Retorna todas as facções"""
	return _factions.values()

func get_faction_count() -> int:
	"""Retorna o número de facções"""
	return _factions.size()

func claim_territory(faction_id: int, tiles: Array) -> bool:
	"""Reclama território para uma facção"""
	if not _factions.has(faction_id):
		return false
	
	var faction = _factions[faction_id]
	
	# Verificar se algum tile já é de outra facção
	for tile in tiles:
		if _tile_to_faction.has(tile) and _tile_to_faction[tile] != faction_id:
			return false
	
	# Reivindicar tiles
	for tile in tiles:
		if not faction.territory.has(tile):
			faction.territory.append(tile)
		_tile_to_faction[tile] = faction_id
	
	if event_bus != null:
		event_bus.faction_territory_claimed.emit(faction_id, tiles)
	
	return true

func release_territory(faction_id: int, tiles: Array) -> bool:
	"""Libera território de uma facção"""
	if not _factions.has(faction_id):
		return false
	
	var faction = _factions[faction_id]
	
	for tile in tiles:
		faction.territory.erase(tile)
		_tile_to_faction.erase(tile)
	
	if event_bus != null:
		event_bus.faction_territory_lost.emit(faction_id, tiles)
	
	return true

func get_faction_at(position: Vector2i) -> int:
	"""Obtém a facção que controla um tile"""
	return _tile_to_faction.get(position, -1)

func get_faction_territory(faction_id: int) -> Array:
	"""Obtém o território de uma facção"""
	if not _factions.has(faction_id):
		return []
	
	return _factions[faction_id].territory.duplicate()

func get_territory_size(faction_id: int) -> int:
	"""Obtém o tamanho do território de uma facção"""
	if not _factions.has(faction_id):
		return 0
	
	return _factions[faction_id].territory.size()

func set_faction_relation(faction_a: int, faction_b: int, relation: int) -> bool:
	"""Define a relação entre duas facções"""
	if not _factions.has(faction_a) or not _factions.has(faction_b):
		return false
	
	var faction = _factions[faction_a]
	faction.relations[faction_b] = clamp(relation, RelationType.HOSTILE, RelationType.ALLIED)
	
	if event_bus != null:
		event_bus.faction_relation_changed.emit(faction_a, faction_b, faction.relations[faction_b])
	
	return true

func get_faction_relation(faction_a: int, faction_b: int) -> int:
	"""Obtém a relação entre duas facções"""
	if not _factions.has(faction_a):
		return RelationType.NEUTRAL
	
	var faction = _factions[faction_a]
	return faction.relations.get(faction_b, RelationType.NEUTRAL)

func modify_faction_relation(faction_a: int, faction_b: int, amount: int) -> bool:
	"""Modifica a relação entre duas facções"""
	if not _factions.has(faction_a) or not _factions.has(faction_b):
		return false
	
	var current_relation = get_faction_relation(faction_a, faction_b)
	var new_relation = clamp(current_relation + amount, RelationType.HOSTILE, RelationType.ALLIED)
	
	return set_faction_relation(faction_a, faction_b, new_relation)

func add_faction_member(faction_id: int, citizen_id: int) -> bool:
	"""Adiciona um membro a uma facção"""
	if not _factions.has(faction_id):
		return false
	
	var faction = _factions[faction_id]
	
	if citizen_id not in faction.members:
		faction.members.append(citizen_id)
	
	return true

func remove_faction_member(faction_id: int, citizen_id: int) -> bool:
	"""Remove um membro de uma facção"""
	if not _factions.has(faction_id):
		return false
	
	var faction = _factions[faction_id]
	faction.members.erase(citizen_id)
	
	return true

func get_faction_members(faction_id: int) -> Array:
	"""Obtém os membros de uma facção"""
	if not _factions.has(faction_id):
		return []
	
	return _factions[faction_id].members.duplicate()

func get_faction_member_count(faction_id: int) -> int:
	"""Obtém o número de membros de uma facção"""
	if not _factions.has(faction_id):
		return 0
	
	return _factions[faction_id].members.size()

func set_player_reputation(faction_id: int, amount: int) -> bool:
	"""Define a reputação do jogador com uma facção"""
	if not _factions.has(faction_id):
		return false
	
	var faction = _factions[faction_id]
	faction.reputation[-1] = clamp(amount, -100, 100)  # -1 = player
	
	return true

func get_player_reputation(faction_id: int) -> int:
	"""Obtém a reputação do jogador com uma facção"""
	if not _factions.has(faction_id):
		return 0
	
	var faction = _factions[faction_id]
	return faction.reputation.get(-1, 0)

func modify_player_reputation(faction_id: int, amount: int) -> bool:
	"""Modifica a reputação do jogador com uma facção"""
	if not _factions.has(faction_id):
		return false
	
	var current_rep = get_player_reputation(faction_id)
	var new_rep = clamp(current_rep + amount, -100, 100)
	
	return set_player_reputation(faction_id, new_rep)

func set_citizen_reputation(faction_id: int, citizen_id: int, amount: int) -> bool:
	"""Define a reputação de um cidadão com uma facção"""
	if not _factions.has(faction_id):
		return false
	
	var faction = _factions[faction_id]
	faction.reputation[citizen_id] = clamp(amount, -100, 100)
	
	return true

func get_citizen_reputation(faction_id: int, citizen_id: int) -> int:
	"""Obtém a reputação de um cidadão com uma facção"""
	if not _factions.has(faction_id):
		return 0
	
	var faction = _factions[faction_id]
	return faction.reputation.get(citizen_id, 0)

func modify_citizen_reputation(faction_id: int, citizen_id: int, amount: int) -> bool:
	"""Modifica a reputação de um cidadão com uma facção"""
	if not _factions.has(faction_id):
		return false
	
	var current_rep = get_citizen_reputation(faction_id, citizen_id)
	var new_rep = clamp(current_rep + amount, -100, 100)
	
	return set_citizen_reputation(faction_id, citizen_id, new_rep)

func check_territorial_dispute(faction_a: int, faction_b: int) -> bool:
	"""Verifica se há disputa territorial entre duas facções"""
	if not _factions.has(faction_a) or not _factions.has(faction_b):
		return false
	
	var faction_a_data = _factions[faction_a]
	var faction_b_data = _factions[faction_b]
	
	# Verificar se há tiles adjacentes de facções diferentes
	for tile_a in faction_a_data.territory:
		var neighbors = _get_tile_neighbors(tile_a)
		for neighbor in neighbors:
			if _tile_to_faction.get(neighbor, -1) == faction_b:
				return true
	
	return false

func _get_tile_neighbors(tile: Vector2i) -> Array:
	"""Obtém os vizinhos de um tile"""
	var neighbors: Array = []
	
	for x in range(-1, 2):
		for y in range(-1, 2):
			if x == 0 and y == 0:
				continue
			neighbors.append(tile + Vector2i(x, y))
	
	return neighbors

func get_faction_statistics() -> Dictionary:
	"""Retorna estatísticas das facções"""
	var stats = {
		"total_factions": _factions.size(),
		"factions": {}
	}
	
	for faction in _factions.values():
		stats["factions"][faction.name] = {
			"id": faction.id,
			"territory_size": faction.territory.size(),
			"members": faction.members.size(),
			"player_reputation": faction.reputation.get(-1, 0),
			"is_player_faction": faction.is_player_faction
		}
	
	return stats

func trigger_territorial_conflict(faction_a: int, faction_b: int) -> bool:
	"""Dispara um conflito territorial entre duas facções"""
	if not check_territorial_dispute(faction_a, faction_b):
		return false
	
	# Modificar relações
	modify_faction_relation(faction_a, faction_b, -1)
	modify_faction_relation(faction_b, faction_a, -1)
	
	if event_bus != null:
		event_bus.faction_conflict_started.emit(faction_a, faction_b)
	
	return true
