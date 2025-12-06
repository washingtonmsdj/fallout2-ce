## WaterSystem - Sistema de água
## Gerencia fontes, distribuição e consumo de água
class_name WaterSystem
extends Node

# Enum para qualidade da água
enum WaterQuality {
	DIRTY,      # Água suja - causa problemas de saúde
	CLEAN,      # Água limpa - uso básico
	PURIFIED    # Água purificada - ideal para consumo
}

# Enum para tipos de fonte
enum SourceType {
	WELL,           # Poço
	PURIFIER,       # Purificador
	RIVER,          # Rio
	WATER_TOWER,    # Torre d'água
	TREATMENT_PLANT # Estação de tratamento
}

# Classe para fonte de água
class WaterSource:
	var id: int
	var building_id: int
	var position: Vector2i
	var source_type: int  # SourceType
	var output: float  # Litros por hora
	var quality: int  # WaterQuality
	var is_active: bool = true
	var contamination_level: float = 0.0  # 0-100
	
	func _init(p_id: int, p_building_id: int, p_pos: Vector2i, p_type: int, p_output: float, p_quality: int) -> void:
		id = p_id
		building_id = p_building_id
		position = p_pos
		source_type = p_type
		output = p_output
		quality = p_quality
	
	func get_actual_output() -> float:
		if not is_active:
			return 0.0
		# Contaminação reduz output
		var contamination_penalty = 1.0 - (contamination_level / 100.0) * 0.5
		return output * contamination_penalty
	
	func get_effective_quality() -> int:
		# Contaminação degrada qualidade
		if contamination_level > 70.0:
			return WaterQuality.DIRTY
		elif contamination_level > 30.0 and quality == WaterQuality.PURIFIED:
			return WaterQuality.CLEAN
		return quality

# Classe para consumidor de água
class WaterConsumer:
	var id: int
	var building_id: int
	var position: Vector2i
	var demand: float  # Litros por hora
	var is_connected: bool = false
	var priority: int = 0  # 0 = baixa, 1 = média, 2 = alta
	var min_quality: int = WaterQuality.DIRTY  # Qualidade mínima aceitável
	
	func _init(p_id: int, p_building_id: int, p_pos: Vector2i, p_demand: float) -> void:
		id = p_id
		building_id = p_building_id
		position = p_pos
		demand = p_demand

# Classe para tubulação
class WaterPipe:
	var from: Vector2i
	var to: Vector2i
	var capacity: float = 1000.0  # Litros por hora
	var is_active: bool = true
	var leak_rate: float = 0.0  # 0-1, percentual de perda
	
	func _init(p_from: Vector2i, p_to: Vector2i) -> void:
		from = p_from
		to = p_to
	
	func get_effective_capacity() -> float:
		if not is_active:
			return 0.0
		return capacity * (1.0 - leak_rate)

# Armazenamento
var _water_sources: Dictionary = {}  # int (id) -> WaterSource
var _water_consumers: Dictionary = {}  # int (id) -> WaterConsumer
var _pipes: Array[WaterPipe] = []
var _water_network: Dictionary = {}  # Vector2i -> Array[Vector2i] (grafo de conexões)
var _next_source_id: int = 0
var _next_consumer_id: int = 0

# Estatísticas
var total_production: float = 0.0
var total_demand: float = 0.0
var total_supplied: float = 0.0
var water_deficit: float = 0.0
var average_quality: float = 0.0  # 0-2 (DIRTY-PURIFIED)

# Configuração
const DEFAULT_CONNECTION_RANGE: float = 5.0
const PIPE_RANGE: float = 10.0

var grid_system
var building_system
var citizen_system
var event_bus
var config

func _ready() -> void:
	pass

func set_config(cfg) -> void:
	config = cfg
	if config == null:
		config = CityConfig.new()

func set_systems(grid, buildings, citizens, bus) -> void:
	"""Define as referências aos sistemas"""
	grid_system = grid
	building_system = buildings
	citizen_system = citizens
	event_bus = bus

