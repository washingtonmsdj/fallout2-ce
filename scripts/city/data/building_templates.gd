## Building Templates - Dados de templates de edifícios
## Define tamanhos, capacidades e produção/consumo para cada tipo
class_name BuildingTemplates
extends Node

# Estrutura de template
class BuildingTemplate:
	var building_type: int
	var name: String
	var size: Vector2i
	var capacity: int  # Pessoas que podem viver/trabalhar
	var construction_cost: Dictionary  # Recursos necessários
	var construction_time: int  # Em ticks
	var production: Dictionary  # Recursos produzidos por tick
	var consumption: Dictionary  # Recursos consumidos por tick
	var maintenance_cost: float  # Custo de manutenção por tick
	var happiness_modifier: float  # Modificador de felicidade
	var health_modifier: float  # Modificador de saúde
	
	func _init(p_type: int, p_name: String, p_size: Vector2i) -> void:
		building_type = p_type
		name = p_name
		size = p_size
		capacity = 0
		construction_cost = {}
		construction_time = 100
		production = {}
		consumption = {}
		maintenance_cost = 1.0
		happiness_modifier = 0.0
		health_modifier = 0.0

# Dicionário de templates
var templates: Dictionary = {}

func _ready() -> void:
	_initialize_templates()

func _initialize_templates() -> void:
	"""Inicializa todos os templates de edifícios"""
	
	# Residencial
	_add_template(BuildingType.SMALL_HOUSE, "Small House", Vector2i(3, 3), 4, 
		{"caps": 100, "materials": 50}, 50,
		{}, {"food": 2, "water": 2},
		0.5, 5.0, 2.0)
	
	_add_template(BuildingType.MEDIUM_HOUSE, "Medium House", Vector2i(4, 4), 8,
		{"caps": 200, "materials": 100}, 100,
		{}, {"food": 4, "water": 4},
		1.0, 10.0, 5.0)
	
	_add_template(BuildingType.LARGE_HOUSE, "Large House", Vector2i(5, 5), 12,
		{"caps": 400, "materials": 150}, 150,
		{}, {"food": 6, "water": 6},
		1.5, 15.0, 8.0)
	
	_add_template(BuildingType.APARTMENT, "Apartment", Vector2i(4, 6), 20,
		{"caps": 500, "materials": 200}, 200,
		{}, {"food": 10, "water": 10},
		2.0, 20.0, 10.0)
	
	# Comercial
	_add_template(BuildingType.SHOP, "Shop", Vector2i(3, 3), 5,
		{"caps": 150, "materials": 75}, 75,
		{"caps": 50}, {"food": 1, "water": 1},
		1.0, 5.0, 0.0)
	
	_add_template(BuildingType.MARKET, "Market", Vector2i(5, 5), 15,
		{"caps": 300, "materials": 150}, 150,
		{"caps": 100}, {"food": 3, "water": 3},
		2.0, 10.0, 0.0)
	
	_add_template(BuildingType.RESTAURANT, "Restaurant", Vector2i(4, 4), 10,
		{"caps": 250, "materials": 100}, 100,
		{"caps": 30}, {"food": 5, "water": 5},
		1.5, 15.0, 5.0)
	
	_add_template(BuildingType.BANK, "Bank", Vector2i(4, 4), 8,
		{"caps": 400, "materials": 200}, 200,
		{"caps": 200}, {"power": 5},
		2.0, 0.0, 0.0)
	
	# Industrial
	_add_template(BuildingType.FACTORY, "Factory", Vector2i(6, 6), 20,
		{"caps": 500, "materials": 300}, 300,
		{"materials": 50}, {"power": 10, "water": 5},
		3.0, -10.0, -5.0)
	
	_add_template(BuildingType.WORKSHOP, "Workshop", Vector2i(4, 4), 10,
		{"caps": 300, "materials": 150}, 150,
		{"components": 20}, {"power": 5},
		1.5, 0.0, 0.0)
	
	_add_template(BuildingType.WAREHOUSE, "Warehouse", Vector2i(5, 5), 5,
		{"caps": 200, "materials": 100}, 100,
		{}, {"power": 2},
		1.0, 0.0, 0.0)
	
	_add_template(BuildingType.POWER_PLANT, "Power Plant", Vector2i(6, 6), 15,
		{"caps": 600, "materials": 400}, 400,
		{"power": 100}, {"fuel": 20, "water": 10},
		5.0, -5.0, -10.0)
	
	# Agrícola
	_add_template(BuildingType.FARM, "Farm", Vector2i(5, 5), 8,
		{"caps": 200, "materials": 100}, 100,
		{"food": 30}, {"water": 10},
		1.0, 5.0, 5.0)
	
	_add_template(BuildingType.GREENHOUSE, "Greenhouse", Vector2i(4, 4), 6,
		{"caps": 250, "materials": 150}, 150,
		{"food": 20}, {"water": 15, "power": 3},
		1.5, 10.0, 5.0)
	
	_add_template(BuildingType.GRAIN_MILL, "Grain Mill", Vector2i(4, 4), 8,
		{"caps": 300, "materials": 150}, 150,
		{"food": 40}, {"power": 5},
		1.5, 0.0, 0.0)
	
	# Militar
	_add_template(BuildingType.GUARD_POST, "Guard Post", Vector2i(3, 3), 4,
		{"caps": 150, "materials": 100}, 100,
		{}, {"power": 2},
		1.0, 0.0, 0.0)
	
	_add_template(BuildingType.BARRACKS, "Barracks", Vector2i(5, 5), 20,
		{"caps": 400, "materials": 200}, 200,
		{}, {"food": 10, "water": 10, "power": 3},
		2.0, 0.0, 0.0)
	
	_add_template(BuildingType.WATCHTOWER, "Watchtower", Vector2i(3, 3), 2,
		{"caps": 200, "materials": 150}, 150,
		{}, {"power": 1},
		0.5, 0.0, 0.0)
	
	_add_template(BuildingType.ARMORY, "Armory", Vector2i(4, 4), 5,
		{"caps": 300, "materials": 200}, 200,
		{}, {"power": 2},
		1.5, 0.0, 0.0)
	
	# Utilidade
	_add_template(BuildingType.WATER_PUMP, "Water Pump", Vector2i(2, 2), 2,
		{"caps": 150, "materials": 100}, 100,
		{"water": 50}, {"power": 5},
		1.0, 0.0, 0.0)
	
	_add_template(BuildingType.MEDICAL_CLINIC, "Medical Clinic", Vector2i(4, 4), 10,
		{"caps": 300, "materials": 200}, 200,
		{}, {"medicine": 5, "power": 3},
		2.0, 0.0, 20.0)
	
	_add_template(BuildingType.SCHOOL, "School", Vector2i(5, 5), 30,
		{"caps": 400, "materials": 250}, 250,
		{}, {"power": 5},
		2.0, 10.0, 0.0)
	
	_add_template(BuildingType.LIBRARY, "Library", Vector2i(4, 4), 20,
		{"caps": 300, "materials": 200}, 200,
		{}, {"power": 3},
		1.5, 15.0, 0.0)
	
	# Especial
	_add_template(BuildingType.VAULT, "Vault", Vector2i(6, 6), 100,
		{"caps": 1000, "materials": 500}, 500,
		{}, {"power": 10},
		5.0, 20.0, 10.0)
	
	_add_template(BuildingType.SETTLEMENT_CENTER, "Settlement Center", Vector2i(5, 5), 50,
		{"caps": 800, "materials": 400}, 400,
		{}, {"power": 5},
		3.0, 25.0, 0.0)

