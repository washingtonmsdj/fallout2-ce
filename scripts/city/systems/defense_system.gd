## DefenseSystem - Sistema de Defesa
## Gerencia estruturas defensivas, patrulhas de guardas e alertas
class_name DefenseSystem
extends Node

# Enums para tipos de defesa
enum DefenseType {
	WALL,
	GATE,
	GUARD_TOWER,
	TURRET_BALLISTIC,
	TURRET_LASER,
	TRAP_MINE,
	TRAP_SPIKE
}

# Classe para dados de estrutura defensiva
class DefenseStructure:
	var id: int
	var type: DefenseType
	var position: Vector2i
	var health: float
	var max_health: float
	var ammo: int
	var max_ammo: int
	var range: float
	var damage: float
	var target_id: int = -1
	var is_active: bool = true
	var faction_id: int = -1
	
	func _init(p_id: int, p_type: DefenseType, p_pos: Vector2i) -> void:
		id = p_id
		type = p_type
		position = p_pos
		
		# Configurar propriedades baseadas no tipo
		match type:
			DefenseType.WALL:
				max_health = 100.0
				health = 100.0
				range = 0.0
				damage = 0.0
				max_ammo = 0
				ammo = 0
			DefenseType.GATE:
				max_health = 80.0
				health = 80.0
				range = 0.0
				damage = 0.0
				max_ammo = 0
				ammo = 0
			DefenseType.GUARD_TOWER:
				max_health = 60.0
				health = 60.0
				range = 15.0
				damage = 25.0
				max_ammo = 200
				ammo = 200
			DefenseType.TURRET_BALLISTIC:
				max_health = 40.0
				health = 40.0
				range = 20.0
				damage = 35.0
				max_ammo = 300
				ammo = 300
			DefenseType.TURRET_LASER:
				max_health = 35.0
				health = 35.0
				range = 25.0
				damage = 40.0
				max_ammo = 150
				ammo = 150
			DefenseType.TRAP_MINE:
				max_health = 10.0
				health = 10.0
				range = 5.0
				damage = 50.0
				max_ammo = 1
				ammo = 1
			DefenseType.TRAP_SPIKE:
				max_health = 15.0
				health = 15.0
				range = 3.0
				damage = 20.0
				max_ammo = 0
				ammo = 0
	
	func _to_string() -> String:
		return "DefenseStructure(id=%d, type=%d, pos=%s, health=%.1f, ammo=%d)" % [
			id, type, position, health, ammo
		]

# Classe para dados de guarda
class GuardData:
	var citizen_id: int
	var patrol_route: Array[Vector2i]
	var current_waypoint: int = 0
	var alert_level: int = 0  # 0=normal, 1=alerta, 2=combate
	var is_active: bool = true
	var faction_id: int = -1
	
	func _init(p_citizen_id: int, p_route: Array[Vector2i]) -> void:
		citizen_id = p_citizen_id
		patrol_route = p_route.duplicate()
	
	func _to_string() -> String:
		return "GuardData(citizen=%d, waypoints=%d, alert=%d)" % [
			citizen_id, patrol_route.size(), alert_level
		]

# Armazenamento de estruturas defensivas
var _defenses: Dictionary = {}  # int (id) -> DefenseStructure
var _guards: Dictionary = {}  # int (citizen_id) -> GuardData
var _next_defense_id: int = 0

# Referências aos sistemas
var grid_system
var config
var event_bus

func _ready() -> void:
	pass

func set_config(cfg) -> void:
	config = cfg
	if config == null:
		config = CityConfig.new()

func set_systems(grid, bus) -> void:
	"""Define as referências aos sistemas"""
	grid_system = grid
	event_bus = bus

# =============================================================================
# CONSTRUÇÃO E GERENCIAMENTO DE DEFESAS
# =============================================================================

func build_defense(type: DefenseType, pos: Vector2i, faction_id: int = -1) -> int:
	"""Constrói uma estrutura defensiva"""
	var defense = DefenseStructure.new(_next_defense_id, type, pos)
	defense.faction_id = faction_id
	_next_defense_id += 1
	
	_defenses[defense.id] = defense
	
	if event_bus != null:
		event_bus.defense_built.emit(defense.id, type, pos)
	
	return defense.id

func destroy_defense(defense_id: int) -> bool:
	"""Destrói uma estrutura defensiva"""
	if not _defenses.has(defense_id):
		return false
	
	var defense = _defenses[defense_id]
	_defenses.erase(defense_id)
	
	if event_bus != null:
		event_bus.defense_destroyed.emit(defense_id)
	
	return true

func get_defense(defense_id: int) -> DefenseStructure:
	"""Obtém uma estrutura defensiva"""
	return _defenses.get(defense_id)

func get_all_defenses() -> Array:
	"""Retorna todas as estruturas defensivas"""
	return _defenses.values()

func get_defenses_by_type(type: DefenseType) -> Array:
	"""Retorna estruturas defensivas de um tipo específico"""
	var result = []
	for defense in _defenses.values():
		if defense.type == type:
			result.append(defense)
	return result

