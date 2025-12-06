## CityEconomySystem - Sistema de economia da cidade
## Gerencia recursos, produção, consumo e preços dinâmicos
class_name CityEconomySystem
extends Node

# Enums para tipos de recursos
enum ResourceType {
	FOOD = 0,
	WATER = 1,
	CAPS = 2,
	MATERIALS = 3,
	POWER = 4,
	MEDICINE = 5,
	WEAPONS = 6,
	FUEL = 7,
	COMPONENTS = 8
}

# Classe para dados de um recurso
class ResourceData:
	var resource_type: int
	var amount: float = 0.0
	var production_rate: float = 0.0  # Por segundo
	var consumption_rate: float = 0.0  # Por segundo
	var price: float = 1.0
	var price_history: Array = []  # Últimos 100 preços
	
	func _init(p_type: int) -> void:
		resource_type = p_type
	
	func _to_string() -> String:
		return "ResourceData(type=%d, amount=%.1f, prod=%.2f, cons=%.2f, price=%.2f)" % [
			resource_type, amount, production_rate, consumption_rate, price
		]

# Armazenamento de recursos
var _resources: Dictionary = {}  # int (type) -> ResourceData
var config
var event_bus
var building_system

func _ready() -> void:
	_initialize_resources()

func set_config(cfg) -> void:
	config = cfg
	if config == null:
		config = CityConfig.new()

func _initialize_resources() -> void:
	"""Inicializa todos os tipos de recursos"""
	for resource_type in ResourceType.values():
		var resource = ResourceData.new(resource_type)
		resource.amount = 100.0  # Quantidade inicial
		_resources[resource_type] = resource

func set_systems(bus, building) -> void:
	"""Define as referências aos sistemas"""
	event_bus = bus
	building_system = building

func add_resource(resource_type: int, amount: float) -> bool:
	"""Adiciona uma quantidade de recurso"""
	if not _resources.has(resource_type):
		return false
	
	var old_amount = _resources[resource_type].amount
	_resources[resource_type].amount += amount
	
	if event_bus != null:
		event_bus.resource_changed.emit(resource_type, old_amount, _resources[resource_type].amount)
	
	return true

func remove_resource(resource_type: int, amount: float) -> bool:
	"""Remove uma quantidade de recurso"""
	if not _resources.has(resource_type):
		return false
	
	var resource = _resources[resource_type]
	
	# Não permitir quantidade negativa
	if resource.amount < amount:
		return false
	
	var old_amount = resource.amount
	resource.amount -= amount
	
	if event_bus != null:
		event_bus.resource_changed.emit(resource_type, old_amount, resource.amount)
	
	return true

func get_resource_amount(resource_type: int) -> float:
	"""Obtém a quantidade de um recurso"""
	if not _resources.has(resource_type):
		return 0.0
	
	return _resources[resource_type].amount

func set_resource_amount(resource_type: int, amount: float) -> bool:
	"""Define a quantidade de um recurso"""
	if not _resources.has(resource_type):
		return false
	
	var old_amount = _resources[resource_type].amount
	_resources[resource_type].amount = max(0.0, amount)
	
	if event_bus != null:
		event_bus.resource_changed.emit(resource_type, old_amount, _resources[resource_type].amount)
	
	return true

func get_resource_price(resource_type: int) -> float:
	"""Obtém o preço de um recurso"""
	if not _resources.has(resource_type):
		return 0.0
	
	return _resources[resource_type].price

func set_resource_price(resource_type: int, price: float) -> bool:
	"""Define o preço de um recurso"""
	if not _resources.has(resource_type):
		return false
	
	var resource = _resources[resource_type]
	resource.price = max(0.1, price)
	
	# Manter histórico de preços
	resource.price_history.append(resource.price)
	if resource.price_history.size() > 100:
		resource.price_history.pop_front()
	
	if event_bus != null:
		event_bus.price_updated.emit(resource_type, resource.price)
	
	return true

func update_production_rates(delta: float) -> void:
	"""Atualiza as taxas de produção e consumo baseado nos edifícios"""
	if building_system == null:
		return
	
	# Resetar taxas
	for resource in _resources.values():
		resource.production_rate = 0.0
		resource.consumption_rate = 0.0
	
	# Calcular produção e consumo de cada edifício
	var buildings = building_system.get_all_buildings()
	for building in buildings:
		if not building.is_operational:
			continue
		
		_update_building_production(building)

func _update_building_production(building: BuildingSystem.BuildingData) -> void:
	"""Atualiza a produção de um edifício específico"""
	# Será expandido quando os templates de edifício estiverem prontos
	pass

func update_economy(delta: float) -> void:
	"""Atualiza a economia (produção, consumo, preços)"""
	# Aplicar produção e consumo
	for resource in _resources.values():
		var net_rate = resource.production_rate - resource.consumption_rate
		resource.amount += net_rate * delta
		resource.amount = max(0.0, resource.amount)
	
	# Atualizar preços dinâmicos
	_update_dynamic_prices()

func _update_dynamic_prices() -> void:
	"""Atualiza preços dinamicamente baseado em oferta e demanda"""
	for resource in _resources.values():
		var demand = resource.consumption_rate
		var supply = resource.production_rate
		
		if supply == 0.0 and demand > 0.0:
			# Sem produção e há demanda - aumentar preço
			resource.price *= 1.05
		elif supply > demand and resource.amount > 100.0:
			# Excesso de produção - diminuir preço
			resource.price *= 0.95
		elif supply < demand and resource.amount < 50.0:
			# Escassez - aumentar preço
			resource.price *= 1.1
		
		# Limitar preço entre 0.1 e 10.0
		resource.price = clamp(resource.price, 0.1, 10.0)

func get_resource_statistics() -> Dictionary:
	"""Retorna estatísticas dos recursos"""
	var stats = {
		"total_resources": _resources.size(),
		"resources": {}
	}
	
	for resource_type in _resources.keys():
		var resource = _resources[resource_type]
		var type_name = ResourceType.keys()[resource_type]
		
		stats["resources"][type_name] = {
			"amount": resource.amount,
			"production_rate": resource.production_rate,
			"consumption_rate": resource.consumption_rate,
			"price": resource.price,
			"balance": resource.production_rate - resource.consumption_rate
		}
	
	return stats

func get_all_resources() -> Dictionary:
	"""Retorna todos os recursos"""
	return _resources.duplicate()

func can_afford(resource_type: int, amount: float) -> bool:
	"""Verifica se há recursos suficientes"""
	if not _resources.has(resource_type):
		return false
	
	return _resources[resource_type].amount >= amount

func get_resource_value(resource_type: int, amount: float) -> float:
	"""Calcula o valor de uma quantidade de recurso"""
	if not _resources.has(resource_type):
		return 0.0
	
	return _resources[resource_type].price * amount

func trade_resources(from_type: int, from_amount: float, to_type: int) -> float:
	"""Troca um recurso por outro baseado em preços"""
	if not _resources.has(from_type) or not _resources.has(to_type):
		return 0.0
	
	if not can_afford(from_type, from_amount):
		return 0.0
	
	var from_value = get_resource_value(from_type, from_amount)
	var to_amount = from_value / _resources[to_type].price
	
	remove_resource(from_type, from_amount)
	add_resource(to_type, to_amount)
	
	return to_amount
