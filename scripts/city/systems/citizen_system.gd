## CitizenSystem - Sistema de cidadãos
## Gerencia cidadãos, necessidades e comportamento autônomo
class_name CitizenSystem
extends Node

# Enums para tipos de necessidade
enum NeedType {
	HUNGER = 0,
	THIRST = 1,
	REST = 2,
	HAPPINESS = 3,
	HEALTH = 4,
	SAFETY = 5
}

# Enums para atividades
enum Activity {
	IDLE = 0,
	WORKING = 1,
	EATING = 2,
	DRINKING = 3,
	SLEEPING = 4,
	LEISURE = 5,
	TRAVELING = 6,
	SEEKING_RESOURCES = 7
}

# Classe para dados de um cidadão
class CitizenData:
	var id: int
	var name: String
	var position: Vector2i
	var home_building_id: int = -1
	var job_building_id: int = -1
	var faction_id: int = -1
	
	# Necessidades (0-100)
	var needs: Dictionary = {
		NeedType.HUNGER: 50.0,
		NeedType.THIRST: 50.0,
		NeedType.REST: 50.0,
		NeedType.HAPPINESS: 50.0,
		NeedType.HEALTH: 100.0,
		NeedType.SAFETY: 50.0
	}
	
	# Atributos
	var skills: Dictionary = {}  # skill_type -> level (0-100)
	var relationships: Dictionary = {}  # citizen_id -> relationship_value (-100 to 100)
	var age: int = 25
	var gender: int = 0  # 0 = male, 1 = female
	var faction_affiliation: int = -1  # ID da facção
	var traits: Array = []  # Array de traits especiais
	var experience: int = 0  # Experiência total
	var level: int = 1  # Nível do cidadão
	
	# Estado
	var current_activity: int = Activity.IDLE
	var current_path: Array = []  # Array of Vector2i
	var path_index: int = 0
	var is_alive: bool = true
	var is_employed: bool = false
	
	# Agenda
	var schedule: Array = []  # Array of ScheduleEntry
	
	class ScheduleEntry:
		var hour: int
		var activity: int
		var location: Vector2i
		
		func _init(p_hour: int, p_activity: int, p_location: Vector2i) -> void:
			hour = p_hour
			activity = p_activity
			location = p_location
	
	func _init(p_id: int, p_name: String, p_pos: Vector2i) -> void:
		id = p_id
		name = p_name
		position = p_pos
	
	func _to_string() -> String:
		return "CitizenData(id=%d, name=%s, pos=%s, alive=%s)" % [
			id, name, position, is_alive
		]
	
	func get_critical_need() -> int:
		"""Retorna o tipo de necessidade mais crítica"""
		var critical_need = -1
		var min_value = 100.0
		
		for need_type in needs.keys():
			if needs[need_type] < min_value:
				min_value = needs[need_type]
				critical_need = need_type
		
		return critical_need if min_value < 30.0 else -1
	
	func is_need_critical(need_type: int) -> bool:
		"""Verifica se uma necessidade é crítica"""
		return needs.get(need_type, 100.0) < 20.0

# Armazenamento de cidadãos
var _citizens: Dictionary = {}  # int (id) -> CitizenData
var _next_citizen_id: int = 0

var grid_system
var building_system
var config
var event_bus

func _ready() -> void:
	pass

func set_config(cfg) -> void:
	config = cfg
	if config == null:
		config = CityConfig.new()

func set_systems(grid, building, bus) -> void:
	"""Define as referências aos sistemas"""
	grid_system = grid
	building_system = building
	event_bus = bus

func spawn_citizen(name: String, position: Vector2i) -> int:
	"""Cria um novo cidadão"""
	var citizen = CitizenData.new(_next_citizen_id, name, position)
	_next_citizen_id += 1
	
	# Inicializar necessidades aleatoriamente
	for need_type in citizen.needs.keys():
		citizen.needs[need_type] = randf_range(30.0, 70.0)
	
	_citizens[citizen.id] = citizen
	
	if event_bus != null:
		event_bus.citizen_spawned.emit(citizen.id)
	
	return citizen.id

