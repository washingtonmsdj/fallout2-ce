## EventSystem - Sistema de eventos dinâmicos
## Gerencia eventos aleatórios e suas consequências
class_name EventSystem
extends Node

# Enum para tipos de eventos
enum EventType {
	RAID,           # Ataque à cidade
	TRADER,         # Comerciante visitante
	DISASTER,       # Desastre natural
	OPPORTUNITY     # Oportunidade especial
}

# Enum para resultados de eventos
enum EventResult {
	SUCCESS,
	FAILURE,
	PARTIAL,
	CANCELLED
}

# Classe para dados de evento
class GameEvent:
	var id: int
	var type: int
	var title: String
	var description: String
	var severity: float = 0.5  # 0-1
	var duration: float = 0.0
	var is_active: bool = true
	var affected_area: Rect2i
	var affected_citizens: Array = []
	var affected_buildings: Array = []
	var rewards: Dictionary = {}
	var penalties: Dictionary = {}
	var choices: Array = []  # Array de opções para o jogador
	var result: int = EventResult.CANCELLED
	
	func _init(p_id: int, p_type: int, p_title: String, p_desc: String) -> void:
		id = p_id
		type = p_type
		title = p_title
		description = p_desc

# Classe para cadeia de eventos
class EventChain:
	var id: int
	var events: Array = []  # Array de GameEvent
	var current_index: int = 0
	var is_complete: bool = false
	
	func _init(p_id: int) -> void:
		id = p_id
	
	func add_event(event: GameEvent) -> void:
		events.append(event)
	
	func get_current_event() -> GameEvent:
		if current_index < events.size():
			return events[current_index]
		return null
	
	func advance() -> bool:
		current_index += 1
		if current_index >= events.size():
			is_complete = true
			return false
		return true

# Estado
var _active_events: Dictionary = {}  # int (id) -> GameEvent
var _event_chains: Dictionary = {}  # int (id) -> EventChain
var _event_history: Array = []
var _next_event_id: int = 0
var _next_chain_id: int = 0

# Configuração
var event_frequency: float = 300.0  # Segundos entre eventos
var event_timer: float = 0.0
var prosperity_level: float = 0.5  # 0-1, afeta frequência e intensidade
var auto_events_enabled: bool = true

# Sistemas
var citizen_system
var building_system
var economy_system
var event_bus
var config

func _ready() -> void:
	pass

func set_config(cfg) -> void:
	config = cfg
	if config == null:
		config = CityConfig.new()

func set_systems(citizens, buildings, economy, bus) -> void:
	"""Define as referências aos sistemas"""
	citizen_system = citizens
	building_system = buildings
	economy_system = economy
	event_bus = bus

func update(delta: float) -> void:
	"""Atualiza o sistema de eventos"""
	# Atualizar eventos ativos
	_update_active_events(delta)
	
	# Gerar novos eventos
	if auto_events_enabled:
		event_timer += delta
		if event_timer >= event_frequency:
			event_timer = 0.0
			_trigger_random_event()

func _update_active_events(delta: float) -> void:
	"""Atualiza eventos ativos"""
	var to_remove: Array = []
	
	for event_id in _active_events.keys():
		var event = _active_events[event_id]
		event.duration -= delta
		
		if event.duration <= 0.0:
			to_remove.append(event_id)
	
	# Remover eventos expirados
	for event_id in to_remove:
		_complete_event(event_id, EventResult.CANCELLED)

func _trigger_random_event() -> void:
	"""Dispara um evento aleatório"""
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Selecionar tipo baseado em prosperidade
	var event_type = _select_event_type(rng)
	var severity = rng.randf_range(0.3, 0.9) * (1.0 + prosperity_level * 0.5)
	
	trigger_event(event_type, severity)

