## PowerSystem - Sistema de eletricidade
## Gerencia geração, distribuição e consumo de energia
class_name PowerSystem
extends Node

# Classe para fonte de energia
class PowerSource:
	var id: int
	var building_id: int
	var position: Vector2i
	var output: float  # Watts gerados
	var is_active: bool = true
	var efficiency: float = 1.0  # 0-1
	
	func _init(p_id: int, p_building_id: int, p_pos: Vector2i, p_output: float) -> void:
		id = p_id
		building_id = p_building_id
		position = p_pos
		output = p_output
	
	func get_actual_output() -> float:
		if not is_active:
			return 0.0
		return output * efficiency

# Classe para consumidor de energia
class PowerConsumer:
	var id: int
	var building_id: int
	var position: Vector2i
	var demand: float  # Watts necessários
	var is_connected: bool = false
	var priority: int = 0  # 0 = baixa, 1 = média, 2 = alta
	
	func _init(p_id: int, p_building_id: int, p_pos: Vector2i, p_demand: float) -> void:
		id = p_id
		building_id = p_building_id
		position = p_pos
		demand = p_demand

# Classe para conduto de energia
class PowerConduit:
	var from: Vector2i
	var to: Vector2i
	var capacity: float = 1000.0  # Watts máximos
	var is_active: bool = true
	
	func _init(p_from: Vector2i, p_to: Vector2i) -> void:
		from = p_from
		to = p_to

# Armazenamento
var _power_sources: Dictionary = {}  # int (id) -> PowerSource
var _power_consumers: Dictionary = {}  # int (id) -> PowerConsumer
var _conduits: Array[PowerConduit] = []
var _power_grid: Dictionary = {}  # Vector2i -> Array[Vector2i] (grafo de conexões)
var _next_source_id: int = 0
var _next_consumer_id: int = 0

# Estatísticas
var total_generation: float = 0.0
var total_demand: float = 0.0
var total_supplied: float = 0.0
var power_deficit: float = 0.0
var grid_efficiency: float = 1.0

# Configuração
const DEFAULT_CONNECTION_RANGE: float = 5.0
const CONDUIT_RANGE: float = 10.0

var grid_system
var building_system
var event_bus
var config

func _ready() -> void:
	pass

func set_config(cfg) -> void:
	config = cfg
	if config == null:
		config = CityConfig.new()

func set_systems(grid, buildings, bus) -> void:
	"""Define as referências aos sistemas"""
	grid_system = grid
	building_system = buildings
	event_bus = bus

func add_power_source(building_id: int, position: Vector2i, output: float) -> int:
	"""Adiciona uma fonte de energia"""
	var source = PowerSource.new(_next_source_id, building_id, position, output)
	_next_source_id += 1
	
	_power_sources[source.id] = source
	
	# Adicionar ao grafo
	if not _power_grid.has(position):
		_power_grid[position] = []
	
	# Emitir evento
	if event_bus != null:
		event_bus.power_source_added.emit(source.id, output)
	
	_update_grid()
	return source.id

func remove_power_source(source_id: int) -> bool:
	"""Remove uma fonte de energia"""
	if not _power_sources.has(source_id):
		return false
	
	var source = _power_sources[source_id]
	_power_sources.erase(source_id)
	
	# Emitir evento
	if event_bus != null:
		event_bus.power_source_removed.emit(source_id)
	
	_update_grid()
	return true

func add_power_consumer(building_id: int, position: Vector2i, demand: float, priority: int = 0) -> int:
	"""Adiciona um consumidor de energia"""
	var consumer = PowerConsumer.new(_next_consumer_id, building_id, position, demand)
	consumer.priority = priority
	_next_consumer_id += 1
	
	_power_consumers[consumer.id] = consumer
	
	# Adicionar ao grafo
	if not _power_grid.has(position):
		_power_grid[position] = []
	
	# Emitir evento
	if event_bus != null:
		event_bus.power_consumer_added.emit(consumer.id, demand)
	
	_update_grid()
	return consumer.id

func remove_power_consumer(consumer_id: int) -> bool:
	"""Remove um consumidor de energia"""
	if not _power_consumers.has(consumer_id):
		return false
	
	var consumer = _power_consumers[consumer_id]
	_power_consumers.erase(consumer_id)
	
	# Emitir evento
	if event_bus != null:
		event_bus.power_consumer_removed.emit(consumer_id)
	
	_update_grid()
	return true

