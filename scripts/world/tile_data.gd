extends Resource
class_name TileData
## Dados de um tile individual no mapa

@export var position: Vector2i = Vector2i.ZERO
@export var terrain_type: int = 0  # CityConfig.TerrainType
@export var is_walkable: bool = true
@export var is_blocking: bool = false
@export var height: float = 0.0
@export var elevation: int = 0  # Nível de elevação (para múltiplos andares)

# Propriedades opcionais
@export var object_id: String = ""  # ID do objeto neste tile (porta, container, etc)
@export var critter_id: String = ""  # ID do critter neste tile
@export var is_lit: bool = true
@export var light_level: float = 1.0

## Retorna se o tile é passável
func is_passable() -> bool:
	return is_walkable and not is_blocking

## Define o tipo de terreno
func set_terrain(terrain: int) -> void:
	terrain_type = terrain
	# Atualizar propriedades baseado no tipo
	match terrain:
		0:  # GROUND
			is_walkable = true
			is_blocking = false
		1:  # WATER
			is_walkable = false
			is_blocking = true
		2:  # ROCK
			is_walkable = false
			is_blocking = true
		3:  # SAND
			is_walkable = true
			is_blocking = false
		4:  # CONCRETE
			is_walkable = true
			is_blocking = false
		5:  # RADIATION_ZONE
			is_walkable = true
			is_blocking = false
		6:  # RUBBLE
			is_walkable = true
			is_blocking = false
		7:  # GRASS
			is_walkable = true
			is_blocking = false
		8:  # DIRT
			is_walkable = true
			is_blocking = false

## Retorna uma cópia do tile
func duplicate() -> TileData:
	var copy = TileData.new()
	copy.position = position
	copy.terrain_type = terrain_type
	copy.is_walkable = is_walkable
	copy.is_blocking = is_blocking
	copy.height = height
	copy.elevation = elevation
	copy.object_id = object_id
	copy.critter_id = critter_id
	copy.is_lit = is_lit
	copy.light_level = light_level
	return copy