func _select_event_type(rng: RandomNumberGenerator) -> int:
	"""Seleciona tipo de evento baseado em pesos"""
	var weights = {
		EventType.RAID: 20 + int(prosperity_level * 30),
		EventType.TRADER: 40,
		EventType.DISASTER: 15,
		EventType.OPPORTUNITY: 25 + int(prosperity_level * 20)
	}
	
	var total = 0
	for w in weights.values():
		total += w
	
	var value = rng.randi_range(0, total - 1)
	var acc = 0
	
	for type in weights.keys():
		acc += weights[type]
		if value < acc:
			return type
	
	return EventType.TRADER

func trigger_event(event_type: int, severity: float = 0.5) -> int:
	"""Dispara um evento específico"""
	var event = _create_event(event_type, severity)
	_active_events[event.id] = event
	
	# Emitir evento
	if event_bus != null:
		event_bus.event_triggered.emit(event.id, event_type, {
			"title": event.title,
			"description": event.description,
			"severity": severity
		})
	
	return event.id

func _create_event(event_type: int, severity: float) -> GameEvent:
	"""Cria um novo evento"""
	var event_id = _next_event_id
	_next_event_id += 1
	
	var event: GameEvent
	
	match event_type:
		EventType.RAID:
			event = _create_raid_event(event_id, severity)
		EventType.TRADER:
			event = _create_trader_event(event_id, severity)
		EventType.DISASTER:
			event = _create_disaster_event(event_id, severity)
		EventType.OPPORTUNITY:
			event = _create_opportunity_event(event_id, severity)
		_:
			event = GameEvent.new(event_id, event_type, "Evento Desconhecido", "Um evento ocorreu.")
	
	return event

func _create_raid_event(event_id: int, severity: float) -> GameEvent:
	var event = GameEvent.new(event_id, EventType.RAID, "Ataque de Saqueadores", 
		"Um grupo de saqueadores está atacando a cidade!")
	event.severity = severity
	event.duration = 120.0
	event.penalties = {"caps": 100 * severity, "materials": 50 * severity}
	return event

func _create_trader_event(event_id: int, severity: float) -> GameEvent:
	var event = GameEvent.new(event_id, EventType.TRADER, "Comerciante Visitante",
		"Um comerciante chegou com mercadorias raras!")
	event.severity = severity
	event.duration = 300.0
	event.rewards = {"caps": -50, "materials": 20}  # Custo para comprar
	return event

func _create_disaster_event(event_id: int, severity: float) -> GameEvent:
	var event = GameEvent.new(event_id, EventType.DISASTER, "Desastre Natural",
		"Um desastre atingiu a cidade!")
	event.severity = severity
	event.duration = 60.0
	event.penalties = {"materials": 30 * severity}
	return event

func _create_opportunity_event(event_id: int, severity: float) -> GameEvent:
	var event = GameEvent.new(event_id, EventType.OPPORTUNITY, "Oportunidade Especial",
		"Uma oportunidade única surgiu!")
	event.severity = severity
	event.duration = 180.0
	event.rewards = {"caps": 150 * severity}
	return event

func resolve_event(event_id: int, result: int) -> bool:
	"""Resolve um evento com um resultado"""
	if not _active_events.has(event_id):
		return false
	
	return _complete_event(event_id, result)

func _complete_event(event_id: int, result: int) -> bool:
	"""Completa um evento"""
	if not _active_events.has(event_id):
		return false
	
	var event = _active_events[event_id]
	event.result = result
	event.is_active = false
	
	# Aplicar recompensas/penalidades
	if result == EventResult.SUCCESS:
		_apply_rewards(event.rewards)
	elif result == EventResult.FAILURE:
		_apply_penalties(event.penalties)
	elif result == EventResult.PARTIAL:
		_apply_rewards(event.rewards, 0.5)
		_apply_penalties(event.penalties, 0.5)
	
	# Adicionar ao histórico
	_event_history.append(event)
	_active_events.erase(event_id)
	
	# Emitir evento
	if event_bus != null:
		event_bus.event_resolved.emit(event_id, result)
	
	return true