func get_defenses_in_area(rect: Rect2i) -> Array:
	"""Retorna estruturas defensivas em uma área"""
	var result = []
	for defense in _defenses.values():
		if rect.has_point(defense.position):
			result.append(defense)
	return result

func get_defenses_by_faction(faction_id: int) -> Array:
	"""Retorna estruturas defensivas de uma facção"""
	var result = []
	for defense in _defenses.values():
		if defense.faction_id == faction_id:
			result.append(defense)
	return result

# =============================================================================
# CÁLCULO DE CLASSIFICAÇÃO DE DEFESA
# =============================================================================

func get_defense_rating() -> float:
	"""Calcula a classificação de defesa total do assentamento"""
	var total_rating = 0.0
	
	for defense in _defenses.values():
		if not defense.is_active:
			continue
		
		# Calcular contribuição baseada no tipo e saúde
		var base_rating = 0.0
		match defense.type:
			DefenseType.WALL:
				base_rating = 10.0
			DefenseType.GATE:
				base_rating = 8.0
			DefenseType.GUARD_TOWER:
				base_rating = 25.0
			DefenseType.TURRET_BALLISTIC:
				base_rating = 35.0
			DefenseType.TURRET_LASER:
				base_rating = 40.0
			DefenseType.TRAP_MINE:
				base_rating = 15.0
			DefenseType.TRAP_SPIKE:
				base_rating = 5.0
		
		# Ajustar pela saúde (estruturas danificadas contribuem menos)
		var health_factor = defense.health / defense.max_health
		var ammo_factor = 1.0
		
		# Ajustar pela munição (turrets sem munição não contribuem)
		if defense.max_ammo > 0:
			ammo_factor = float(defense.ammo) / float(defense.max_ammo)
		
		total_rating += base_rating * health_factor * ammo_factor
	
	return total_rating

func get_defense_rating_by_faction(faction_id: int) -> float:
	"""Calcula a classificação de defesa de uma facção específica"""
	var total_rating = 0.0
	
	for defense in _defenses.values():
		if defense.faction_id != faction_id or not defense.is_active:
			continue
		
		var base_rating = 0.0
		match defense.type:
			DefenseType.WALL:
				base_rating = 10.0
			DefenseType.GATE:
				base_rating = 8.0
			DefenseType.GUARD_TOWER:
				base_rating = 25.0
			DefenseType.TURRET_BALLISTIC:
				base_rating = 35.0
			DefenseType.TURRET_LASER:
				base_rating = 40.0
			DefenseType.TRAP_MINE:
				base_rating = 15.0
			DefenseType.TRAP_SPIKE:
				base_rating = 5.0
		
		var health_factor = defense.health / defense.max_health
		var ammo_factor = 1.0
		
		if defense.max_ammo > 0:
			ammo_factor = float(defense.ammo) / float(defense.max_ammo)
		
		total_rating += base_rating * health_factor * ammo_factor
	
	return total_rating

# =============================================================================
# DANO E REPARAÇÃO
# =============================================================================

func damage_defense(defense_id: int, damage: float) -> bool:
	"""Causa dano a uma estrutura defensiva"""
	if not _defenses.has(defense_id):
		return false
	
	var defense = _defenses[defense_id]
	defense.health = maxf(0.0, defense.health - damage)
	
	if defense.health <= 0:
		defense.is_active = false
	
	if event_bus != null:
		event_bus.defense_damaged.emit(defense_id, damage)
	
	return true

func repair_defense(defense_id: int, amount: float) -> bool:
	"""Repara uma estrutura defensiva"""
	if not _defenses.has(defense_id):
		return false
	
	var defense = _defenses[defense_id]
	defense.health = minf(defense.max_health, defense.health + amount)
	
	if defense.health > 0:
		defense.is_active = true
	
	return true

func refill_ammo(defense_id: int, amount: int) -> bool:
	"""Reabastece munição de uma estrutura defensiva"""
	if not _defenses.has(defense_id):
		return false
	
	var defense = _defenses[defense_id]
	if defense.max_ammo <= 0:
		return false
	
	defense.ammo = mini(defense.max_ammo, defense.ammo + amount)
	return true

# =============================================================================
# ENGAJAMENTO AUTOMÁTICO
# =============================================================================

func engage_target(defense_id: int, target_id: int) -> bool:
	"""Engaja um alvo com uma estrutura defensiva"""
	if not _defenses.has(defense_id):
		return false
	
	var defense = _defenses[defense_id]
	
	# Apenas turrets e torres podem engajar
	if defense.type not in [DefenseType.GUARD_TOWER, DefenseType.TURRET_BALLISTIC, DefenseType.TURRET_LASER]:
		return false
	
	# Verificar munição
	if defense.ammo <= 0:
		if event_bus != null:
			event_bus.defense_ammo_depleted.emit(defense_id)
		return false
	
	defense.target_id = target_id
	defense.ammo -= 1
	
	if event_bus != null:
		event_bus.defense_engaged.emit(defense_id, target_id)
	
	return true

