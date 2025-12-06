## ZoneSystem - Sistema de zoneamento
## Gerencia zonas de construção e restrições
class_name ZoneSystem
extends Node

# Enums para tipos de zona
enum ZoneType {
	RESIDENTIAL = 0,
	COMMERCIAL = 1,
	INDUSTRIAL = 2,
	AGRICULTURAL = 3,
	MILITARY = 4,
	RESTRICTED = 5
}

# Classe para dados de uma zona
class ZoneData:
	var id: int
	var zone_type: int = ZoneType.RESIDENTIAL
	var tiles: Array = []  # Vector2i positions
	var lots: Array = []  # Array of Lot
	var statistics: Dictionary = {}  # Estatísticas da zona
	
	class Lot:
		var id: int
		var position: Vector2i
		var size: Vector2i
		var is_occupied: bool = false
		var building_id: int = -1
		
		func _init(p_id: int, p_pos: Vector2i, p_size: Vector2i) -> void:
			id = p_id
			position = p_pos
			size = p_size
		
		func _to_string() -> String:
			return "Lot(id=%d, pos=%s, occupied=%s)" % [id, position, is_occupied]
	
	func _init(p_id: int, p_type: int = ZoneType.RESIDENTIAL) -> void:
		id = p_id
		zone_type = p_type
		statistics = {
			"population": 0,
			"buildings": 0,
			"happiness": 50.0,
			"development": 0.0
		}
	
	func _to_string() -> String:
		return "ZoneData(id=%d, type=%d, tiles=%d, lots=%d)" % [
			id, zone_type, tiles.size(), lots.size()
		]

# Armazenamento de zonas
var _zones: Dictionary = {}  # int (id) -> ZoneData
var _tile_to_zone: Dictionary = {}  # Vector2i -> int (zone id)
var _next_zone_id: int = 0
var _next_lot_id: int = 0

var grid_system
var config

func _ready() -> void:
	pass

func set_config(cfg) -> void:
	config = cfg
	if config == null:
		config = CityConfig.new()

func set_grid_system(grid) -> void:
	"""Define a referência ao GridSystem"""
	grid_system = grid

func create_zone(tiles: Array, zone_type: int = ZoneType.RESIDENTIAL) -> int:
	"""Cria uma zona com os tiles especificados"""
	if tiles.is_empty():
		return -1
	
	var zone = ZoneData.new(_next_zone_id, zone_type)
	_next_zone_id += 1
	
	# Adicionar tiles
	for tile_pos in tiles:
		zone.tiles.append(tile_pos)
		_tile_to_zone[tile_pos] = zone.id
	
	_zones[zone.id] = zone
	
	# Subdividir em lotes
	_subdivide_into_lots(zone)
	
	return zone.id

func _subdivide_into_lots(zone: ZoneData) -> void:
	"""Subdivide uma zona em lotes construíveis"""
	if zone.tiles.is_empty():
		return
	
	# Encontrar bounds da zona
	var min_x = zone.tiles[0].x
	var max_x = zone.tiles[0].x
	var min_y = zone.tiles[0].y
	var max_y = zone.tiles[0].y
	
	for tile in zone.tiles:
		min_x = min(min_x, tile.x)
		max_x = max(max_x, tile.x)
		min_y = min(min_y, tile.y)
		max_y = max(max_y, tile.y)
	
	# Tamanho padrão de lote
	var lot_size = Vector2i(5, 5)
	
	# Criar lotes
	var x = min_x
	while x < max_x:
		var y = min_y
		while y < max_y:
			var lot_pos = Vector2i(x, y)
			var lot_end = lot_pos + lot_size
			
			# Verificar se o lote está dentro da zona
			var lot_valid = true
			for check_x in range(lot_pos.x, min(lot_end.x, max_x + 1)):
				for check_y in range(lot_pos.y, min(lot_end.y, max_y + 1)):
					if not zone.tiles.has(Vector2i(check_x, check_y)):
						lot_valid = false
						break
				if not lot_valid:
					break
			
			if lot_valid:
				var lot = ZoneData.Lot.new(_next_lot_id, lot_pos, lot_size)
				_next_lot_id += 1
				zone.lots.append(lot)
			
			y += lot_size.y
		x += lot_size.x

func get_zone(zone_id: int) -> ZoneData:
	"""Obtém uma zona"""
	return _zones.get(zone_id)

func get_zone_at_tile(position: Vector2i) -> int:
	"""Obtém o ID da zona em um tile específico"""
	return _tile_to_zone.get(position, -1)

func is_zoned(position: Vector2i) -> bool:
	"""Verifica se um tile está em uma zona"""
	return _tile_to_zone.has(position)

func get_all_zones() -> Array:
	"""Retorna todas as zonas"""
	return _zones.values()

