## VehicleSystem - Sistema de veículos
## Gerencia veículos, movimento, combustível e customização
class_name VehicleSystem
extends Node

# Estrutura de dados para veículos
class VehicleData:
	var id: int
	var type: CityConfig.VehicleType
	var position: Vector2i
	var velocity: Vector2 = Vector2.ZERO
	var acceleration: float = 0.0
	var rotation: float = 0.0
	var fuel: float
	var max_fuel: float
	var fuel_consumption: float
	var cargo: float = 0.0
	var max_cargo: float
	var health: float
	var max_health: float
	var speed: float
	var passengers: int = 0
	var max_passengers: int
	var condition: float = 100.0  # 0-100
	var owner_faction: int = -1
	var upgrades: Array[String] = []
	var customizations: Dictionary = {}
	var path: Array[Vector2i] = []
	var path_index: int = 0
	var is_moving: bool = false
	var target_position: Vector2i = Vector2i.ZERO
	
	func _init(p_id: int, p_type: CityConfig.VehicleType, p_position: Vector2i):
		id = p_id
		type = p_type
		position = p_position
		
		var stats = CityConfig.VEHICLE_STATS[p_type]
		speed = stats["speed"]
		max_fuel = stats["fuel_capacity"]
		fuel = max_fuel * 0.5  # Start at 50% fuel
		fuel_consumption = stats["fuel_consumption"]
		max_cargo = stats["cargo_capacity"]
		max_health = stats["health"]
		health = max_health
		max_passengers = stats["passengers"]

# Classe para customizações de veículos
class VehicleUpgrade:
	var name: String
	var type: String  # "engine", "armor", "cargo", "weapon"
	var cost: Dictionary
	var effects: Dictionary
	
	func _init(p_name: String, p_type: String, p_cost: Dictionary, p_effects: Dictionary):
		name = p_name
		type = p_type
		cost = p_cost
		effects = p_effects

# Variáveis do sistema
var vehicles: Dictionary = {}  # id -> VehicleData
var next_vehicle_id: int = 0
var event_bus: EventBus
var grid_system: GridSystem
var road_system: RoadSystem
var economy_system: EconomySystem

# Upgrades disponíveis
var available_upgrades: Array[VehicleUpgrade] = []

func _ready() -> void:
	event_bus = get_tree().root.get_child(0).get_node_or_null("EventBus")
	grid_system = get_tree().root.get_child(0).get_node_or_null("GridSystem")
	road_system = get_tree().root.get_child(0).get_node_or_null("RoadSystem")
	economy_system = get_tree().root.get_child(0).get_node_or_null("EconomySystem")
	
	_initialize_upgrades()

func _initialize_upgrades() -> void:
	"""Inicializa os upgrades disponíveis para veículos"""
	available_upgrades = [
		VehicleUpgrade.new("Turbo Engine", "engine", 
			{"materials": 50.0, "components": 20.0},
			{"speed_multiplier": 1.3}),
		VehicleUpgrade.new("Reinforced Armor", "armor",
			{"materials": 100.0},
			{"health_multiplier": 1.5}),
		VehicleUpgrade.new("Extended Cargo", "cargo",
			{"materials": 30.0},
			{"cargo_multiplier": 1.5}),
		VehicleUpgrade.new("Fuel Efficiency", "engine",
			{"components": 15.0},
			{"fuel_consumption_multiplier": 0.7}),
		VehicleUpgrade.new("Weapon Mount", "weapon",
			{"materials": 80.0, "weapons": 10.0},
			{"has_weapon": true, "weapon_damage": 25.0})
	]

# =============================================================================
# VEHICLE CREATION AND MANAGEMENT
# =============================================================================

func create_vehicle(vehicle_type: CityConfig.VehicleType, position: Vector2i, faction: int = -1) -> int:
	"""Cria um novo veículo"""
	var vehicle_id = next_vehicle_id
	next_vehicle_id += 1
	
	var vehicle = VehicleData.new(vehicle_id, vehicle_type, position)
	vehicle.owner_faction = faction
	
	vehicles[vehicle_id] = vehicle
	
	if event_bus:
		event_bus.vehicle_created.emit(vehicle_id, vehicle_type, position)
	
	return vehicle_id