func process_raid(raid_data: Dictionary) -> Dictionary:
	"""Processa um ataque/raid contra o assentamento"""
	var result = {
		"defenses_engaged": 0,
		"damage_dealt": 0.0,
		"ammo_used": 0,
		"casualties": 0
	}
	
	# Engajar com todas as defesas ativas
	for defense in _defenses.values():
		if not defense.is_active or defense.ammo <= 0:
			continue
		
		# Simular engajamento
		if defense.type in [DefenseType.GUARD_TOWER, DefenseType.TURRET_BALLISTIC, DefenseType.TURRET_LASER]:
			result["defenses_engaged"] += 1
			result["damage_dealt"] += defense.damage
			result["ammo_used"] += 1
			defense.ammo -= 1
	
	return result

# =============================================================================
# PATRULHAS DE GUARDAS
# =============================================================================

func assign_guard(citizen_id: int, route: Array[Vector2i]) -> bool:
	"""Atribui uma rota de patrulha a um cidadão"""
	if route.is_empty():
		return false
	
	var guard = GuardData.new(citizen_id, route)
	_guards[citizen_id] = guard
	
	if event_bus != null:
		event_bus.guard_assigned.emit(citizen_id, route)
	
	return true

func remove_guard(citizen_id: int) -> bool:
	"""Remove um guarda de patrulha"""
	if not _guards.has(citizen_id):
		return false
	
	_guards.erase(citizen_id)
	return true

func get_guard(citizen_id: int) -> GuardData:
	"""Obtém dados de um guarda"""
	return _guards.get(citizen_id)

func get_all_guards() -> Array:
	"""Retorna todos os guardas"""
	return _guards.values()

func get_guards_by_faction(faction_id: int) -> Array:
	"""Retorna guardas de uma facção específica"""
	var result = []
	for guard in _guards.values():
		if guard.faction_id == faction_id:
			result.append(guard)
	return result

func update_guard_waypoint(citizen_id: int) -> bool:
	"""Avança o guarda para o próximo ponto de patrulha"""
	if not _guards.has(citizen_id):
		return false
	
	var guard = _guards[citizen_id]
	guard.current_waypoint = (guard.current_waypoint + 1) % guard.patrol_route.size()
	return true

func get_guard_current_waypoint(citizen_id: int) -> Vector2i:
	"""Obtém o ponto de patrulha atual de um guarda"""
	if not _guards.has(citizen_id):
		return Vector2i.ZERO
	
	var guard = _guards[citizen_id]
	if guard.patrol_route.is_empty():
		return Vector2i.ZERO
	
	return guard.patrol_route[guard.current_waypoint]

# =============================================================================
# ALERTAS E AVISOS
# =============================================================================

func trigger_alert(threat_pos: Vector2i, threat_type: int = 0) -> void:
	"""Dispara um alerta para ameaça iminente"""
	# Aumentar nível de alerta de todos os guardas
	for guard in _guards.values():
		if guard.alert_level < 1:
			guard.alert_level = 1
	
	if event_bus != null:
		event_bus.settlement_alert.emit(threat_type, threat_pos)

func trigger_combat_alert(threat_pos: Vector2i) -> void:
	"""Dispara alerta de combate"""
	# Aumentar nível de alerta para combate
	for guard in _guards.values():
		guard.alert_level = 2
	
	if event_bus != null:
		event_bus.settlement_alert.emit(2, threat_pos)

func reset_alert_level() -> void:
	"""Reseta o nível de alerta de todos os guardas"""
	for guard in _guards.values():
		guard.alert_level = 0

# =============================================================================
# ESTATÍSTICAS E RELATÓRIOS
# =============================================================================

func get_defense_statistics() -> Dictionary:
	"""Retorna estatísticas de defesa"""
	var stats = {
		"total_defenses": _defenses.size(),
		"active_defenses": 0,
		"total_health": 0.0,
		"total_ammo": 0,
		"defense_rating": get_defense_rating(),
		"guards": _guards.size(),
		"by_type": {}
	}
	
	for defense in _defenses.values():
		if defense.is_active:
			stats["active_defenses"] += 1
		stats["total_health"] += defense.health
		stats["total_ammo"] += defense.ammo
		
		var type_name = DefenseType.keys()[defense.type]
		if not stats["by_type"].has(type_name):
			stats["by_type"][type_name] = 0
		stats["by_type"][type_name] += 1
	
	return stats

func get_defense_count() -> int:
	"""Retorna o número total de estruturas defensivas"""
	return _defenses.size()

func get_active_defense_count() -> int:
	"""Retorna o número de estruturas defensivas ativas"""
	var count = 0
	for defense in _defenses.values():
		if defense.is_active:
			count += 1
	return count

func get_guard_count() -> int:
	"""Retorna o número total de guardas"""
	return _guards.size()

func get_total_ammo() -> int:
	"""Retorna a munição total disponível"""
	var total = 0
	for defense in _defenses.values():
		total += defense.ammo
	return total