func kill_citizen(citizen_id: int) -> bool:
	"""Remove um cidadão"""
	if not _citizens.has(citizen_id):
		return false
	
	var citizen = _citizens[citizen_id]
	citizen.is_alive = false
	
	if event_bus != null:
		event_bus.citizen_died.emit(citizen_id)
	
	return true

func get_citizen(citizen_id: int) -> CitizenData:
	"""Obtém um cidadão"""
	return _citizens.get(citizen_id)

func get_all_citizens() -> Array:
	"""Retorna todos os cidadãos"""
	return _citizens.values()

func get_citizen_count() -> int:
	"""Retorna o número de cidadãos"""
	return _citizens.size()

func get_alive_citizens() -> Array:
	"""Retorna todos os cidadãos vivos"""
	var result: Array = []
	for citizen in _citizens.values():
		if citizen.is_alive:
			result.append(citizen)
	return result

func update_citizen_needs(delta: float) -> void:
	"""Atualiza as necessidades de todos os cidadãos"""
	for citizen in _citizens.values():
		if not citizen.is_alive:
			continue
		
		# Aplicar decay de necessidades
		for need_type in citizen.needs.keys():
			var decay_rate = config.get_need_decay_rate(need_type)
			citizen.needs[need_type] = max(0.0, citizen.needs[need_type] - decay_rate * delta)
		
		# Verificar necessidades críticas
		var critical_need = citizen.get_critical_need()
		if critical_need >= 0:
			if event_bus != null:
				event_bus.citizen_need_critical.emit(citizen.id, critical_need)

func fulfill_need(citizen_id: int, need_type: int, amount: float) -> bool:
	"""Satisfaz uma necessidade de um cidadão"""
	if not _citizens.has(citizen_id):
		return false
	
	var citizen = _citizens[citizen_id]
	if not citizen.needs.has(need_type):
		return false
	
	citizen.needs[need_type] = min(100.0, citizen.needs[need_type] + amount)
	return true

func assign_job(citizen_id: int, building_id: int) -> bool:
	"""Atribui um trabalho a um cidadão"""
	if not _citizens.has(citizen_id):
		return false
	
	var citizen = _citizens[citizen_id]
	
	# Verificar se o edifício pode empregar
	if building_system != null:
		if not building_system.can_employ(building_id):
			return false
	
	# Se já tinha trabalho, remover do anterior
	if citizen.job_building_id >= 0 and building_system != null:
		building_system.remove_employee(citizen.job_building_id, citizen_id)
	
	citizen.job_building_id = building_id
	citizen.is_employed = true
	
	# Notificar o edifício
	if building_system != null:
		building_system.add_employee(building_id, citizen_id)
	
	return true

func remove_job(citizen_id: int) -> bool:
	"""Remove o trabalho de um cidadão"""
	if not _citizens.has(citizen_id):
		return false
	
	var citizen = _citizens[citizen_id]
	
	# Notificar o edifício anterior
	if citizen.job_building_id >= 0 and building_system != null:
		building_system.remove_employee(citizen.job_building_id, citizen_id)
	
	citizen.job_building_id = -1
	citizen.is_employed = false
	
	return true

func assign_home(citizen_id: int, building_id: int) -> bool:
	"""Atribui uma casa a um cidadão"""
	if not _citizens.has(citizen_id):
		return false
	
	var citizen = _citizens[citizen_id]
	
	# Verificar se o edifício pode hospedar
	if building_system != null:
		if not building_system.can_house(building_id):
			return false
	
	# Se já tinha casa, remover do anterior
	if citizen.home_building_id >= 0 and building_system != null:
		building_system.remove_resident(citizen.home_building_id, citizen_id)
	
	citizen.home_building_id = building_id
	
	# Notificar o edifício
	if building_system != null:
		building_system.add_resident(building_id, citizen_id)
	
	return true

func remove_home(citizen_id: int) -> bool:
	"""Remove a casa de um cidadão"""
	if not _citizens.has(citizen_id):
		return false
	
	var citizen = _citizens[citizen_id]
	
	# Notificar o edifício anterior
	if citizen.home_building_id >= 0 and building_system != null:
		building_system.remove_resident(citizen.home_building_id, citizen_id)
	
	citizen.home_building_id = -1
	
	return true