func place_conduit(from: Vector2i, to: Vector2i) -> bool:
	"""Coloca um conduto de energia entre dois pontos"""
	# Verificar se a distância é válida
	var distance = from.distance_to(to)
	if distance > CONDUIT_RANGE:
		return false
	
	var conduit = PowerConduit.new(from, to)
	_conduits.append(conduit)
	
	# Adicionar conexão ao grafo
	if not _power_grid.has(from):
		_power_grid[from] = []
	if not _power_grid.has(to):
		_power_grid[to] = []
	
	if to not in _power_grid[from]:
		_power_grid[from].append(to)
	if from not in _power_grid[to]:
		_power_grid[to].append(from)
	
	# Emitir evento
	if event_bus != null:
		event_bus.conduit_placed.emit(from, to)
	
	_update_grid()
	return true

func remove_conduit(from: Vector2i, to: Vector2i) -> bool:
	"""Remove um conduto de energia"""
	var found = false
	for i in range(_conduits.size() - 1, -1, -1):
		var conduit = _conduits[i]
		if (conduit.from == from and conduit.to == to) or (conduit.from == to and conduit.to == from):
			_conduits.remove_at(i)
			found = true
	
	if found:
		# Remover conexão do grafo
		if _power_grid.has(from):
			_power_grid[from].erase(to)
		if _power_grid.has(to):
			_power_grid[to].erase(from)
		
		# Emitir evento
		if event_bus != null:
			event_bus.conduit_removed.emit(from, to)
		
		_update_grid()
	
	return found

func _update_grid() -> void:
	"""Atualiza o estado da rede elétrica"""
	# Calcular geração total
	total_generation = 0.0
	for source in _power_sources.values():
		total_generation += source.get_actual_output()
	
	# Calcular demanda total
	total_demand = 0.0
	for consumer in _power_consumers.values():
		total_demand += consumer.demand
	
	# Verificar conexões e distribuir energia
	_update_connections()
	
	# Calcular déficit
	power_deficit = max(0.0, total_demand - total_generation)
	
	# Calcular energia fornecida
	total_supplied = min(total_generation, total_demand)
	
	# Emitir evento
	if event_bus != null:
		event_bus.power_grid_updated.emit(total_generation, total_demand)
		
		if power_deficit > 0.0:
			event_bus.power_shortage.emit(power_deficit)
		elif power_deficit == 0.0 and total_demand > 0.0:
			event_bus.power_restored.emit()

func _update_connections() -> void:
	"""Atualiza as conexões entre fontes e consumidores"""
	# Resetar conexões
	for consumer in _power_consumers.values():
		consumer.is_connected = false
	
	# Para cada consumidor, verificar se há caminho para alguma fonte
	for consumer in _power_consumers.values():
		for source in _power_sources.values():
			if _has_path_to_source(consumer.position, source.position):
				consumer.is_connected = true
				break

func _has_path_to_source(from: Vector2i, to: Vector2i) -> bool:
	"""Verifica se há um caminho válido entre dois pontos na rede"""
	# Verificar conexão direta (dentro do alcance)
	var distance = from.distance_to(to)
	if distance <= DEFAULT_CONNECTION_RANGE:
		return true
	
	# BFS para encontrar caminho através de condutos
	var visited: Dictionary = {}
	var queue: Array = [from]
	visited[from] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		# Verificar se chegamos ao destino
		if current.distance_to(to) <= DEFAULT_CONNECTION_RANGE:
			return true
		
		# Explorar vizinhos
		if _power_grid.has(current):
			for neighbor in _power_grid[current]:
				if not visited.has(neighbor):
					visited[neighbor] = true
					queue.append(neighbor)
	
	return false

func is_building_powered(building_id: int) -> bool:
	"""Verifica se um edifício está recebendo energia"""
	for consumer in _power_consumers.values():
		if consumer.building_id == building_id:
			return consumer.is_connected and power_deficit == 0.0
	return false

func get_building_power_status(building_id: int) -> Dictionary:
	"""Retorna o status de energia de um edifício"""
	var status = {
		"is_powered": false,
		"is_connected": false,
		"demand": 0.0,
		"supplied": 0.0,
		"power_ratio": 0.0  # 0-1, quanto da demanda está sendo atendida
	}
	
	for consumer in _power_consumers.values():
		if consumer.building_id == building_id:
			status["is_connected"] = consumer.is_connected
			status["demand"] = consumer.demand
			
			if consumer.is_connected and power_deficit == 0.0:
				status["is_powered"] = true
				status["supplied"] = consumer.demand
				status["power_ratio"] = 1.0
			elif consumer.is_connected and power_deficit > 0.0:
				# Distribuir energia proporcionalmente
				var ratio = total_generation / total_demand if total_demand > 0.0 else 0.0
				status["supplied"] = consumer.demand * ratio
				status["power_ratio"] = ratio
				# Considerar "powered" se receber pelo menos 50% da demanda
				status["is_powered"] = ratio >= 0.5
			
			break
	
	return status

