## BuildingSystem - Sistema de edifícios
## Gerencia construção, destruição e upgrades de edifícios
class_name BuildingSystem
extends Node

# Enums para tipos de edifício
enum BuildingType {
	# Residencial
	SMALL_HOUSE = 0,
	MEDIUM_HOUSE = 1,
	LARGE_HOUSE = 2,
	APARTMENT = 3,
	
	# Comercial
	SHOP = 4,
	MARKET = 5,
	RESTAURANT = 6,
	BANK = 7,
	
	# Industrial
	FACTORY = 8,
	WORKSHOP = 9,
	WAREHOUSE = 10,
	POWER_PLANT = 11,
	
	# Agrícola
	FARM = 12,
	GREENHOUSE = 13,
	GRAIN_MILL = 14,
	
	# Militar
	GUARD_POST = 15,
	BARRACKS = 16,
	WATCHTOWER = 17,
	ARMORY = 18,
	
	# Utilidade
	WATER_PUMP = 19,
	MEDICAL_CLINIC = 20,
	SCHOOL = 21,
	LIBRARY = 22,
	
	# Especial
	VAULT = 23,
	SETTLEMENT_CENTER = 24
}

# Classe para dados de um edifício
class BuildingData:
	var id: int
	var building_type: int = BuildingType.SMALL_HOUSE
	var position: Vector2i
	var size: Vector2i
	var tiles: Array = []  # Vector2i positions
	var level: int = 1
	var condition: float = 100.0  # 0-100
	var is_operational: bool = true
	var owner_id: int = -1  # Citizen ID or faction ID
	var construction_progress: float = 0.0  # 0-100
	var is_under_construction: bool = false
	var metadata: Dictionary = {}
	
	func _init(p_id: int, p_type: int, p_pos: Vector2i, p_size: Vector2i) -> void:
		id = p_id
		building_type = p_type
		position = p_pos
		size = p_size
	
	func _to_string() -> String:
		return "BuildingData(id=%d, type=%d, pos=%s, level=%d, condition=%.1f)" % [
			id, building_type, position, level, condition
		]

# Armazenamento de edifícios
var _buildings: Dictionary = {}  # int (id) -> BuildingData
var _tile_to_building: Dictionary = {}  # Vector2i -> int (building id)
var _next_building_id: int = 0

var grid_system
var zone_system
var config
var event_bus

func _ready() -> void:
	pass

func set_config(cfg) -> void:
	config = cfg
	if config == null:
		config = CityConfig.new()

func set_systems(grid, zone, bus) -> void:
	"""Define as referências aos sistemas"""
	grid_system = grid
	zone_system = zone
	event_bus = bus

func construct_building(building_type: int, position: Vector2i, size: Vector2i, 
						zone_id: int = -1) -> int:
	"""Constrói um novo edifício"""
	if grid_system == null:
		return -1
	
	# Verificar se o espaço está disponível
	if not _is_space_available(position, size):
		return -1
	
	# Verificar restrições de zona
	if zone_id >= 0 and zone_system != null:
		if not zone_system.can_build_in_zone(zone_id, building_type):
			return -1
	
	var building = BuildingData.new(_next_building_id, building_type, position, size)
	_next_building_id += 1
	
	# Gerar tiles do edifício
	for x in range(position.x, position.x + size.x):
		for y in range(position.y, position.y + size.y):
			var tile_pos = Vector2i(x, y)
			if grid_system._is_valid_position(tile_pos):
				building.tiles.append(tile_pos)
				_tile_to_building[tile_pos] = building.id
	
	building.is_under_construction = true
	building.construction_progress = 0.0
	
	_buildings[building.id] = building
	
	# Emitir evento
	if event_bus != null:
		event_bus.building_constructed.emit(building.id, position)
	
	return building.id

func _is_space_available(position: Vector2i, size: Vector2i) -> bool:
	"""Verifica se o espaço está disponível para construção"""
	if grid_system == null:
		return false
	
	for x in range(position.x, position.x + size.x):
		for y in range(position.y, position.y + size.y):
			var tile_pos = Vector2i(x, y)
			
			# Verificar se o tile é válido e caminhável
			if not grid_system._is_valid_position(tile_pos):
				return false
			if not grid_system.is_walkable(tile_pos):
				return false
			# Verificar se já há um edifício
			if _tile_to_building.has(tile_pos):
				return false
	
	return true