func _add_template(building_type: int, name: String, size: Vector2i, capacity: int,
					construction_cost: Dictionary, construction_time: int,
					production: Dictionary, consumption: Dictionary,
					maintenance_cost: float, happiness_mod: float, health_mod: float) -> void:
	"""Adiciona um template de edifício"""
	var template = BuildingTemplate.new(building_type, name, size)
	template.capacity = capacity
	template.construction_cost = construction_cost.duplicate()
	template.construction_time = construction_time
	template.production = production.duplicate()
	template.consumption = consumption.duplicate()
	template.maintenance_cost = maintenance_cost
	template.happiness_modifier = happiness_mod
	template.health_modifier = health_mod
	
	templates[building_type] = template

func get_template(building_type: int) -> BuildingTemplate:
	"""Obtém um template de edifício"""
	return templates.get(building_type)

func get_all_templates() -> Array:
	"""Retorna todos os templates"""
	return templates.values()

func get_template_by_name(name: String) -> BuildingTemplate:
	"""Obtém um template pelo nome"""
	for template in templates.values():
		if template.name == name:
			return template
	return null

func get_templates_by_size(size: Vector2i) -> Array:
	"""Retorna templates de um tamanho específico"""
	var result: Array = []
	for template in templates.values():
		if template.size == size:
			result.append(template)
	return result

func get_templates_with_capacity(min_capacity: int) -> Array:
	"""Retorna templates com capacidade mínima"""
	var result: Array = []
	for template in templates.values():
		if template.capacity >= min_capacity:
			result.append(template)
	return result

# Enum para tipos de edifício (referência)
enum BuildingType {
	SMALL_HOUSE = 0,
	MEDIUM_HOUSE = 1,
	LARGE_HOUSE = 2,
	APARTMENT = 3,
	SHOP = 4,
	MARKET = 5,
	RESTAURANT = 6,
	BANK = 7,
	FACTORY = 8,
	WORKSHOP = 9,
	WAREHOUSE = 10,
	POWER_PLANT = 11,
	FARM = 12,
	GREENHOUSE = 13,
	GRAIN_MILL = 14,
	GUARD_POST = 15,
	BARRACKS = 16,
	WATCHTOWER = 17,
	ARMORY = 18,
	WATER_PUMP = 19,
	MEDICAL_CLINIC = 20,
	SCHOOL = 21,
	LIBRARY = 22,
	VAULT = 23,
	SETTLEMENT_CENTER = 24
}