func destroy_vehicle(vehicle_id: int) -> void:
	"""Destrói um veículo"""
	if not vehicles.has(vehicle_id):
		push_error("Vehicle %d not found" % vehicle_id)
		return
	
	var vehicle = vehicles[vehicle_id]
	vehicles.erase(vehicle_id)
	
	if event_bus:
		event_bus.vehicle_destroyed.emit(vehicle_id)

func get_vehicle(vehicle_id: int) -> VehicleData:
	"""Obtém dados de um veículo"""
	return vehicles.get(vehicle_id)

func get_vehicles_in_area(rect: Rect2i) -> Array[VehicleData]:
	"""Obtém todos os veículos em uma área"""
	var result: Array[VehicleData] = []
	for vehicle in vehicles.values():
		if rect.has_point(vehicle.position):
			result.append(vehicle)
	return result

func get_vehicles_by_faction(faction_id: int) -> Array[VehicleData]:
	"""Obtém todos os veículos de uma facção"""
	var result: Array[VehicleData] = []
	for vehicle in vehicles.values():
		if vehicle.owner_faction == faction_id:
			result.append(vehicle)
	return result

# =============================================================================
# FUEL MANAGEMENT
# =============================================================================

func consume_fuel(vehicle_id: int, amount: float) -> bool:
	"""Consome combustível de um veículo"""
	if not vehicles.has(vehicle_id):
		return false
	
	var vehicle = vehicles[vehicle_id]
	if vehicle.fuel >= amount:
		vehicle.fuel -= amount
		return true
	return false

func refuel(vehicle_id: int, amount: float) -> bool:
	"""Abastece um veículo"""
	if not vehicles.has(vehicle_id):
		return false
	
	var vehicle = vehicles[vehicle_id]
	var fuel_needed = vehicle.max_fuel - vehicle.fuel
	var fuel_to_add = minf(amount, fuel_needed)
	
	# Consome combustível do sistema econômico
	if economy_system and economy_system.consume_resource(CityConfig.ResourceType.FUEL, fuel_to_add):
		vehicle.fuel += fuel_to_add
		return true
	
	return false

func get_fuel_percentage(vehicle_id: int) -> float:
	"""Obtém a porcentagem de combustível"""
	if not vehicles.has(vehicle_id):
		return 0.0
	
	var vehicle = vehicles[vehicle_id]
	return (vehicle.fuel / vehicle.max_fuel) * 100.0

func is_fuel_critical(vehicle_id: int) -> bool:
	"""Verifica se o combustível está crítico"""
	return get_fuel_percentage(vehicle_id) < 20.0

# =============================================================================
# CARGO MANAGEMENT
# =============================================================================

func add_cargo(vehicle_id: int, amount: float) -> bool:
	"""Adiciona carga ao veículo"""
	if not vehicles.has(vehicle_id):
		return false
	
	var vehicle = vehicles[vehicle_id]
	if vehicle.cargo + amount <= vehicle.max_cargo:
		vehicle.cargo += amount
		return true
	return false

func remove_cargo(vehicle_id: int, amount: float) -> bool:
	"""Remove carga do veículo"""
	if not vehicles.has(vehicle_id):
		return false
	
	var vehicle = vehicles[vehicle_id]
	if vehicle.cargo >= amount:
		vehicle.cargo -= amount
		return true
	return false

func get_cargo_percentage(vehicle_id: int) -> float:
	"""Obtém a porcentagem de carga"""
	if not vehicles.has(vehicle_id):
		return 0.0
	
	var vehicle = vehicles[vehicle_id]
	return (vehicle.cargo / vehicle.max_cargo) * 100.0

func is_cargo_full(vehicle_id: int) -> bool:
	"""Verifica se a carga está cheia"""
	if not vehicles.has(vehicle_id):
		return false
	
	var vehicle = vehicles[vehicle_id]
	return vehicle.cargo >= vehicle.max_cargo