func complete_construction(building_id: int) -> bool:
	"""Completa a construção de um edifício"""
	if not _buildings.has(building_id):
		return false
	
	var building = _buildings[building_id]
	building.is_under_construction = false
	building.construction_progress = 100.0
	building.is_operational = true
	
	return true

func upgrade_building(building_id: int) -> bool:
	"""Faz upgrade de um edifício"""
	if not _buildings.has(building_id):
		return false
	
	var building = _buildings[building_id]
	
	# Verificar se o edifício está operacional
	if not building.is_operational:
		return false
	
	# Verificar se já está no nível máximo
	if building.level >= 5:
		return false
	
	building.level += 1
	building.condition = 100.0
	building.is_operational = true
	
	if event_bus != null:
		event_bus.building_upgraded.emit(building_id, building.level)
	
	return true

func repair_building(building_id: int, amount: float = 50.0) -> bool:
	"""Repara um edifício"""
	if not _buildings.has(building_id):
		return false
	
	var building = _buildings[building_id]
	building.condition = min(100.0, building.condition + amount)
	
	return true

func damage_building(building_id: int, amount: float = 10.0) -> bool:
	"""Danifica um edifício"""
	if not _buildings.has(building_id):
		return false
	
	var building = _buildings[building_id]
	building.condition = max(0.0, building.condition - amount)
	
	if building.condition <= 0.0:
		building.is_operational = false
	
	return true

func destroy_building(building_id: int) -> bool:
	"""Remove um edifício e desloca seus ocupantes"""
	if not _buildings.has(building_id):
		return false
	
	var building = _buildings[building_id]
	
	# Remover tiles
	for tile_pos in building.tiles:
		_tile_to_building.erase(tile_pos)
	
	_buildings.erase(building_id)
	
	if event_bus != null:
		event_bus.building_destroyed.emit(building_id)
	
	return true

func displace_occupants(building_id: int) -> Array:
	"""Desloca ocupantes de um edifício e retorna seus IDs"""
	if not _buildings.has(building_id):
		return []
	
	var displaced: Array = []
	var building = _buildings[building_id]
	
	# Coletar IDs dos ocupantes
	if building.metadata.has("occupants"):
		displaced = building.metadata["occupants"].duplicate()
		building.metadata["occupants"] = []
	
	return displaced

func add_occupant(building_id: int, citizen_id: int) -> bool:
	"""Adiciona um ocupante a um edifício"""
	if not _buildings.has(building_id):
		return false
	
	var building = _buildings[building_id]
	
	if not building.metadata.has("occupants"):
		building.metadata["occupants"] = []
	
	if citizen_id not in building.metadata["occupants"]:
		building.metadata["occupants"].append(citizen_id)
	
	return true

func remove_occupant(building_id: int, citizen_id: int) -> bool:
	"""Remove um ocupante de um edifício"""
	if not _buildings.has(building_id):
		return false
	
	var building = _buildings[building_id]
	
	if building.metadata.has("occupants"):
		building.metadata["occupants"].erase(citizen_id)
	
	return true

func get_occupants(building_id: int) -> Array:
	"""Retorna os ocupantes de um edifício"""
	if not _buildings.has(building_id):
		return []
	
	var building = _buildings[building_id]
	
	if building.metadata.has("occupants"):
		return building.metadata["occupants"].duplicate()
	
	return []

func get_occupant_count(building_id: int) -> int:
	"""Retorna o número de ocupantes de um edifício"""
	if not _buildings.has(building_id):
		return 0
	
	var building = _buildings[building_id]
	
	if building.metadata.has("occupants"):
		return building.metadata["occupants"].size()
	
	return 0

func get_building(building_id: int) -> BuildingData:
	"""Obtém um edifício"""
	return _buildings.get(building_id)

