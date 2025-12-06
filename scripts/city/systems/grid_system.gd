## GridSystem - Sistema de grid e terreno da cidade
## Gerencia tiles, terreno, elevação e walkability
class_name GridSystem
extends Node

# Enums para tipos de terreno
enum TerrainType {
	GRASS = 0,
	DIRT = 1,
	CONCRETE = 2,
	WATER = 3,
	ROCK = 4,
	SAND = 5,
	ASPHALT = 6,
	METAL = 7,
	RADIOACTIVE = 8
}

# Classe para dados de um tile
class CityTileData:
	var terrain_type: int = TerrainType.GRASS
	var elevation: float = 0.0
	var walkable: bool = true
	var radiation_level: float = 0.0
	
	func _init(p_terrain: int = TerrainType.GRASS, p_elevation: float = 0.0, 
			   p_walkable: bool = true, p_radiation: float = 0.0) -> void:
		terrain_type = p_terrain
		elevation = p_elevation
		walkable = p_walkable
		radiation_level = p_radiation
	
	func _to_string() -> String:
		return "CityTileData(terrain=%d, elev=%.1f, walk=%s, rad=%.1f)" % [
			terrain_type, elevation, walkable, radiation_level
		]

# Armazenamento do grid
var _tiles: Dictionary = {}  # Vector2i -> CityTileData
var _grid_width: int = 100
var _grid_height: int = 100
var config

func _ready() -> void:
	_initialize_grid()

func set_config(cfg) -> void:
	config = cfg

func _initialize_grid() -> void:
	"""Inicializa o grid com tiles padrão"""
	_tiles.clear()
	for x in range(_grid_width):
		for y in range(_grid_height):
			var pos = Vector2i(x, y)
			_tiles[pos] = CityTileData.new()

func set_grid_size(width: int, height: int) -> void:
	"""Define o tamanho do grid (50x50 a 500x500)"""
	width = clampi(width, 50, 500)
	height = clampi(height, 50, 500)
	_grid_width = width
	_grid_height = height
	_initialize_grid()

func get_grid_size() -> Vector2i:
	"""Retorna o tamanho do grid"""
	return Vector2i(_grid_width, _grid_height)

func get_tile(position: Vector2i):
	"""Obtém dados de um tile"""
	if not _is_valid_position(position):
		return null
	return _tiles.get(position)

func set_tile(position: Vector2i, tile_data) -> bool:
	"""Define dados de um tile"""
	if not _is_valid_position(position):
		return false
	_tiles[position] = tile_data
	return true

func is_walkable(position: Vector2i) -> bool:
	"""Verifica se um tile é caminhável"""
	var tile = get_tile(position)
	return tile != null and tile.walkable

func get_tiles_in_area(area: Rect2i) -> Array:
	"""Retorna todos os tiles em uma área"""
	var result: Array = []
	for x in range(area.position.x, area.position.x + area.size.x):
		for y in range(area.position.y, area.position.y + area.size.y):
			var pos = Vector2i(x, y)
			if _is_valid_position(pos):
				result.append(_tiles[pos])
	return result

func get_neighbors(position: Vector2i, include_diagonals: bool = false) -> Array:
	"""Retorna tiles vizinhos"""
	var neighbors: Array = []
	var offsets = [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT
	]
	if include_diagonals:
		offsets.append_array([
			Vector2i.UP + Vector2i.LEFT,
			Vector2i.UP + Vector2i.RIGHT,
			Vector2i.DOWN + Vector2i.LEFT,
			Vector2i.DOWN + Vector2i.RIGHT
		])
	
	for offset in offsets:
		var neighbor_pos = position + offset
		if _is_valid_position(neighbor_pos):
			neighbors.append(neighbor_pos)
	
	return neighbors

func raycast(from: Vector2i, to: Vector2i) -> Array:
	"""Raycast entre dois pontos, retorna tiles atravessados"""
	var result: Array = []
	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	var sx = 1 if to.x > from.x else -1
	var sy = 1 if to.y > from.y else -1
	var err = dx - dy
	
	var current = from
	while current != to:
		result.append(current)
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			current.x += sx
		if e2 < dx:
			err += dx
			current.y += sy
	
	result.append(to)
	return result

func serialize() -> PackedByteArray:
	"""Serializa o grid para PackedByteArray"""
	var data = PackedByteArray()
	
	# Escrever dimensões
	data.append_array(PackedInt32Array([_grid_width, _grid_height]).to_byte_array())
	
	# Escrever cada tile
	for x in range(_grid_width):
		for y in range(_grid_height):
			var pos = Vector2i(x, y)
			var tile = _tiles[pos]
			
			# Escrever dados do tile
			data.append(tile.terrain_type)
			data.append_array(PackedFloat32Array([tile.elevation, tile.radiation_level]).to_byte_array())
			data.append(1 if tile.walkable else 0)
	
	return data

func deserialize(data: PackedByteArray) -> bool:
	"""Desserializa o grid de PackedByteArray"""
	if data.size() < 8:
		return false
	
	var offset = 0
	
	# Ler dimensões
	var width = data.decode_s32(offset)
	offset += 4
	var height = data.decode_s32(offset)
	offset += 4
	
	set_grid_size(width, height)
	
	# Ler cada tile
	for x in range(_grid_width):
		for y in range(_grid_height):
			if offset + 9 > data.size():
				return false
			
			var pos = Vector2i(x, y)
			var terrain_type = data[offset]
			offset += 1
			
			var elevation = data.decode_float(offset)
			offset += 4
			var radiation = data.decode_float(offset)
			offset += 4
			
			var walkable = data[offset] == 1
			offset += 1
			
			var tile = CityTileData.new(terrain_type, elevation, walkable, radiation)
			_tiles[pos] = tile
	
	return true

func _is_valid_position(position: Vector2i) -> bool:
	"""Verifica se uma posição está dentro do grid"""
	return position.x >= 0 and position.x < _grid_width and \
		   position.y >= 0 and position.y < _grid_height
