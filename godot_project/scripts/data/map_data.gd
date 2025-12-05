class_name MapData
extends Resource

## Dados de um mapa do Fallout 2
## Contém informações sobre tiles, objetos, NPCs e conexões

# Identificação
@export var id: String = ""
@export var name: String = ""

# Dimensões
@export var width: int = 200
@export var height: int = 200
@export var elevation_count: int = 3

# Tiles por elevação [elevation][y][x]
@export var floor_tiles: Array = []
@export var roof_tiles: Array = []

# Objetos no mapa
@export var objects: Array = []

# NPCs no mapa
@export var npcs: Array = []

# Itens no mapa
@export var items: Array = []

# Conexões com outros mapas
@export var exits: Array = []

# Scripts do mapa
@export var map_scripts: Array[String] = []
@export var spatial_scripts: Dictionary = {}

# Flags e variáveis do mapa
@export var flags: Dictionary = {}
@export var variables: Dictionary = {}

# Música e ambiente
@export var music_track: String = ""
@export var ambient_sound: String = ""
@export var lighting_level: float = 1.0


func _init() -> void:
	pass


## Inicializar mapa com valores
func setup(p_id: String, p_name: String, p_width: int, p_height: int) -> MapData:
	id = p_id
	name = p_name
	width = p_width
	height = p_height
	elevation_count = 3
	
	# Inicializar arrays de tiles
	floor_tiles.clear()
	roof_tiles.clear()
	
	for elev in range(elevation_count):
		var floor_layer: Array = []
		var roof_layer: Array = []
		
		for y in range(p_height):
			var floor_row: Array = []
			var roof_row: Array = []
			
			for x in range(p_width):
				floor_row.append(0)
				roof_row.append(0)
			
			floor_layer.append(floor_row)
			roof_layer.append(roof_row)
		
		floor_tiles.append(floor_layer)
		roof_tiles.append(roof_layer)
	
	return self


## Obter tile em posição específica
func get_tile(pos: Vector2i, elev: int) -> TileData:
	if elev < 0 or elev >= elevation_count:
		return null
	
	if pos.x < 0 or pos.x >= width or pos.y < 0 or pos.y >= height:
		return null
	
	var tid = floor_tiles[elev][pos.y][pos.x]
	var tile = TileData.new()
	tile.tile_id = tid
	tile.elevation = elev
	return tile


## Definir tile em posição específica
func set_tile(pos: Vector2i, elevation: int, tile_id: int) -> void:
	if elevation < 0 or elevation >= elevation_count:
		return
	
	if pos.x < 0 or pos.x >= width or pos.y < 0 or pos.y >= height:
		return
	
	floor_tiles[elevation][pos.y][pos.x] = tile_id


## Verificar se posição é válida
func is_valid_position(pos: Vector2i, elevation: int) -> bool:
	if elevation < 0 or elevation >= elevation_count:
		return false
	
	if pos.x < 0 or pos.x >= width or pos.y < 0 or pos.y >= height:
		return false
	
	return true


## Obter todos os objetos em uma posição
func get_objects_at(pos: Vector2i) -> Array:
	var result: Array = []
	
	for obj in objects:
		if obj.position == pos:
			result.append(obj)
	
	return result


## Obter todos os NPCs em uma posição
func get_npcs_at(pos: Vector2i) -> Array:
	var result: Array = []
	
	for npc in npcs:
		if npc.position == pos:
			result.append(npc)
	
	return result


## Validar integridade do mapa
func validate() -> Array:
	var errors: Array = []
	
	if id.is_empty():
		errors.append("Map ID cannot be empty")
	
	if name.is_empty():
		errors.append("Map name cannot be empty")
	
	if width <= 0 or height <= 0:
		errors.append("Map dimensions must be positive")
	
	if elevation_count <= 0 or elevation_count > 3:
		errors.append("Elevation count must be between 1 and 3")
	
	if floor_tiles.size() != elevation_count:
		errors.append("Floor tiles array size mismatch")
	
	if roof_tiles.size() != elevation_count:
		errors.append("Roof tiles array size mismatch")
	
	# Validar objetos
	for obj in objects:
		if not is_valid_position(obj.position, 0):
			errors.append("Object outside map bounds: " + obj.id)
	
	# Validar NPCs
	for npc in npcs:
		if not is_valid_position(npc.position, 0):
			errors.append("NPC outside map bounds: " + npc.npc_id)
	
	# Validar itens
	for item in items:
		if not is_valid_position(item.position, 0):
			errors.append("Item outside map bounds: " + item.item_id)
	
	return errors