func add_water_source(building_id: int, position: Vector2i, source_type: int, output: float, quality: int) -> int:
	"""Adiciona uma fonte de água"""
	var source = WaterSource.new(_next_source_id, building_id, position, source_type, output, quality)
	_next_source_id += 1
	
	_water_sources[source.id] = source
	
	# Adicionar ao grafo
	if not _water_network.has(position):
		_water_network[position] = []
	
	# Emitir evento
	if event_bus != null:
		event_bus.water_source_added.emit(source.id, output, quality)
	
	_update_network()
	return source.id

func remove_water_source(source_id: int) -> bool:
	"""Remove uma fonte de água"""
	if not _water_sources.has(source_id):
		return false
	
	var source = _water_sources[source_id]
	_water_sources.erase(source_id)
	
	# Emitir evento
	if event_bus != null:
		event_bus.water_source_removed.emit(source_id)
	
	_update_network()
	return true

func add_water_consumer(building_id: int, position: Vector2i, demand: float, min_quality: int = WaterQuality.DIRTY, priority: int = 0) -> int:
	"""Adiciona um consumidor de água"""
	var consumer = WaterConsumer.new(_next_consumer_id, building_id, position, demand)
	consumer.min_quality = min_quality
	consumer.priority = priority
	_next_consumer_id += 1
	
	_water_consumers[consumer.id] = consumer
	
	# Adicionar ao grafo
	if not _water_network.has(position):
		_water_network[position] = []
	
	# Emitir evento
	if event_bus != null:
		event_bus.water_consumer_added.emit(consumer.id, demand)
	
	_update_network()
	return consumer.id

func remove_water_consumer(consumer_id: int) -> bool:
	"""Remove um consumidor de água"""
	if not _water_consumers.has(consumer_id):
		return false
	
	var consumer = _water_consumers[consumer_id]
	_water_consumers.erase(consumer_id)
	
	# Emitir evento
	if event_bus != null:
		event_bus.water_consumer_removed.emit(consumer_id)
	
	_update_network()
	return true

func place_pipe(from: Vector2i, to: Vector2i) -> bool:
	"""Coloca uma tubulação entre dois pontos"""
	# Verificar se a distância é válida
	var distance = from.distance_to(to)
	if distance > PIPE_RANGE:
		return false
	
	var pipe = WaterPipe.new(from, to)
	_pipes.append(pipe)
	
	# Adicionar conexão ao grafo
	if not _water_network.has(from):
		_water_network[from] = []
	if not _water_network.has(to):
		_water_network[to] = []
	
	if to not in _water_network[from]:
		_water_network[from].append(to)
	if from not in _water_network[to]:
		_water_network[to].append(from)
	
	# Emitir evento
	if event_bus != null:
		event_bus.pipe_placed.emit(from, to)
	
	_update_network()
	return true

func remove_pipe(from: Vector2i, to: Vector2i) -> bool:
	"""Remove uma tubulação"""
	var found = false
	for i in range(_pipes.size() - 1, -1, -1):
		var pipe = _pipes[i]
		if (pipe.from == from and pipe.to == to) or (pipe.from == to and pipe.to == from):
			_pipes.remove_at(i)
			found = true
	
	if found:
		# Remover conexão do grafo
		if _water_network.has(from):
			_water_network[from].erase(to)
		if _water_network.has(to):
			_water_network[to].erase(from)
		
		# Emitir evento
		if event_bus != null:
			event_bus.pipe_removed.emit(from, to)
		
		_update_network()
	
	return found

