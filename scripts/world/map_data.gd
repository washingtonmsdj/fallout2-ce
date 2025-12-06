extends Resource
class_name MapData
## Dados de um mapa completo

@export var map_name: String = "Untitled Map"
@export var map_id: String = ""
@export var width: int = 100
@export var height: int = 100
@export var tile_size: float = 32.0

# Dados dos tiles
var tiles: Dictionary = {}  # {Vector2i: TileData}
var objects: Dictionary = {}  # {String: MapObject}
var critters: Dictionary = {}  # {String: Critter}
var triggers: Array[TriggerZone] = []

## Inicializa o mapa com tiles vazios
func initialize() -> void:
	tiles.clear()
	
	for x in range(width):
		for y in range(height):
			var pos = Vector2i(x, y)
			var tile = TileData.new()
			tile.position = pos
			tile.set_terrain(0)  # GROUND por padrão
			tiles[pos] = tile

## Retorna o tile em uma posição
func get_tile(position: Vector2i) -> TileData:
	if position in tiles:
		return tiles[position]
	return null

## Define um tile em uma posição
func set_tile(position: Vector2i, tile: TileData) -> void:
	if position.x >= 0 and position.x < width and position.y >= 0 and position.y < height:
		tiles[position] = tile
		tile.position = position

## Verifica se uma posição é válida
func is_valid_position(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < width and position.y >= 0 and position.y < height

## Verifica se um tile é passável
func is_walkable(position: Vector2i) -> bool:
	var tile = get_tile(position)
	if tile == null:
		return false
	return tile.is_passable()

## Retorna todos os tiles passáveis
func get_walkable_tiles() -> Array[Vector2i]:
	var walkable: Array[Vector2i] = []
	
	for pos in tiles:
		var tile = tiles[pos]
		if tile.is_passable():
			walkable.append(pos)
	
	return walkable

## Retorna tiles vizinhos
func get_neighbors(position: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	
	var directions = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i(1, 1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(-1, -1)
	]
	
	for dir in directions:
		var neighbor_pos = position + dir
		if is_valid_position(neighbor_pos):
			neighbors.append(neighbor_pos)
	
	return neighbors

## Retorna tiles vizinhos passáveis
func get_walkable_neighbors(position: Vector2i) -> Array[Vector2i]:
	var walkable_neighbors: Array[Vector2i] = []
	
	for neighbor in get_neighbors(position):
		if is_walkable(neighbor):
			walkable_neighbors.append(neighbor)
	
	return walkable_neighbors

## Adiciona um objeto ao mapa
func add_object(obj_id: String, obj: MapObject, position: Vector2i) -> void:
	objects[obj_id] = obj
	var tile = get_tile(position)
	if tile:
		tile.object_id = obj_id

## Remove um objeto do mapa
func remove_object(obj_id: String) -> void:
	if obj_id in objects:
		objects.erase(obj_id)
		
		# Remover referência do tile
		for pos in tiles:
			var tile = tiles[pos]
			if tile.object_id == obj_id:
				tile.object_id = ""

## Adiciona um critter ao mapa
func add_critter(critter_id: String, critter: Critter, position: Vector2i) -> void:
	critters[critter_id] = critter
	var tile = get_tile(position)
	if tile:
		tile.critter_id = critter_id

## Remove um critter do mapa
func remove_critter(critter_id: String) -> void:
	if critter_id in critters:
		critters.erase(critter_id)
		
		# Remover referência do tile
		for pos in tiles:
			var tile = tiles[pos]
			if tile.critter_id == critter_id:
				tile.critter_id = ""

## Retorna informações sobre o mapa
func get_map_info() -> Dictionary:
	return {
		"name": map_name,
		"id": map_id,
		"width": width,
		"height": height,
		"tile_size": tile_size,
		"tile_count": tiles.size(),
		"object_count": objects.size(),
		"critter_count": critters.size(),
		"trigger_count": triggers.size()
	}

## Calcula a distância entre dois tiles
func get_distance(from: Vector2i, to: Vector2i) -> float:
	return from.distance_to(to)

## Retorna tiles em um raio
func get_tiles_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var tiles_in_radius: Array[Vector2i] = []
	
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var pos = Vector2i(x, y)
			if is_valid_position(pos):
				if center.distance_to(pos) <= radius:
					tiles_in_radius.append(pos)
	
	return tiles_in_radius