func apply_power_shortage_effects() -> void:
	"""Aplica efeitos de falta de energia aos edifícios"""
	if building_system == null:
		return
	
	# Para cada consumidor
	for consumer in _power_consumers.values():
		if consumer.building_id < 0:
			continue
		
		var building = building_system.get_building(consumer.building_id)
		if building == null:
			continue
		
		# Calcular quanto de energia está recebendo
		var power_ratio = 0.0
		if consumer.is_connected:
			if power_deficit == 0.0:
				power_ratio = 1.0
			else:
				power_ratio = total_generation / total_demand if total_demand > 0.0 else 0.0
		
		# Aplicar efeitos baseados na prioridade e ratio
		if power_ratio < 0.5:
			# Energia crítica - edifício não operacional
			building_system.set_building_operational(consumer.building_id, false)
		elif power_ratio < 0.8:
			# Energia baixa - reduzir eficiência
			if building.metadata.has("power_efficiency"):
				building.metadata["power_efficiency"] = power_ratio
			else:
				building.metadata["power_efficiency"] = power_ratio
			building_system.set_building_operational(consumer.building_id, true)
		else:
			# Energia suficiente - operação normal
			if building.metadata.has("power_efficiency"):
				building.metadata["power_efficiency"] = 1.0
			else:
				building.metadata["power_efficiency"] = 1.0
			building_system.set_building_operational(consumer.building_id, true)

func get_power_efficiency(building_id: int) -> float:
	"""Retorna a eficiência de energia de um edifício (0-1)"""
	if building_system == null:
		return 1.0
	
	var building = building_system.get_building(building_id)
	if building == null:
		return 1.0
	
	if building.metadata.has("power_efficiency"):
		return building.metadata["power_efficiency"]
	
	return 1.0

func set_consumer_priority(consumer_id: int, priority: int) -> bool:
	"""Define a prioridade de um consumidor (0=baixa, 1=média, 2=alta)"""
	if not _power_consumers.has(consumer_id):
		return false
	
	_power_consumers[consumer_id].priority = clamp(priority, 0, 2)
	return true

func distribute_power_by_priority() -> void:
	"""Distribui energia priorizando consumidores de alta prioridade"""
	if power_deficit <= 0.0:
		return
	
	# Separar consumidores por prioridade
	var high_priority: Array = []
	var medium_priority: Array = []
	var low_priority: Array = []
	
	for consumer in _power_consumers.values():
		if not consumer.is_connected:
			continue
		
		match consumer.priority:
			2:
				high_priority.append(consumer)
			1:
				medium_priority.append(consumer)
			0:
				low_priority.append(consumer)
	
	# Calcular demandas por prioridade
	var high_demand = 0.0
	var medium_demand = 0.0
	var low_demand = 0.0
	
	for c in high_priority:
		high_demand += c.demand
	for c in medium_priority:
		medium_demand += c.demand
	for c in low_priority:
		low_demand += c.demand
	
	# Distribuir energia disponível
	var remaining_power = total_generation
	
	# Primeiro, atender alta prioridade
	if high_demand > 0.0:
		var allocated = min(remaining_power, high_demand)
		remaining_power -= allocated
	
	# Depois, média prioridade
	if medium_demand > 0.0 and remaining_power > 0.0:
		var allocated = min(remaining_power, medium_demand)
		remaining_power -= allocated
	
	# Por último, baixa prioridade
	# (remaining_power é o que sobra)

func get_shortage_report() -> Dictionary:
	"""Retorna relatório detalhado de falta de energia"""
	var report = {
		"has_shortage": power_deficit > 0.0,
		"deficit": power_deficit,
		"deficit_percentage": 0.0,
		"affected_buildings": [],
		"critical_buildings": [],
		"total_affected": 0
	}
	
	if total_demand > 0.0:
		report["deficit_percentage"] = (power_deficit / total_demand) * 100.0
	
	# Identificar edifícios afetados
	for consumer in _power_consumers.values():
		if consumer.building_id < 0:
			continue
		
		if not consumer.is_connected:
			report["critical_buildings"].append(consumer.building_id)
			report["total_affected"] += 1
		elif power_deficit > 0.0:
			var ratio = total_generation / total_demand if total_demand > 0.0 else 0.0
			if ratio < 0.5:
				report["critical_buildings"].append(consumer.building_id)
			else:
				report["affected_buildings"].append(consumer.building_id)
			report["total_affected"] += 1
	
	return report