func _update_network() -> void:
	"""Atualiza o estado da rede de água"""
	# Calcular produção total
	total_production = 0.0
	var quality_sum = 0.0
	var active_sources = 0
	
	for source in _water_sources.values():
		var output = source.get_actual_output()
		total_production += output
		if output > 0.0:
			quality_sum += source.get_effective_quality()
			active_sources += 1
	
	# Calcular qualidade média
	if active_sources > 0:
		average_quality = quality_sum / active_sources
	else:
		average_quality = 0.0
	
	# Calcular demanda total
	total_demand = 0.0
	for consumer in _water_consumers.values():
		total_demand += consumer.demand
	
	# Verificar conexões e distribuir água
	_update_connections()
	
	# Calcular déficit
	water_deficit = max(0.0, total_demand - total_production)
	
	# Calcular água fornecida
	total_supplied = min(total_production, total_demand)
	
	# Emitir evento
	if event_bus != null:
		event_bus.water_grid_updated.emit(total_production, total_demand)
		
		if water_deficit > 0.0:
			event_bus.water_shortage.emit(water_deficit)
		elif water_deficit == 0.0 and total_demand > 0.0:
			event_bus.water_restored.emit()

func _update_connections() -> void:
	"""Atualiza as conexões entre fontes e consumidores"""
	# Resetar conexões
	for consumer in _water_consumers.values():
		consumer.is_connected = false
	
	# Para cada consumidor, verificar se há caminho para alguma fonte
	for consumer in _water_consumers.values():
		for source in _water_sources.values():
			if _has_path_to_source(consumer.position, source.position):
				# Verificar se a qualidade é adequada
				if source.get_effective_quality() >= consumer.min_quality:
					consumer.is_connected = true
					break

func _has_path_to_source(from: Vector2i, to: Vector2i) -> bool:
	"""Verifica se há um caminho válido entre dois pontos na rede"""
	# Verificar conexão direta (dentro do alcance)
	var distance = from.distance_to(to)
	if distance <= DEFAULT_CONNECTION_RANGE:
		return true
	
	# BFS para encontrar caminho através de tubulações
	var visited: Dictionary = {}
	var queue: Array = [from]
	visited[from] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		# Verificar se chegamos ao destino
		if current.distance_to(to) <= DEFAULT_CONNECTION_RANGE:
			return true
		
		# Explorar vizinhos
		if _water_network.has(current):
			for neighbor in _water_network[current]:
				if not visited.has(neighbor):
					visited[neighbor] = true
					queue.append(neighbor)
	
	return false

func contaminate_source(source_id: int, level: float) -> bool:
	"""Contamina uma fonte de água"""
	if not _water_sources.has(source_id):
		return false
	
	var source = _water_sources[source_id]
	source.contamination_level = clamp(source.contamination_level + level, 0.0, 100.0)
	
	# Emitir evento
	if event_bus != null:
		event_bus.water_contaminated.emit(source_id, source.contamination_level)
	
	_update_network()
	return true

func purify_source(source_id: int, amount: float) -> bool:
	"""Purifica uma fonte de água"""
	if not _water_sources.has(source_id):
		return false
	
	var source = _water_sources[source_id]
	source.contamination_level = clamp(source.contamination_level - amount, 0.0, 100.0)
	
	# Emitir evento
	if event_bus != null:
		event_bus.water_purified.emit(source_id)
	
	_update_network()
	return true

func is_building_supplied(building_id: int) -> bool:
	"""Verifica se um edifício está recebendo água"""
	for consumer in _water_consumers.values():
		if consumer.building_id == building_id:
			return consumer.is_connected and water_deficit == 0.0
	return false

func get_building_water_status(building_id: int) -> Dictionary:
	"""Retorna o status de água de um edifício"""
	var status = {
		"is_supplied": false,
		"is_connected": false,
		"demand": 0.0,
		"supplied": 0.0,
		"quality": WaterQuality.DIRTY,
		"water_ratio": 0.0
	}
	
	for consumer in _water_consumers.values():
		if consumer.building_id == building_id:
			status["is_connected"] = consumer.is_connected
			status["demand"] = consumer.demand
			
			if consumer.is_connected:
				# Encontrar fonte conectada para determinar qualidade
				for source in _water_sources.values():
					if _has_path_to_source(consumer.position, source.position):
						status["quality"] = source.get_effective_quality()
						break
				
				if water_deficit == 0.0:
					status["is_supplied"] = true
					status["supplied"] = consumer.demand
					status["water_ratio"] = 1.0
				elif water_deficit > 0.0:
					# Distribuir água proporcionalmente
					var ratio = total_production / total_demand if total_demand > 0.0 else 0.0
					status["supplied"] = consumer.demand * ratio
					status["water_ratio"] = ratio
					status["is_supplied"] = ratio >= 0.5
			
			break
	
	return status

