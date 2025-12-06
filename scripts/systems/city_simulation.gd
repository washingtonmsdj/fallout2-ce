## Sistema de Simulação de Cidade - Inspirado no Citybound
## Cria cidades dinâmicas que crescem e evoluem
class_name CitySimulation
extends Node

signal building_constructed(building: Node, position: Vector2)
signal citizen_spawned(citizen: Node)
signal city_updated()

## Configurações da cidade
@export var immigration_rate: float = 2.0  ## Segundos entre imigrações
@export var max_population: int = 100
@export var initial_buildings: int = 5

## Recursos da cidade
enum CityResource { FOOD, WATER, CAPS, MATERIALS, POWER }

## Tipos de zona
enum ZoneType { RESIDENTIAL, COMMERCIAL, INDUSTRIAL, AGRICULTURAL }

## Tipos de edifício
enum BuildingType { 
	HOUSE, SHOP, WORKSHOP, FARM, 
	WATER_TOWER, POWER_PLANT, CLINIC,
	BAR, HOTEL, WAREHOUSE
}

## Estado da cidade
var city_name: String = "New Settlement"
var population: int = 0
var resources: Dictionary = {}
var buildings: Array = []
var citizens: Array = []
var zones: Array = []
var roads: Array = []

## Timers
var immigration_timer: float = 0.0
var economy_timer: float = 0.0

## Grid da cidade
var city_grid: Dictionary = {}  ## Vector2i -> CellData
var grid_size: Vector2i = Vector2i(50, 50)
var cell_size: float = 32.0

func _ready():
	_initialize_resources()
	_generate_initial_city()

func _process(delta):
	_update_immigration(delta)
	_update_economy(delta)
	_update_citizens(delta)

## Inicializa recursos
func _initialize_resources():
	resources = {
		CityResource.FOOD: 100.0,
		CityResource.WATER: 100.0,
		CityResource.CAPS: 500.0,
		CityResource.MATERIALS: 50.0,
		CityResource.POWER: 0.0
	}

## Gera cidade inicial
func _generate_initial_city():
	# Criar estrada principal horizontal
	_create_main_road()
	
	# Criar estradas verticais
	for x in [10, 20, 30, 40]:
		for y in range(5, grid_size.y - 5):
			var cell = Vector2i(x, y)
			_set_cell(cell, "road")
			roads.append(cell)
	
	# Criar zona residencial (verde)
	_create_zone(Vector2i(5, 5), Vector2i(12, 8), ZoneType.RESIDENTIAL)
	_create_zone(Vector2i(5, 28), Vector2i(12, 8), ZoneType.RESIDENTIAL)
	
	# Criar zona comercial (azul)
	_create_zone(Vector2i(22, 5), Vector2i(8, 8), ZoneType.COMMERCIAL)
	
	# Criar zona industrial (amarela)
	_create_zone(Vector2i(32, 5), Vector2i(8, 8), ZoneType.INDUSTRIAL)
	
	# Criar zona agrícola (marrom)
	_create_zone(Vector2i(22, 28), Vector2i(18, 10), ZoneType.AGRICULTURAL)
	
	# Construir edifícios iniciais
	for i in range(initial_buildings):
		_try_build_random_building()
	
	# Garantir pelo menos uma fazenda e torre de água
	_try_build_building(BuildingType.FARM)
	_try_build_building(BuildingType.WATER_TOWER)

## Cria estrada principal
func _create_main_road():
	for x in range(grid_size.x):
		var cell = Vector2i(x, grid_size.y / 2)
		_set_cell(cell, "road")
		roads.append(cell)

## Cria uma zona
func _create_zone(start: Vector2i, size: Vector2i, type: ZoneType):
	var zone = {
		"start": start,
		"size": size,
		"type": type,
		"lots": []
	}
	
	# Criar lotes na zona
	for x in range(start.x, start.x + size.x, 3):
		for y in range(start.y, start.y + size.y, 3):
			if _is_adjacent_to_road(Vector2i(x, y)):
				var lot = {
					"position": Vector2i(x, y),
					"size": Vector2i(2, 2),
					"occupied": false,
					"building": null
				}
				zone["lots"].append(lot)
	
	zones.append(zone)

## Verifica se célula é adjacente a estrada
func _is_adjacent_to_road(cell: Vector2i) -> bool:
	var neighbors = [
		cell + Vector2i(0, 1),
		cell + Vector2i(0, -1),
		cell + Vector2i(1, 0),
		cell + Vector2i(-1, 0)
	]
	
	for neighbor in neighbors:
		if neighbor in roads:
			return true
	return false

## Define célula no grid
func _set_cell(cell: Vector2i, type: String):
	city_grid[cell] = {"type": type, "data": null}

