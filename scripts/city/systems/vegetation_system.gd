## VegetationSystem - Sistema de vegetação procedural
## Gera e gerencia árvores, arbustos, etc.
class_name VegetationSystem
extends Node

## Tipos de vegetação
enum VegetationType {
	TREE_OAK,
	TREE_PINE,
	TREE_PALM,
	BUSH,
	GRASS_PATCH,
	FLOWERS
}

## Dados de uma planta
class Plant:
	var id: int
	var position: Vector2i
	var type: int
	var age: float = 0.0
	var health: float = 100.0
	var size: float = 1.0
	
	func _init(p_id: int, p_pos: Vector2i, p_type: int):
		id = p_id
		position = p_pos
		type = p_type
		size = randf_range(0.8, 1.2)

## Plantas ativas
var _plants: Dictionary = {}  # id -> Plant
var _next_plant_id: int = 0
var _grid_system
var _rng: RandomNumberGenerator

## Sinais
signal plant_added(plant_id: int, position: Vector2i, type: int)
signal plant_removed(plant_id: int)

func _init() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

func set_grid_system(grid) -> void:
	_grid_system = grid

## Planta uma árvore/planta
func plant_vegetation(pos: Vector2i, type: int) -> int:
	var plant_id = _next_plant_id
	_next_plant_id += 1
	
	var plant = Plant.new(plant_id, pos, type)
	_plants[plant_id] = plant
	
	plant_added.emit(plant_id, pos, type)
	return plant_id

## Remove vegetação
func remove_vegetation(plant_id: int) -> bool:
	if not _plants.has(plant_id):
		return false
	
	_plants.erase(plant_id)
	plant_removed.emit(plant_id)
	return true

## Gera vegetação aleatória em uma área
func generate_vegetation_in_area(start: Vector2i, end: Vector2i, density: float = 0.1) -> void:
	for y in range(start.y, end.y):
		for x in range(start.x, end.x):
			if _rng.randf() < density:
				var type = _rng.randi_range(VegetationType.TREE_OAK, VegetationType.TREE_PINE)
				plant_vegetation(Vector2i(x, y), type)

## Gera árvores ao longo de uma estrada
func generate_street_trees(road_tiles: Array, spacing: int = 5) -> void:
	var count = 0
	for tile in road_tiles:
		if count % spacing == 0:
			# Plantar dos dois lados da estrada
			var offset_x = [-2, 2][_rng.randi() % 2]
			var offset_y = [-2, 2][_rng.randi() % 2]
			var tree_pos = Vector2i(tile.x + offset_x, tile.y + offset_y)
			plant_vegetation(tree_pos, VegetationType.TREE_OAK)
		count += 1

## Retorna todas as plantas
func get_all_plants() -> Array:
	return _plants.values()

## Retorna uma planta específica
func get_plant(plant_id: int):
	return _plants.get(plant_id)

## Atualiza crescimento das plantas
func update_vegetation(delta: float) -> void:
	for plant in _plants.values():
		plant.age += delta * 0.1
		# Plantas crescem até um tamanho máximo
		if plant.size < 1.5:
			plant.size += delta * 0.01

## Limpa todas as plantas
func clear_all() -> void:
	_plants.clear()
	_next_plant_id = 0

## Estatísticas
func get_vegetation_count() -> int:
	return _plants.size()

func get_vegetation_by_type(type: int) -> int:
	var count = 0
	for plant in _plants.values():
		if plant.type == type:
			count += 1
	return count