func apply_water_shortage_effects() -> void:
	"""Aplica efeitos de falta de água aos edifícios e cidadãos"""
	if building_system == null:
		return
	
	# Para cada consumidor
	for consumer in _water_consumers.values():
		if consumer.building_id < 0:
			continue
		
		var building = building_system.get_building(consumer.building_id)
		if building == null:
			continue
		
		# Calcular quanto de água está recebendo
		var water_ratio = 0.0
		var water_quality = WaterQuality.DIRTY
		
		if consumer.is_connected:
			# Encontrar qualidade da água
			for source in _water_sources.values():
				if _has_path_to_source(consumer.position, source.position):
					water_quality = source.get_effective_quality()
					break
			
			if water_deficit == 0.0:
				water_ratio = 1.0
			else:
				water_ratio = total_production / total_demand if total_demand > 0.0 else 0.0
		
		# Aplicar efeitos baseados no ratio e qualidade
		if water_ratio < 0.3:
			# Água crítica - edifício não operacional
			building_system.set_building_operational(consumer.building_id, false)
		elif water_ratio < 0.7:
			# Água baixa - reduzir eficiência
			building.metadata["water_efficiency"] = water_ratio
			building_system.set_building_operational(consumer.building_id, true)
		else:
			# Água suficiente - operação normal
			building.metadata["water_efficiency"] = 1.0
			building_system.set_building_operational(consumer.building_id, true)
		
		# Armazenar qualidade da água
		building.metadata["water_quality"] = water_quality
		
		# Aplicar efeitos de saúde aos cidadãos se água contaminada
		if water_quality == WaterQuality.DIRTY and citizen_system != null:
			_apply_contamination_effects(consumer.building_id)

func _apply_contamination_effects(building_id: int) -> void:
	"""Aplica efeitos de contaminação aos cidadãos em um edifício"""
	if citizen_system == null or building_system == null:
		return
	
	var building = building_system.get_building(building_id)
	if building == null:
		return
	
	# Obter ocupantes do edifício
	var occupants = building_system.get_occupants(building_id)
	
	for citizen_id in occupants:
		var citizen = citizen_system.get_citizen(citizen_id)
		if citizen != null:
			# Reduzir saúde gradualmente
			citizen_system.update_citizen_need(citizen_id, CityConfig.NeedType.HEALTH, -0.5)

func get_water_quality_at(position: Vector2i) -> int:
	"""Retorna a qualidade da água em uma posição"""
	# Encontrar a fonte mais próxima conectada
	var best_quality = WaterQuality.DIRTY
	
	for source in _water_sources.values():
		if _has_path_to_source(position, source.position):
			var quality = source.get_effective_quality()
			if quality > best_quality:
				best_quality = quality
	
	return best_quality

func upgrade_source_quality(source_id: int, new_quality: int) -> bool:
	"""Melhora a qualidade de uma fonte de água"""
	if not _water_sources.has(source_id):
		return false
	
	var source = _water_sources[source_id]
	
	# Só pode melhorar, não piorar
	if new_quality > source.quality:
		source.quality = new_quality
		_update_network()
		return true
	
	return false

func get_contamination_level(source_id: int) -> float:
	"""Retorna o nível de contaminação de uma fonte"""
	if not _water_sources.has(source_id):
		return 0.0
	
	return _water_sources[source_id].contamination_level

func get_contaminated_sources() -> Array:
	"""Retorna todas as fontes contaminadas"""
	var contaminated: Array = []
	
	for source in _water_sources.values():
		if source.contamination_level > 0.0:
			contaminated.append(source)
	
	return contaminated