# =============================================================================
# PASSENGER MANAGEMENT
# =============================================================================

func add_passenger(vehicle_id: int) -> bool:
	"""Adiciona um passageiro ao veículo"""
	if not vehicles.has(vehicle_id):
		return false
	
	var vehicle = vehicles[vehicle_id]
	if vehicle.passengers < vehicle.max_passengers:
		vehicle.passengers += 1
		return true
	return false

func remove_passenger(vehicle_id: int) -> bool:
	"""Remove um passageiro do veículo"""
	if not vehicles.has(vehicle_id):
		return false
	
	var vehicle = vehicles[vehicle_id]
	if vehicle.passengers > 0:
		vehicle.passengers -= 1
		return true
	return false

func get_passenger_count(vehicle_id: int) -> int:
	"""Obtém o número de passageiros"""
	if not vehicles.has(vehicle_id):
		return 0
	
	return vehicles[vehicle_id].passengers

func is_full(vehicle_id: int) -> bool:
	"""Verifica se o veículo está cheio de passageiros"""
	if not vehicles.has(vehicle_id):
		return false
	
	var vehicle = vehicles[vehicle_id]
	return vehicle.passengers >= vehicle.max_passengers

# =============================================================================
# VEHICLE CONDITION AND DAMAGE
# =============================================================================

func damage_vehicle(vehicle_id: int, amount: float) -> void:
	"""Causa dano a um veículo"""
	if not vehicles.has(vehicle_id):
		return
	
	var vehicle = vehicles[vehicle_id]
	vehicle.health = maxf(0.0, vehicle.health - amount)
	vehicle.condition = (vehicle.health / vehicle.max_health) * 100.0
	
	if event_bus:
		event_bus.vehicle_damaged.emit(vehicle_id, amount, vehicle.health)

func repair_vehicle(vehicle_id: int, amount: float) -> bool:
	"""Repara um veículo"""
	if not vehicles.has(vehicle_id):
		return false
	
	var vehicle = vehicles[vehicle_id]
	var repair_amount = minf(amount, vehicle.max_health - vehicle.health)
	
	vehicle.health += repair_amount
	vehicle.condition = (vehicle.health / vehicle.max_health) * 100.0
	
	if event_bus:
		event_bus.vehicle_repaired.emit(vehicle_id, repair_amount)
	
	return true

func is_operational(vehicle_id: int) -> bool:
	"""Verifica se um veículo está operacional"""
	if not vehicles.has(vehicle_id):
		return false
	
	var vehicle = vehicles[vehicle_id]
	return vehicle.health > 0.0 and vehicle.fuel > 0.0

func is_destroyed(vehicle_id: int) -> bool:
	"""Verifica se um veículo foi destruído"""
	if not vehicles.has(vehicle_id):
		return false
	
	return vehicles[vehicle_id].health <= 0.0

# =============================================================================
# MOVEMENT AND PATHFINDING
# =============================================================================

func move_to(vehicle_id: int, target: Vector2i) -> bool:
	"""Move um veículo para um destino"""
	if not vehicles.has(vehicle_id):
		return false
	
	var vehicle = vehicles[vehicle_id]
	
	# Verifica se tem combustível
	if vehicle.fuel <= 0.0:
		return false
	
	# Obtém caminho usando o sistema de pathfinding
	if road_system:
		# Usa raycast do grid para criar um caminho simples
		if grid_system:
			var path = grid_system.raycast(vehicle.position, target)
			if path and path.size() > 0:
				vehicle.path = path
				vehicle.path_index = 0
				vehicle.target_position = target
				vehicle.is_moving = true
				return true
	
	return false

func stop_vehicle(vehicle_id: int) -> void:
	"""Para um veículo"""
	if not vehicles.has(vehicle_id):
		return
	
	var vehicle = vehicles[vehicle_id]
	vehicle.is_moving = false
	vehicle.path.clear()
	vehicle.path_index = 0
	vehicle.velocity = Vector2.ZERO
	vehicle.acceleration = 0.0