func get_building_at_tile(position: Vector2i) -> int:
	"""Obtém o ID do edifício em um tile específico"""
	return _tile_to_building.get(position, -1)

func is_building_tile(position: Vector2i) -> bool:
	"""Verifica se um tile é parte de um edifício"""
	return _tile_to_building.has(position)

func get_all_buildings() -> Array:
	"""Retorna todos os edifícios"""
	return _buildings.values()

func get_building_count() -> int:
	"""Retorna o número de edifícios"""
	return _buildings.size()

func get_buildings_by_type(building_type: int) -> Array:
	"""Retorna todos os edifícios de um tipo específico"""
	var result: Array = []
	for building in _buildings.values():
		if building.building_type == building_type:
			result.append(building)
	return result

func get_buildings_in_area(area: Rect2i) -> Array:
	"""Retorna todos os edifícios em uma área"""
	var result: Array = []
	for building in _buildings.values():
		var building_rect = Rect2i(building.position, building.size)
		if building_rect.intersects(area):
			result.append(building)
	return result

func set_building_operational(building_id: int, operational: bool) -> bool:
	"""Define se um edifício está operacional"""
	if not _buildings.has(building_id):
		return false
	
	_buildings[building_id].is_operational = operational
	return true

func get_building_statistics() -> Dictionary:
	"""Retorna estatísticas dos edifícios"""
	var stats = {
		"total_buildings": _buildings.size(),
		"operational": 0,
		"under_construction": 0,
		"damaged": 0,
		"by_type": {}
	}
	
	for building in _buildings.values():
		if building.is_operational:
			stats["operational"] += 1
		if building.is_under_construction:
			stats["under_construction"] += 1
		if building.condition < 50.0:
			stats["damaged"] += 1
		
		var type_name = BuildingType.keys()[building.building_type]
		if not stats["by_type"].has(type_name):
			stats["by_type"][type_name] = 0
		stats["by_type"][type_name] += 1
	
	return stats

func can_house(building_id: int) -> bool:
	"""Verifica se um edifício pode hospedar cidadãos"""
	if not _buildings.has(building_id):
		return false
	
	var building = _buildings[building_id]
	
	# Apenas edifícios residenciais podem hospedar
	match building.building_type:
		BuildingType.SMALL_HOUSE, BuildingType.MEDIUM_HOUSE, BuildingType.LARGE_HOUSE, BuildingType.APARTMENT:
			return true
		_:
			return false

func can_employ(building_id: int) -> bool:
	"""Verifica se um edifício pode empregar cidadãos"""
	if not _buildings.has(building_id):
		return false
	
	var building = _buildings[building_id]
	
	# Edifícios que podem empregar
	if building.building_type in [
		BuildingType.SHOP, BuildingType.MARKET, BuildingType.RESTAURANT, BuildingType.BANK,
		BuildingType.FACTORY, BuildingType.WORKSHOP, BuildingType.WAREHOUSE, BuildingType.POWER_PLANT,
		BuildingType.FARM, BuildingType.GREENHOUSE, BuildingType.GRAIN_MILL,
		BuildingType.GUARD_POST, BuildingType.BARRACKS, BuildingType.WATCHTOWER, BuildingType.ARMORY,
		BuildingType.WATER_PUMP, BuildingType.MEDICAL_CLINIC, BuildingType.SCHOOL, BuildingType.LIBRARY,
		BuildingType.SETTLEMENT_CENTER
	]:
		return true
	return false

func get_housing_capacity(building_id: int) -> int:
	"""Retorna a capacidade de moradia de um edifício"""
	if not _buildings.has(building_id):
		return 0
	
	var building = _buildings[building_id]
	
	match building.building_type:
		BuildingType.SMALL_HOUSE:
			return 2
		BuildingType.MEDIUM_HOUSE:
			return 4
		BuildingType.LARGE_HOUSE:
			return 6
		BuildingType.APARTMENT:
			return 8
		_:
			return 0