func get_quality_distribution() -> Dictionary:
	"""Retorna a distribuição de qualidade das fontes"""
	var distribution = {
		WaterQuality.DIRTY: 0,
		WaterQuality.CLEAN: 0,
		WaterQuality.PURIFIED: 0
	}
	
	for source in _water_sources.values():
		var quality = source.get_effective_quality()
		distribution[quality] += 1
	
	return distribution

func calculate_health_impact() -> Dictionary:
	"""Calcula o impacto na saúde da população"""
	var impact = {
		"affected_citizens": 0,
		"health_loss_rate": 0.0,
		"contaminated_buildings": []
	}
	
	if building_system == null or citizen_system == null:
		return impact
	
	# Para cada consumidor
	for consumer in _water_consumers.values():
		if consumer.building_id < 0 or not consumer.is_connected:
			continue
		
		# Verificar qualidade da água
		var water_quality = WaterQuality.DIRTY
		for source in _water_sources.values():
			if _has_path_to_source(consumer.position, source.position):
				water_quality = source.get_effective_quality()
				break
		
		# Se água suja, contar cidadãos afetados
		if water_quality == WaterQuality.DIRTY:
			var occupants = building_system.get_occupants(consumer.building_id)
			impact["affected_citizens"] += occupants.size()
			impact["contaminated_buildings"].append(consumer.building_id)
			
			# Taxa de perda de saúde baseada na qualidade
			impact["health_loss_rate"] += 0.5 * occupants.size()
	
	return impact

func set_consumer_min_quality(consumer_id: int, min_quality: int) -> bool:
	"""Define a qualidade mínima aceitável para um consumidor"""
	if not _water_consumers.has(consumer_id):
		return false
	
	_water_consumers[consumer_id].min_quality = clamp(min_quality, WaterQuality.DIRTY, WaterQuality.PURIFIED)
	_update_network()
	return true

func get_quality_name(quality: int) -> String:
	"""Retorna o nome da qualidade da água"""
	match quality:
		WaterQuality.DIRTY:
			return "Suja"
		WaterQuality.CLEAN:
			return "Limpa"
		WaterQuality.PURIFIED:
			return "Purificada"
		_:
			return "Desconhecida"

func get_water_statistics() -> Dictionary:
	"""Retorna estatísticas da rede de água"""
	var connected_consumers = 0
	var supplied_consumers = 0
	
	for consumer in _water_consumers.values():
		if consumer.is_connected:
			connected_consumers += 1
			if water_deficit == 0.0:
				supplied_consumers += 1
	
	return {
		"total_production": total_production,
		"total_demand": total_demand,
		"total_supplied": total_supplied,
		"water_deficit": water_deficit,
		"average_quality": average_quality,
		"source_count": _water_sources.size(),
		"consumer_count": _water_consumers.size(),
		"connected_consumers": connected_consumers,
		"supplied_consumers": supplied_consumers,
		"pipe_count": _pipes.size()
	}

func get_water_sources() -> Array:
	"""Retorna todas as fontes de água"""
	return _water_sources.values()

func get_water_consumers() -> Array:
	"""Retorna todos os consumidores de água"""
	return _water_consumers.values()

func get_pipes() -> Array:
	"""Retorna todas as tubulações"""
	return _pipes.duplicate()

func set_source_active(source_id: int, active: bool) -> bool:
	"""Define se uma fonte está ativa"""
	if not _water_sources.has(source_id):
		return false
	
	_water_sources[source_id].is_active = active
	_update_network()
	return true

func set_pipe_leak_rate(from: Vector2i, to: Vector2i, leak_rate: float) -> bool:
	"""Define a taxa de vazamento de uma tubulação"""
	for pipe in _pipes:
		if (pipe.from == from and pipe.to == to) or (pipe.from == to and pipe.to == from):
			pipe.leak_rate = clamp(leak_rate, 0.0, 1.0)
			_update_network()
			return true
	return false