func update_vehicle_movement(vehicle_id: int, delta: float) -> void:
	"""Atualiza o movimento de um veículo"""
	if not vehicles.has(vehicle_id):
		return
	
	var vehicle = vehicles[vehicle_id]
	
	if not vehicle.is_moving or vehicle.path.is_empty():
		return
	
	# Calcula consumo de combustível baseado na distância
	var distance_per_frame = vehicle.speed * delta
	var fuel_consumed = (distance_per_frame / 100.0) * vehicle.fuel_consumption
	
	if not consume_fuel(vehicle_id, fuel_consumed):
		stop_vehicle(vehicle_id)
		return
	
	# Move para o próximo waypoint
	if vehicle.path_index < vehicle.path.size():
		var next_pos = vehicle.path[vehicle.path_index]
		var direction = (next_pos - vehicle.position).normalized()
		
		vehicle.velocity = direction * vehicle.speed
		vehicle.position = next_pos
		vehicle.path_index += 1
		
		# Atualiza rotação
		if direction != Vector2.ZERO:
			vehicle.rotation = atan2(direction.y, direction.x)
	else:
		# Chegou ao destino
		stop_vehicle(vehicle_id)

# =============================================================================
# UPGRADES AND CUSTOMIZATION
# =============================================================================

func apply_upgrade(vehicle_id: int, upgrade_name: String) -> bool:
	"""Aplica um upgrade a um veículo"""
	if not vehicles.has(vehicle_id):
		return false
	
	var vehicle = vehicles[vehicle_id]
	
	# Encontra o upgrade
	var upgrade: VehicleUpgrade = null
	for avail_upgrade in available_upgrades:
		if avail_upgrade.name == upgrade_name:
			upgrade = avail_upgrade
			break
	
	if not upgrade:
		return false
	
	# Verifica se já tem o upgrade
	if upgrade_name in vehicle.upgrades:
		return false
	
	# Consome recursos
	if economy_system:
		for resource_type in upgrade.cost:
			var amount = upgrade.cost[resource_type]
			if not economy_system.consume_resource(resource_type, amount):
				return false
	
	# Aplica efeitos do upgrade
	for effect_name in upgrade.effects:
		var effect_value = upgrade.effects[effect_name]
		
		match effect_name:
			"speed_multiplier":
				vehicle.speed *= effect_value
			"health_multiplier":
				vehicle.max_health *= effect_value
				vehicle.health = vehicle.max_health
			"cargo_multiplier":
				vehicle.max_cargo *= effect_value
			"fuel_consumption_multiplier":
				vehicle.fuel_consumption *= effect_value
			"has_weapon":
				vehicle.customizations["has_weapon"] = effect_value
			"weapon_damage":
				vehicle.customizations["weapon_damage"] = effect_value
	
	vehicle.upgrades.append(upgrade_name)
	
	if event_bus:
		event_bus.vehicle_upgraded.emit(vehicle_id, upgrade_name)
	
	return true

func get_available_upgrades(vehicle_id: int) -> Array[String]:
	"""Obtém upgrades disponíveis para um veículo"""
	if not vehicles.has(vehicle_id):
		return []
	
	var vehicle = vehicles[vehicle_id]
	var available: Array[String] = []
	
	for upgrade in available_upgrades:
		if not upgrade.name in vehicle.upgrades:
			available.append(upgrade.name)
	
	return available

func get_applied_upgrades(vehicle_id: int) -> Array[String]:
	"""Obtém upgrades aplicados a um veículo"""
	if not vehicles.has(vehicle_id):
		return []
	
	return vehicles[vehicle_id].upgrades.duplicate()

# =============================================================================
# VEHICLE COMBAT
# =============================================================================

func has_weapon(vehicle_id: int) -> bool:
	"""Verifica se um veículo tem arma"""
	if not vehicles.has(vehicle_id):
		return false
	
	var vehicle = vehicles[vehicle_id]
	return vehicle.customizations.get("has_weapon", false)