func _apply_rewards(rewards: Dictionary, multiplier: float = 1.0) -> void:
	"""Aplica recompensas"""
	if economy_system == null:
		return
	
	for resource_name in rewards.keys():
		var amount = rewards[resource_name] * multiplier
		if amount > 0:
			var resource_type = _get_resource_type(resource_name)
			if resource_type >= 0:
				economy_system.add_resource(resource_type, amount)

func _apply_penalties(penalties: Dictionary, multiplier: float = 1.0) -> void:
	"""Aplica penalidades"""
	if economy_system == null:
		return
	
	for resource_name in penalties.keys():
		var amount = penalties[resource_name] * multiplier
		var resource_type = _get_resource_type(resource_name)
		if resource_type >= 0:
			economy_system.consume_resource(resource_type, amount)

func _get_resource_type(name: String) -> int:
	"""Converte nome de recurso para tipo"""
	match name.to_lower():
		"food": return CityConfig.ResourceType.FOOD
		"water": return CityConfig.ResourceType.WATER
		"caps": return CityConfig.ResourceType.CAPS
		"materials": return CityConfig.ResourceType.MATERIALS
		"power": return CityConfig.ResourceType.POWER
		"medicine": return CityConfig.ResourceType.MEDICINE
		"weapons": return CityConfig.ResourceType.WEAPONS
		"fuel": return CityConfig.ResourceType.FUEL
		"components": return CityConfig.ResourceType.COMPONENTS
	return -1

func create_event_chain(events: Array) -> int:
	"""Cria uma cadeia de eventos"""
	var chain = EventChain.new(_next_chain_id)
	_next_chain_id += 1
	
	for event_data in events:
		var event = _create_event(event_data["type"], event_data.get("severity", 0.5))
		chain.add_event(event)
	
	_event_chains[chain.id] = chain
	
	# Emitir evento
	if event_bus != null and chain.events.size() > 0:
		event_bus.event_chain_started.emit(chain.id, chain.events[0].id)
	
	return chain.id

func advance_event_chain(chain_id: int) -> bool:
	"""Avança para o próximo evento na cadeia"""
	if not _event_chains.has(chain_id):
		return false
	
	var chain = _event_chains[chain_id]
	if chain.advance():
		var current = chain.get_current_event()
		if current != null and event_bus != null:
			event_bus.event_chain_progressed.emit(chain_id, current.id)
		return true
	else:
		if event_bus != null:
			event_bus.event_chain_ended.emit(chain_id, EventResult.SUCCESS)
		return false

func get_active_events() -> Array:
	"""Retorna todos os eventos ativos"""
	return _active_events.values()

func get_event(event_id: int) -> GameEvent:
	"""Retorna um evento específico"""
	return _active_events.get(event_id)

func get_event_history() -> Array:
	"""Retorna o histórico de eventos"""
	return _event_history.duplicate()

func set_prosperity_level(level: float) -> void:
	"""Define o nível de prosperidade"""
	prosperity_level = clamp(level, 0.0, 1.0)

func get_prosperity_level() -> float:
	"""Retorna o nível de prosperidade"""
	return prosperity_level

func enable_auto_events(enabled: bool) -> void:
	"""Ativa/desativa eventos automáticos"""
	auto_events_enabled = enabled

func set_event_frequency(frequency: float) -> void:
	"""Define a frequência de eventos"""
	event_frequency = max(60.0, frequency)

func get_event_statistics() -> Dictionary:
	"""Retorna estatísticas de eventos"""
	return {
		"active_events": _active_events.size(),
		"total_events": _event_history.size() + _active_events.size(),
		"prosperity_level": prosperity_level,
		"event_frequency": event_frequency,
		"auto_events_enabled": auto_events_enabled
	}

func clear() -> void:
	"""Limpa todos os dados do sistema"""
	_active_events.clear()
	_event_chains.clear()
	_event_history.clear()
	_next_event_id = 0
	_next_chain_id = 0
	event_timer = 0.0
	prosperity_level = 0.5