## Atualiza imigração
func _update_immigration(delta):
	immigration_timer += delta
	
	if immigration_timer >= immigration_rate:
		immigration_timer = 0.0
		_try_immigrate()

## Tenta imigrar novo cidadão
func _try_immigrate():
	if population >= max_population:
		return
	
	# Verificar se há moradia disponível
	var available_house = _find_available_housing()
	if available_house.is_empty():
		# Tentar construir nova casa
		_try_build_building(BuildingType.HOUSE)
		return
	
	# Criar cidadão
	_spawn_citizen(available_house)

## Encontra moradia disponível
func _find_available_housing() -> Dictionary:
	for building in buildings:
		if building["type"] == BuildingType.HOUSE:
			if building["occupants"] < building["capacity"]:
				return building
	return {}

## Spawna cidadão
func _spawn_citizen(house: Dictionary):
	var citizen = {
		"id": population,
		"name": _generate_name(),
		"home": house,
		"job": null,
		"needs": {
			"hunger": 100.0,
			"thirst": 100.0,
			"rest": 100.0,
			"happiness": 50.0
		},
		"position": house["position"],
		"state": "idle"
	}
	
	citizens.append(citizen)
	house["occupants"] += 1
	population += 1
	
	emit_signal("citizen_spawned", citizen)

## Gera nome aleatório
func _generate_name() -> String:
	var first_names = ["John", "Jane", "Marcus", "Sarah", "Duke", "Rose", "Max", "Lily"]
	var last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis"]
	return first_names.pick_random() + " " + last_names.pick_random()

## Tenta construir edifício
func _try_build_building(type: BuildingType) -> bool:
	var lot = _find_vacant_lot_for_type(type)
	if lot.is_empty():
		return false
	
	return _construct_building(lot, type)

## Encontra lote vago para tipo de edifício
func _find_vacant_lot_for_type(type: BuildingType) -> Dictionary:
	var required_zone = _get_zone_for_building(type)
	
	for zone in zones:
		if zone["type"] == required_zone:
			for lot in zone["lots"]:
				if not lot["occupied"]:
					return lot
	
	return {}

## Retorna zona necessária para tipo de edifício
func _get_zone_for_building(type: BuildingType) -> ZoneType:
	match type:
		BuildingType.HOUSE:
			return ZoneType.RESIDENTIAL
		BuildingType.SHOP, BuildingType.BAR, BuildingType.HOTEL:
			return ZoneType.COMMERCIAL
		BuildingType.WORKSHOP, BuildingType.WAREHOUSE:
			return ZoneType.INDUSTRIAL
		BuildingType.FARM:
			return ZoneType.AGRICULTURAL
		_:
			return ZoneType.RESIDENTIAL

## Constrói edifício
func _construct_building(lot: Dictionary, type: BuildingType) -> bool:
	var cost = _get_building_cost(type)
	
	if resources[CityResource.MATERIALS] < cost:
		return false
	
	resources[CityResource.MATERIALS] -= cost
	
	var building = {
		"id": buildings.size(),
		"type": type,
		"position": lot["position"],
		"lot": lot,
		"capacity": _get_building_capacity(type),
		"occupants": 0,
		"production": _get_building_production(type),
		"health": 100.0
	}
	
	lot["occupied"] = true
	lot["building"] = building
	buildings.append(building)
	
	emit_signal("building_constructed", building, Vector2(lot["position"]) * cell_size)
	return true

## Custo de construção
func _get_building_cost(type: BuildingType) -> float:
	match type:
		BuildingType.HOUSE: return 10.0
		BuildingType.SHOP: return 20.0
		BuildingType.WORKSHOP: return 30.0
		BuildingType.FARM: return 15.0
		BuildingType.WATER_TOWER: return 50.0
		BuildingType.POWER_PLANT: return 100.0
		BuildingType.CLINIC: return 40.0
		BuildingType.BAR: return 25.0
		BuildingType.HOTEL: return 35.0
		BuildingType.WAREHOUSE: return 20.0
		_: return 10.0

## Capacidade do edifício
func _get_building_capacity(type: BuildingType) -> int:
	match type:
		BuildingType.HOUSE: return 4
		BuildingType.SHOP: return 2
		BuildingType.WORKSHOP: return 5
		BuildingType.FARM: return 3
		BuildingType.HOTEL: return 10
		_: return 1

## Produção do edifício
func _get_building_production(type: BuildingType) -> Dictionary:
	match type:
		BuildingType.FARM:
			return {CityResource.FOOD: 5.0}
		BuildingType.WATER_TOWER:
			return {CityResource.WATER: 10.0}
		BuildingType.POWER_PLANT:
			return {CityResource.POWER: 20.0}
		BuildingType.WORKSHOP:
			return {CityResource.MATERIALS: 2.0}
		BuildingType.SHOP:
			return {CityResource.CAPS: 3.0}
		_:
			return {}