func get_weapon_damage(vehicle_id: int) -> float:
	"""Obtém o dano da arma do veículo"""
	if not vehicles.has(vehicle_id):
		return 0.0
	
	var vehicle = vehicles[vehicle_id]
	return vehicle.customizations.get("weapon_damage", 0.0)

func fire_weapon(vehicle_id: int, target_position: Vector2i) -> bool:
	"""Dispara a arma de um veículo"""
	if not has_weapon(vehicle_id):
		return false
	
	var vehicle = vehicles[vehicle_id]
	var damage = get_weapon_damage(vehicle_id)
	
	if event_bus:
		event_bus.vehicle_fired.emit(vehicle_id, target_position, damage)
	
	return true

# =============================================================================
# STATISTICS AND QUERIES
# =============================================================================

func get_vehicle_count() -> int:
	"""Obtém o número total de veículos"""
	return vehicles.size()

func get_all_vehicles() -> Array[VehicleData]:
	"""Obtém todos os veículos"""
	return vehicles.values()

func get_vehicle_stats(vehicle_id: int) -> Dictionary:
	"""Obtém estatísticas de um veículo"""
	if not vehicles.has(vehicle_id):
		return {}
	
	var vehicle = vehicles[vehicle_id]
	return {
		"id": vehicle.id,
		"type": vehicle.type,
		"position": vehicle.position,
		"fuel": vehicle.fuel,
		"max_fuel": vehicle.max_fuel,
		"fuel_percentage": get_fuel_percentage(vehicle_id),
		"cargo": vehicle.cargo,
		"max_cargo": vehicle.max_cargo,
		"cargo_percentage": get_cargo_percentage(vehicle_id),
		"health": vehicle.health,
		"max_health": vehicle.max_health,
		"condition": vehicle.condition,
		"passengers": vehicle.passengers,
		"max_passengers": vehicle.max_passengers,
		"speed": vehicle.speed,
		"is_operational": is_operational(vehicle_id),
		"is_moving": vehicle.is_moving,
		"upgrades": vehicle.upgrades.duplicate(),
		"owner_faction": vehicle.owner_faction
	}

# =============================================================================
# SERIALIZATION
# =============================================================================

func serialize() -> Dictionary:
	"""Serializa o estado do sistema de veículos"""
	var vehicle_data: Array[Dictionary] = []
	
	for vehicle in vehicles.values():
		vehicle_data.append({
			"id": vehicle.id,
			"type": vehicle.type,
			"position": vehicle.position,
			"fuel": vehicle.fuel,
			"cargo": vehicle.cargo,
			"health": vehicle.health,
			"condition": vehicle.condition,
			"passengers": vehicle.passengers,
			"owner_faction": vehicle.owner_faction,
			"upgrades": vehicle.upgrades.duplicate(),
			"customizations": vehicle.customizations.duplicate(),
			"is_moving": vehicle.is_moving
		})
	
	return {
		"vehicles": vehicle_data,
		"next_vehicle_id": next_vehicle_id
	}

func deserialize(data: Dictionary) -> void:
	"""Desserializa o estado do sistema de veículos"""
	vehicles.clear()
	next_vehicle_id = data.get("next_vehicle_id", 0)
	
	for vehicle_data in data.get("vehicles", []):
		var vehicle = VehicleData.new(
			vehicle_data["id"],
			vehicle_data["type"],
			vehicle_data["position"]
		)
		
		vehicle.fuel = vehicle_data.get("fuel", vehicle.max_fuel * 0.5)
		vehicle.cargo = vehicle_data.get("cargo", 0.0)
		vehicle.health = vehicle_data.get("health", vehicle.max_health)
		vehicle.condition = vehicle_data.get("condition", 100.0)
		vehicle.passengers = vehicle_data.get("passengers", 0)
		vehicle.owner_faction = vehicle_data.get("owner_faction", -1)
		vehicle.upgrades = vehicle_data.get("upgrades", [])
		vehicle.customizations = vehicle_data.get("customizations", {})
		vehicle.is_moving = vehicle_data.get("is_moving", false)
		
		vehicles[vehicle.id] = vehicle