func get_power_statistics() -> Dictionary:
	"""Retorna estatísticas da rede elétrica"""
	var connected_consumers = 0
	var powered_consumers = 0
	
	for consumer in _power_consumers.values():
		if consumer.is_connected:
			connected_consumers += 1
			if power_deficit == 0.0:
				powered_consumers += 1
	
	return {
		"total_generation": total_generation,
		"total_demand": total_demand,
		"total_supplied": total_supplied,
		"power_deficit": power_deficit,
		"grid_efficiency": grid_efficiency,
		"source_count": _power_sources.size(),
		"consumer_count": _power_consumers.size(),
		"connected_consumers": connected_consumers,
		"powered_consumers": powered_consumers,
		"conduit_count": _conduits.size()
	}

func get_power_sources() -> Array:
	"""Retorna todas as fontes de energia"""
	return _power_sources.values()

func get_power_consumers() -> Array:
	"""Retorna todos os consumidores de energia"""
	return _power_consumers.values()

func get_conduits() -> Array:
	"""Retorna todos os condutos"""
	return _conduits.duplicate()

func set_source_active(source_id: int, active: bool) -> bool:
	"""Define se uma fonte está ativa"""
	if not _power_sources.has(source_id):
		return false
	
	_power_sources[source_id].is_active = active
	_update_grid()
	return true

func set_source_efficiency(source_id: int, efficiency: float) -> bool:
	"""Define a eficiência de uma fonte"""
	if not _power_sources.has(source_id):
		return false
	
	_power_sources[source_id].efficiency = clamp(efficiency, 0.0, 1.0)
	_update_grid()
	return true

func get_nearest_power_source(position: Vector2i) -> int:
	"""Retorna o ID da fonte de energia mais próxima"""
	var nearest_id = -1
	var nearest_distance = INF
	
	for source in _power_sources.values():
		var distance = position.distance_to(source.position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_id = source.id
	
	return nearest_id

func get_connection_range() -> float:
	"""Retorna o alcance de conexão padrão"""
	return DEFAULT_CONNECTION_RANGE

func get_conduit_range() -> float:
	"""Retorna o alcance máximo de um conduto"""
	return CONDUIT_RANGE

func can_connect(from: Vector2i, to: Vector2i) -> bool:
	"""Verifica se dois pontos podem ser conectados"""
	var distance = from.distance_to(to)
	return distance <= CONDUIT_RANGE

func get_connected_nodes(position: Vector2i) -> Array:
	"""Retorna todos os nós conectados a uma posição"""
	if not _power_grid.has(position):
		return []
	return _power_grid[position].duplicate()

func is_position_in_grid(position: Vector2i) -> bool:
	"""Verifica se uma posição faz parte da rede"""
	return _power_grid.has(position)

func get_power_coverage_area(source_position: Vector2i) -> Array:
	"""Retorna todas as posições cobertas por uma fonte de energia"""
	var covered: Array = []
	var visited: Dictionary = {}
	var queue: Array = [source_position]
	visited[source_position] = true
	covered.append(source_position)
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		# Explorar vizinhos
		if _power_grid.has(current):
			for neighbor in _power_grid[current]:
				if not visited.has(neighbor):
					visited[neighbor] = true
					covered.append(neighbor)
					queue.append(neighbor)
	
	return covered

func get_network_segments() -> Array:
	"""Retorna os segmentos isolados da rede"""
	var segments: Array = []
	var visited: Dictionary = {}
	
	# Para cada nó no grafo
	for node in _power_grid.keys():
		if not visited.has(node):
			# BFS para encontrar todos os nós conectados
			var segment: Array = []
			var queue: Array = [node]
			visited[node] = true
			
			while queue.size() > 0:
				var current = queue.pop_front()
				segment.append(current)
				
				if _power_grid.has(current):
					for neighbor in _power_grid[current]:
						if not visited.has(neighbor):
							visited[neighbor] = true
							queue.append(neighbor)
			
			segments.append(segment)
	
	return segments

func optimize_connections() -> void:
	"""Otimiza as conexões da rede removendo redundâncias"""
	# Esta é uma implementação básica que pode ser expandida
	_update_grid()

func clear() -> void:
	"""Limpa todos os dados do sistema"""
	_power_sources.clear()
	_power_consumers.clear()
	_conduits.clear()
	_power_grid.clear()
	_next_source_id = 0
	_next_consumer_id = 0
	total_generation = 0.0
	total_demand = 0.0
	total_supplied = 0.0
	power_deficit = 0.0