func get_shortage_report() -> Dictionary:
	"""Retorna relatório detalhado de falta de água"""
	var report = {
		"has_shortage": water_deficit > 0.0,
		"deficit": water_deficit,
		"deficit_percentage": 0.0,
		"affected_buildings": [],
		"critical_buildings": [],
		"contaminated_sources": [],
		"total_affected": 0
	}
	
	if total_demand > 0.0:
		report["deficit_percentage"] = (water_deficit / total_demand) * 100.0
	
	# Identificar edifícios afetados
	for consumer in _water_consumers.values():
		if consumer.building_id < 0:
			continue
		
		if not consumer.is_connected:
			report["critical_buildings"].append(consumer.building_id)
			report["total_affected"] += 1
		elif water_deficit > 0.0:
			var ratio = total_production / total_demand if total_demand > 0.0 else 0.0
			if ratio < 0.3:
				report["critical_buildings"].append(consumer.building_id)
			else:
				report["affected_buildings"].append(consumer.building_id)
			report["total_affected"] += 1
	
	# Identificar fontes contaminadas
	for source in _water_sources.values():
		if source.contamination_level > 30.0:
			report["contaminated_sources"].append(source.id)
	
	return report

func get_connection_range() -> float:
	"""Retorna o alcance de conexão padrão"""
	return DEFAULT_CONNECTION_RANGE

func get_pipe_range() -> float:
	"""Retorna o alcance máximo de uma tubulação"""
	return PIPE_RANGE

func can_connect(from: Vector2i, to: Vector2i) -> bool:
	"""Verifica se dois pontos podem ser conectados"""
	var distance = from.distance_to(to)
	return distance <= PIPE_RANGE

func get_connected_nodes(position: Vector2i) -> Array:
	"""Retorna todos os nós conectados a uma posição"""
	if not _water_network.has(position):
		return []
	return _water_network[position].duplicate()

func is_position_in_network(position: Vector2i) -> bool:
	"""Verifica se uma posição faz parte da rede"""
	return _water_network.has(position)

func get_water_coverage_area(source_position: Vector2i) -> Array:
	"""Retorna todas as posições cobertas por uma fonte de água"""
	var covered: Array = []
	var visited: Dictionary = {}
	var queue: Array = [source_position]
	visited[source_position] = true
	covered.append(source_position)
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		# Explorar vizinhos
		if _water_network.has(current):
			for neighbor in _water_network[current]:
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
	for node in _water_network.keys():
		if not visited.has(node):
			# BFS para encontrar todos os nós conectados
			var segment: Array = []
			var queue: Array = [node]
			visited[node] = true
			
			while queue.size() > 0:
				var current = queue.pop_front()
				segment.append(current)
				
				if _water_network.has(current):
					for neighbor in _water_network[current]:
						if not visited.has(neighbor):
							visited[neighbor] = true
							queue.append(neighbor)
			
			segments.append(segment)
	
	return segments

func repair_pipe(from: Vector2i, to: Vector2i) -> bool:
	"""Repara uma tubulação (remove vazamentos)"""
	return set_pipe_leak_rate(from, to, 0.0)

func get_pipe_at(from: Vector2i, to: Vector2i) -> WaterPipe:
	"""Retorna a tubulação entre dois pontos"""
	for pipe in _pipes:
		if (pipe.from == from and pipe.to == to) or (pipe.from == to and pipe.to == from):
			return pipe
	return null

func get_total_pipe_capacity() -> float:
	"""Retorna a capacidade total de todas as tubulações"""
	var total = 0.0
	for pipe in _pipes:
		total += pipe.get_effective_capacity()
	return total

func optimize_network() -> void:
	"""Otimiza a rede removendo redundâncias"""
	# Esta é uma implementação básica que pode ser expandida
	_update_network()

func clear() -> void:
	"""Limpa todos os dados do sistema"""
	_water_sources.clear()
	_water_consumers.clear()
	_pipes.clear()
	_water_network.clear()
	_next_source_id = 0
	_next_consumer_id = 0
	total_production = 0.0
	total_demand = 0.0
	total_supplied = 0.0
	water_deficit = 0.0
	average_quality = 0.0