func get_employment_capacity(building_id: int) -> int:
	"""Retorna a capacidade de emprego de um edifício"""
	if not _buildings.has(building_id):
		return 0
	
	var building = _buildings[building_id]
	
	match building.building_type:
		BuildingType.SHOP:
			return 2
		BuildingType.MARKET:
			return 4
		BuildingType.RESTAURANT:
			return 3
		BuildingType.BANK:
			return 3
		BuildingType.FACTORY:
			return 8
		BuildingType.WORKSHOP:
			return 4
		BuildingType.WAREHOUSE:
			return 3
		BuildingType.POWER_PLANT:
			return 5
		BuildingType.FARM:
			return 4
		BuildingType.GREENHOUSE:
			return 3
		BuildingType.GRAIN_MILL:
			return 3
		BuildingType.GUARD_POST:
			return 4
		BuildingType.BARRACKS:
			return 6
		BuildingType.WATCHTOWER:
			return 2
		BuildingType.ARMORY:
			return 2
		BuildingType.WATER_PUMP:
			return 2
		BuildingType.MEDICAL_CLINIC:
			return 3
		BuildingType.SCHOOL:
			return 4
		BuildingType.LIBRARY:
			return 2
		BuildingType.SETTLEMENT_CENTER:
			return 5
		_:
			return 0

func add_resident(building_id: int, citizen_id: int) -> bool:
	"""Adiciona um residente a um edifício"""
	if not _buildings.has(building_id):
		return false
	
	var building = _buildings[building_id]
	
	# Verificar capacidade
	var capacity = get_housing_capacity(building_id)
	var current_residents = get_residents(building_id).size()
	
	if current_residents >= capacity:
		return false
	
	if not building.metadata.has("residents"):
		building.metadata["residents"] = []
	
	if citizen_id not in building.metadata["residents"]:
		building.metadata["residents"].append(citizen_id)
	
	return true

func remove_resident(building_id: int, citizen_id: int) -> bool:
	"""Remove um residente de um edifício"""
	if not _buildings.has(building_id):
		return false
	
	var building = _buildings[building_id]
	
	if building.metadata.has("residents"):
		building.metadata["residents"].erase(citizen_id)
	
	return true

func get_residents(building_id: int) -> Array:
	"""Retorna os residentes de um edifício"""
	if not _buildings.has(building_id):
		return []
	
	var building = _buildings[building_id]
	
	if building.metadata.has("residents"):
		return building.metadata["residents"].duplicate()
	
	return []

func get_resident_count(building_id: int) -> int:
	"""Retorna o número de residentes de um edifício"""
	if not _buildings.has(building_id):
		return 0
	
	var building = _buildings[building_id]
	
	if building.metadata.has("residents"):
		return building.metadata["residents"].size()
	
	return 0

func add_employee(building_id: int, citizen_id: int) -> bool:
	"""Adiciona um funcionário a um edifício"""
	if not _buildings.has(building_id):
		return false
	
	var building = _buildings[building_id]
	
	# Verificar capacidade
	var capacity = get_employment_capacity(building_id)
	var current_employees = get_employees(building_id).size()
	
	if current_employees >= capacity:
		return false
	
	if not building.metadata.has("employees"):
		building.metadata["employees"] = []
	
	if citizen_id not in building.metadata["employees"]:
		building.metadata["employees"].append(citizen_id)
	
	return true

func remove_employee(building_id: int, citizen_id: int) -> bool:
	"""Remove um funcionário de um edifício"""
	if not _buildings.has(building_id):
		return false
	
	var building = _buildings[building_id]
	
	if building.metadata.has("employees"):
		building.metadata["employees"].erase(citizen_id)
	
	return true

func get_employees(building_id: int) -> Array:
	"""Retorna os funcionários de um edifício"""
	if not _buildings.has(building_id):
		return []
	
	var building = _buildings[building_id]
	
	if building.metadata.has("employees"):
		return building.metadata["employees"].duplicate()
	
	return []

func get_employee_count(building_id: int) -> int:
	"""Retorna o número de funcionários de um edifício"""
	if not _buildings.has(building_id):
		return 0
	
	var building = _buildings[building_id]
	
	if building.metadata.has("employees"):
		return building.metadata["employees"].size()
	
	return 0