func get_zone_count() -> int:
	"""Retorna o número de zonas"""
	return _zones.size()

func get_zones_by_type(zone_type: int) -> Array:
	"""Retorna todas as zonas de um tipo específico"""
	var result: Array = []
	for zone in _zones.values():
		if zone.zone_type == zone_type:
			result.append(zone)
	return result

func destroy_zone(zone_id: int) -> bool:
	"""Remove uma zona"""
	if not _zones.has(zone_id):
		return false
	
	var zone = _zones[zone_id]
	
	# Remover tiles
	for tile_pos in zone.tiles:
		_tile_to_zone.erase(tile_pos)
	
	_zones.erase(zone_id)
	return true

func get_available_lot(zone_id: int) -> ZoneData.Lot:
	"""Obtém um lote disponível em uma zona"""
	if not _zones.has(zone_id):
		return null
	
	var zone = _zones[zone_id]
	for lot in zone.lots:
		if not lot.is_occupied:
			return lot
	
	return null

func occupy_lot(zone_id: int, lot_id: int, building_id: int) -> bool:
	"""Marca um lote como ocupado"""
	if not _zones.has(zone_id):
		return false
	
	var zone = _zones[zone_id]
	for lot in zone.lots:
		if lot.id == lot_id:
			lot.is_occupied = true
			lot.building_id = building_id
			zone.statistics["buildings"] += 1
			return true
	
	return false

func free_lot(zone_id: int, lot_id: int) -> bool:
	"""Marca um lote como livre"""
	if not _zones.has(zone_id):
		return false
	
	var zone = _zones[zone_id]
	for lot in zone.lots:
		if lot.id == lot_id:
			lot.is_occupied = false
			lot.building_id = -1
			zone.statistics["buildings"] -= 1
			return true
	
	return false

func get_zone_statistics(zone_id: int) -> Dictionary:
	"""Obtém estatísticas de uma zona"""
	if not _zones.has(zone_id):
		return {}
	
	return _zones[zone_id].statistics.duplicate()

func update_zone_statistics(zone_id: int, stats: Dictionary) -> void:
	"""Atualiza estatísticas de uma zona"""
	if not _zones.has(zone_id):
		return
	
	var zone = _zones[zone_id]
	for key in stats.keys():
		zone.statistics[key] = stats[key]

func can_build_in_zone(zone_id: int, building_type: int) -> bool:
	"""Verifica se um tipo de edifício pode ser construído em uma zona"""
	if not _zones.has(zone_id):
		return false
	
	var zone = _zones[zone_id]
	
	# Restrições por tipo de zona
	match zone.zone_type:
		ZoneType.RESIDENTIAL:
			# Apenas edifícios residenciais e utilidade
			return building_type in [
				0, 1, 2, 3,  # SMALL_HOUSE, MEDIUM_HOUSE, LARGE_HOUSE, APARTMENT
				20, 21, 22   # MEDICAL_CLINIC, SCHOOL, LIBRARY
			]
		ZoneType.COMMERCIAL:
			# Apenas edifícios comerciais e utilidade
			return building_type in [
				4, 5, 6, 7,  # SHOP, MARKET, RESTAURANT, BANK
				20, 21, 22   # MEDICAL_CLINIC, SCHOOL, LIBRARY
			]
		ZoneType.INDUSTRIAL:
			# Apenas edifícios industriais
			return building_type in [
				8, 9, 10, 11,  # FACTORY, WORKSHOP, WAREHOUSE, POWER_PLANT
				19             # WATER_PUMP
			]
		ZoneType.AGRICULTURAL:
			# Apenas edifícios agrícolas
			return building_type in [
				12, 13, 14  # FARM, GREENHOUSE, GRAIN_MILL
			]
		ZoneType.MILITARY:
			# Apenas edifícios militares
			return building_type in [
				15, 16, 17, 18  # GUARD_POST, BARRACKS, WATCHTOWER, ARMORY
			]
		ZoneType.RESTRICTED:
			# Nenhum edifício permitido
			return false
	
	return false

func get_occupied_lots_count(zone_id: int) -> int:
	"""Retorna o número de lotes ocupados em uma zona"""
	if not _zones.has(zone_id):
		return 0
	
	var zone = _zones[zone_id]
	var count = 0
	for lot in zone.lots:
		if lot.is_occupied:
			count += 1
	
	return count

func get_available_lots_count(zone_id: int) -> int:
	"""Retorna o número de lotes disponíveis em uma zona"""
	if not _zones.has(zone_id):
		return 0
	
	var zone = _zones[zone_id]
	var count = 0
	for lot in zone.lots:
		if not lot.is_occupied:
			count += 1
	
	return count