func add_schedule_entry(citizen_id: int, hour: int, activity: int, location: Vector2i) -> bool:
	"""Adiciona uma entrada à agenda de um cidadão"""
	if not _citizens.has(citizen_id):
		return false
	
	var citizen = _citizens[citizen_id]
	var entry = CitizenData.ScheduleEntry.new(hour, activity, location)
	citizen.schedule.append(entry)
	
	return true

func get_citizen_statistics() -> Dictionary:
	"""Retorna estatísticas dos cidadãos"""
	var stats = {
		"total_citizens": _citizens.size(),
		"alive_citizens": 0,
		"employed_citizens": 0,
		"average_happiness": 0.0,
		"average_health": 0.0
	}
	
	var total_happiness = 0.0
	var total_health = 0.0
	
	for citizen in _citizens.values():
		if citizen.is_alive:
			stats["alive_citizens"] += 1
			total_happiness += citizen.needs[NeedType.HAPPINESS]
			total_health += citizen.needs[NeedType.HEALTH]
		
		if citizen.is_employed:
			stats["employed_citizens"] += 1
	
	if stats["alive_citizens"] > 0:
		stats["average_happiness"] = total_happiness / stats["alive_citizens"]
		stats["average_health"] = total_health / stats["alive_citizens"]
	
	return stats

func get_citizens_with_critical_need(need_type: int) -> Array:
	"""Retorna cidadãos com uma necessidade crítica"""
	var result: Array = []
	for citizen in _citizens.values():
		if citizen.is_alive and citizen.is_need_critical(need_type):
			result.append(citizen)
	return result

func get_unemployed_citizens() -> Array:
	"""Retorna cidadãos desempregados"""
	var result: Array = []
	for citizen in _citizens.values():
		if citizen.is_alive and not citizen.is_employed:
			result.append(citizen)
	return result

func get_homeless_citizens() -> Array:
	"""Retorna cidadãos sem casa"""
	var result: Array = []
	for citizen in _citizens.values():
		if citizen.is_alive and citizen.home_building_id == -1:
			result.append(citizen)
	return result

func make_autonomous_decision(citizen_id: int) -> void:
	"""Toma decisões autônomas baseadas em necessidades críticas"""
	if not _citizens.has(citizen_id):
		return
	
	var citizen = _citizens[citizen_id]
	if not citizen.is_alive:
		return
	
	# Encontrar a necessidade mais crítica
	var critical_need = citizen.get_critical_need()
	
	if critical_need == -1:
		# Sem necessidades críticas, continuar com atividade atual
		return
	
	# Decidir ação baseada na necessidade crítica
	match critical_need:
		NeedType.HUNGER:
			# Procurar comida
			citizen.current_activity = Activity.SEEKING_RESOURCES
			_seek_resource_location(citizen, "food")
		
		NeedType.THIRST:
			# Procurar água
			citizen.current_activity = Activity.SEEKING_RESOURCES
			_seek_resource_location(citizen, "water")
		
		NeedType.REST:
			# Ir para casa dormir
			if citizen.home_building_id >= 0:
				citizen.current_activity = Activity.SLEEPING
				_move_to_building(citizen, citizen.home_building_id)
			else:
				# Procurar abrigo
				citizen.current_activity = Activity.SEEKING_RESOURCES
				_seek_resource_location(citizen, "shelter")
		
		NeedType.HEALTH:
			# Procurar clínica médica
			citizen.current_activity = Activity.SEEKING_RESOURCES
			_seek_resource_location(citizen, "medical")
		
		NeedType.SAFETY:
			# Procurar abrigo seguro
			citizen.current_activity = Activity.SEEKING_RESOURCES
			_seek_resource_location(citizen, "safe_zone")

func _seek_resource_location(citizen: CitizenData, resource_type: String) -> void:
	"""Procura por um local que tenha o recurso desejado"""
	# Esta função será expandida quando o BuildingSystem estiver completo
	# Por enquanto, apenas marca que o cidadão está procurando
	pass