## Tenta construir edifício aleatório
func _try_build_random_building():
	var types = [
		BuildingType.HOUSE,
		BuildingType.HOUSE,
		BuildingType.HOUSE,
		BuildingType.SHOP,
		BuildingType.FARM
	]
	_try_build_building(types.pick_random())

## Atualiza economia
func _update_economy(delta):
	economy_timer += delta
	
	if economy_timer >= 1.0:  # A cada segundo
		economy_timer = 0.0
		
		# Produção dos edifícios
		for building in buildings:
			for resource in building["production"]:
				resources[resource] += building["production"][resource] * delta
		
		# Consumo da população
		var food_consumption = population * 0.1
		var water_consumption = population * 0.15
		
		resources[CityResource.FOOD] = max(0, resources[CityResource.FOOD] - food_consumption)
		resources[CityResource.WATER] = max(0, resources[CityResource.WATER] - water_consumption)
		
		emit_signal("city_updated")

## Atualiza cidadãos
func _update_citizens(delta):
	for citizen in citizens:
		_update_citizen_needs(citizen, delta)
		_update_citizen_behavior(citizen, delta)

## Atualiza necessidades do cidadão
func _update_citizen_needs(citizen: Dictionary, delta: float):
	citizen["needs"]["hunger"] -= delta * 0.5
	citizen["needs"]["thirst"] -= delta * 0.8
	citizen["needs"]["rest"] -= delta * 0.3
	
	# Clamp valores
	for need in citizen["needs"]:
		citizen["needs"][need] = clamp(citizen["needs"][need], 0.0, 100.0)

## Atualiza comportamento do cidadão
func _update_citizen_behavior(citizen: Dictionary, delta: float):
	# Encontrar necessidade mais urgente
	var urgent_need = _find_urgent_need(citizen)
	
	match urgent_need:
		"hunger":
			citizen["state"] = "seeking_food"
			_citizen_seek_food(citizen)
		"thirst":
			citizen["state"] = "seeking_water"
			_citizen_seek_water(citizen)
		"rest":
			citizen["state"] = "going_home"
			_citizen_go_home(citizen)
		_:
			citizen["state"] = "working"
			_citizen_work(citizen)

## Encontra necessidade urgente
func _find_urgent_need(citizen: Dictionary) -> String:
	var min_value = 30.0  # Threshold de urgência
	var urgent = ""
	
	for need in citizen["needs"]:
		if citizen["needs"][need] < min_value:
			min_value = citizen["needs"][need]
			urgent = need
	
	return urgent

## Cidadão busca comida
func _citizen_seek_food(citizen: Dictionary):
	if resources[CityResource.FOOD] > 0:
		resources[CityResource.FOOD] -= 1.0
		citizen["needs"]["hunger"] = min(100.0, citizen["needs"]["hunger"] + 30.0)

## Cidadão busca água
func _citizen_seek_water(citizen: Dictionary):
	if resources[CityResource.WATER] > 0:
		resources[CityResource.WATER] -= 1.0
		citizen["needs"]["thirst"] = min(100.0, citizen["needs"]["thirst"] + 40.0)

## Cidadão vai para casa
func _citizen_go_home(citizen: Dictionary):
	citizen["needs"]["rest"] = min(100.0, citizen["needs"]["rest"] + 20.0)

## Cidadão trabalha
func _citizen_work(citizen: Dictionary):
	# Gera caps trabalhando
	resources[CityResource.CAPS] += 0.1

## API Pública

## Adiciona zona manualmente
func add_zone(start: Vector2i, size: Vector2i, type: ZoneType):
	_create_zone(start, size, type)

## Adiciona estrada
func add_road(from: Vector2i, to: Vector2i):
	var current = from
	while current != to:
		_set_cell(current, "road")
		roads.append(current)
		
		if current.x < to.x:
			current.x += 1
		elif current.x > to.x:
			current.x -= 1
		elif current.y < to.y:
			current.y += 1
		elif current.y > to.y:
			current.y -= 1

## Força construção de edifício
func force_build(type: BuildingType) -> bool:
	return _try_build_building(type)

## Retorna estatísticas da cidade
func get_stats() -> Dictionary:
	return {
		"name": city_name,
		"population": population,
		"buildings": buildings.size(),
		"resources": resources.duplicate(),
		"happiness": _calculate_average_happiness()
	}

## Calcula felicidade média
func _calculate_average_happiness() -> float:
	if citizens.is_empty():
		return 50.0
	
	var total = 0.0
	for citizen in citizens:
		total += citizen["needs"]["happiness"]
	
	return total / citizens.size()