func _move_to_building(citizen: CitizenData, building_id: int) -> void:
	"""Move um cidadão para um edifício"""
	# Esta função será expandida quando o pathfinding estiver integrado
	# Por enquanto, apenas marca o destino
	pass

func set_citizen_skill(citizen_id: int, skill_type: int, level: int) -> bool:
	"""Define o nível de uma habilidade"""
	if not _citizens.has(citizen_id):
		return false
	
	var citizen = _citizens[citizen_id]
	citizen.skills[skill_type] = clamp(level, 0, 100)
	return true

func get_citizen_skill(citizen_id: int, skill_type: int) -> int:
	"""Obtém o nível de uma habilidade"""
	if not _citizens.has(citizen_id):
		return 0
	
	var citizen = _citizens[citizen_id]
	return citizen.skills.get(skill_type, 0)

func add_relationship(citizen_id_a: int, citizen_id_b: int, amount: int) -> bool:
	"""Adiciona relacionamento entre dois cidadãos"""
	if not _citizens.has(citizen_id_a) or not _citizens.has(citizen_id_b):
		return false
	
	var citizen_a = _citizens[citizen_id_a]
	var current = citizen_a.relationships.get(citizen_id_b, 0)
	citizen_a.relationships[citizen_id_b] = clamp(current + amount, -100, 100)
	return true

func get_relationship(citizen_id_a: int, citizen_id_b: int) -> int:
	"""Obtém o relacionamento entre dois cidadãos"""
	if not _citizens.has(citizen_id_a):
		return 0
	
	var citizen_a = _citizens[citizen_id_a]
	return citizen_a.relationships.get(citizen_id_b, 0)

func add_trait(citizen_id: int, trait_name: String) -> bool:
	"""Adiciona um trait a um cidadão"""
	if not _citizens.has(citizen_id):
		return false
	
	var citizen = _citizens[citizen_id]
	if not citizen.traits.has(trait_name):
		citizen.traits.append(trait_name)
	return true

func has_trait(citizen_id: int, trait_name: String) -> bool:
	"""Verifica se um cidadão tem um trait"""
	if not _citizens.has(citizen_id):
		return false
	
	var citizen = _citizens[citizen_id]
	return citizen.traits.has(trait_name)

func add_experience(citizen_id: int, amount: int) -> bool:
	"""Adiciona experiência a um cidadão"""
	if not _citizens.has(citizen_id):
		return false
	
	var citizen = _citizens[citizen_id]
	citizen.experience += amount
	
	# Verificar level up (100 exp por nível)
	var new_level = 1 + (citizen.experience / 100)
	if new_level > citizen.level:
		citizen.level = new_level
	
	return true

func update_citizen_activity(citizen_id: int, delta: float) -> void:
	"""Atualiza a atividade de um cidadão"""
	if not _citizens.has(citizen_id):
		return
	
	var citizen = _citizens[citizen_id]
	if not citizen.is_alive:
		return
	
	# Se tem caminho, seguir
	if citizen.current_path.size() > 0 and citizen.path_index < citizen.current_path.size():
		citizen.position = citizen.current_path[citizen.path_index]
		citizen.path_index += 1
	
	# Atualizar atividade baseada no estado
	match citizen.current_activity:
		Activity.WORKING:
			# Produzir recursos (será implementado com BuildingSystem)
			pass
		
		Activity.EATING:
			# Consumir comida e satisfazer fome
			fulfill_need(citizen_id, NeedType.HUNGER, 20.0 * delta)
		
		Activity.DRINKING:
			# Consumir água e satisfazer sede
			fulfill_need(citizen_id, NeedType.THIRST, 20.0 * delta)
		
		Activity.SLEEPING:
			# Descansar e satisfazer necessidade de sono
			fulfill_need(citizen_id, NeedType.REST, 30.0 * delta)
		
		Activity.LEISURE:
			# Atividade de lazer e aumentar felicidade
			fulfill_need(citizen_id, NeedType.HAPPINESS, 15.0 * delta)
		
		Activity.SEEKING_RESOURCES:
			# Procurar recursos (será implementado com BuildingSystem)
			pass

