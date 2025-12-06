## QuestSystem - Sistema de quests dinâmicas
## Gera quests baseadas nos problemas da cidade e gerencia progresso
class_name QuestSystem
extends Node

# Enums para tipos de quest
enum QuestType {
	FETCH,        # Buscar/coletar itens
	ELIMINATE,    # Eliminar inimigos/ameaças
	ESCORT,       # Escoltar NPCs
	BUILD,        # Construir estruturas
	INVESTIGATE,  # Investigar locais/eventos
	DEFEND,       # Defender local
	TRADE,        # Negociar com facções
	REPAIR        # Reparar estruturas
}

# Enums para status de quest
enum QuestStatus {
	AVAILABLE,    # Disponível para aceitar
	ACTIVE,       # Aceita e em progresso
	COMPLETED,    # Completada
	FAILED,       # Falhada
	ABANDONED     # Abandonada
}

# Enums para dificuldade
enum QuestDifficulty {
	EASY,
	MEDIUM,
	HARD,
	VERY_HARD
}

# Classe para objetivos de quest
class QuestObjective:
	var id: String
	var description: String
	var type: String  # "collect", "kill", "reach", "build", etc
	var target: String
	var current_progress: int = 0
	var required_progress: int = 1
	var is_complete: bool = false
	var is_optional: bool = false
	
	func _init(p_id: String, p_desc: String, p_type: String, p_target: String, p_required: int):
		id = p_id
		description = p_desc
		type = p_type
		target = p_target
		required_progress = p_required
	
	func update_progress(amount: int) -> void:
		current_progress = mini(current_progress + amount, required_progress)
		if current_progress >= required_progress:
			is_complete = true
	
	func get_progress_percentage() -> float:
		return (float(current_progress) / float(required_progress)) * 100.0
	
	func _to_string() -> String:
		return "Objective(%s: %d/%d)" % [description, current_progress, required_progress]

# Classe para recompensas
class QuestReward:
	var caps: int = 0
	var experience: int = 0
	var items: Dictionary = {}  # item_id -> quantity
	var resources: Dictionary = {}  # ResourceType -> amount
	var reputation: Dictionary = {}  # faction_id -> amount
	var unlocks: Array[String] = []  # IDs de receitas, áreas, etc
	
	func _init():
		pass
	
	func _to_string() -> String:
		return "Reward(caps=%d, xp=%d, items=%d)" % [caps, experience, items.size()]

# Classe principal de Quest
class Quest:
	var id: String
	var title: String
	var description: String
	var type: QuestType
	var difficulty: QuestDifficulty
	var status: QuestStatus = QuestStatus.AVAILABLE
	var objectives: Array[QuestObjective] = []
	var rewards: QuestReward
	var giver_id: int = -1  # ID do NPC que dá a quest
	var giver_faction: int = -1
	var location: Vector2i = Vector2i.ZERO
	var time_limit: float = 0.0  # 0 = sem limite
	var time_elapsed: float = 0.0
	var is_repeatable: bool = false
	var required_level: int = 1
	var required_reputation: Dictionary = {}  # faction_id -> min_reputation
	var next_quest_id: String = ""  # Para quest chains
	var branch_quests: Dictionary = {}  # outcome -> quest_id
	var source: String = ""  # "resource_shortage", "raid", "citizen_request", etc
	
	func _init(p_id: String, p_title: String, p_type: QuestType):
		id = p_id
		title = p_title
		type = p_type
		rewards = QuestReward.new()
	
	func add_objective(objective: QuestObjective) -> void:
		objectives.append(objective)
	
	func update_objective(objective_id: String, progress: int) -> bool:
		for obj in objectives:
			if obj.id == objective_id:
				obj.update_progress(progress)
				return true
		return false
	
	func are_all_objectives_complete() -> bool:
		for obj in objectives:
			if not obj.is_optional and not obj.is_complete:
				return false
		return true
	
	func get_progress_percentage() -> float:
		if objectives.is_empty():
			return 0.0
		
		var total = 0.0
		var completed = 0.0
		
		for obj in objectives:
			if not obj.is_optional:
				total += 1.0
				if obj.is_complete:
					completed += 1.0
		
		return (completed / total) * 100.0 if total > 0 else 0.0
	
	func update_time(delta: float) -> void:
		if time_limit > 0:
			time_elapsed += delta
	
	func is_time_expired() -> bool:
		return time_limit > 0 and time_elapsed >= time_limit
	
	func _to_string() -> String:
		return "Quest(%s, %s, %d%%)" % [title, QuestStatus.keys()[status], get_progress_percentage()]

# Variáveis do sistema
var quests: Dictionary = {}  # quest_id -> Quest
var active_quests: Array[String] = []
var completed_quests: Array[String] = []
var failed_quests: Array[String] = []
var available_quests: Array[String] = []
var next_quest_id: int = 0

var event_bus: CityEventBus
var economy_system: EconomySystem
var citizen_system: CitizenSystem
var faction_system: FactionSystem
var building_system: BuildingSystem

# Configurações de geração
var quest_generation_enabled: bool = true
var quest_generation_interval: float = 300.0  # 5 minutos
var time_since_last_generation: float = 0.0
var max_active_quests: int = 10
var max_available_quests: int = 20

func _ready() -> void:
	event_bus = get_tree().root.get_child(0).get_node_or_null("EventBus")
	economy_system = get_tree().root.get_child(0).get_node_or_null("EconomySystem")
	citizen_system = get_tree().root.get_child(0).get_node_or_null("CitizenSystem")
	faction_system = get_tree().root.get_child(0).get_node_or_null("FactionSystem")
	building_system = get_tree().root.get_child(0).get_node_or_null("BuildingSystem")
	
	_connect_signals()

func _process(delta: float) -> void:
	_update_active_quests(delta)
	_check_quest_generation(delta)

func _connect_signals() -> void:
	"""Conecta aos sinais de outros sistemas para gerar quests"""
	if event_bus:
		event_bus.resource_shortage.connect(_on_resource_shortage)
		event_bus.raid_started.connect(_on_raid_started)
		event_bus.building_destroyed.connect(_on_building_destroyed)
		event_bus.citizen_need_critical.connect(_on_citizen_need_critical)

# =============================================================================
# QUEST GENERATION
# =============================================================================

func _check_quest_generation(delta: float) -> void:
	"""Verifica se deve gerar novas quests"""
	if not quest_generation_enabled:
		return
	
	time_since_last_generation += delta
	
	if time_since_last_generation >= quest_generation_interval:
		time_since_last_generation = 0.0
		_generate_random_quest()

func _generate_random_quest() -> void:
	"""Gera uma quest aleatória baseada no estado da cidade"""
	if available_quests.size() >= max_available_quests:
		return
	
	# Escolhe tipo aleatório
	var quest_types = [
		QuestType.FETCH,
		QuestType.ELIMINATE,
		QuestType.BUILD,
		QuestType.INVESTIGATE
	]
	
	var type = quest_types[randi() % quest_types.size()]
	
	match type:
		QuestType.FETCH:
			_generate_fetch_quest()
		QuestType.ELIMINATE:
			_generate_eliminate_quest()
		QuestType.BUILD:
			_generate_build_quest()
		QuestType.INVESTIGATE:
			_generate_investigate_quest()

func _generate_fetch_quest() -> Quest:
	"""Gera uma quest de coleta"""
	var quest_id = "fetch_%d" % next_quest_id
	next_quest_id += 1
	
	var resources = [
		CityConfig.ResourceType.FOOD,
		CityConfig.ResourceType.WATER,
		CityConfig.ResourceType.MATERIALS,
		CityConfig.ResourceType.MEDICINE
	]
	
	var resource = resources[randi() % resources.size()]
	var amount = randi_range(10, 50)
	
	var quest = Quest.new(quest_id, "Gather Resources", QuestType.FETCH)
	quest.description = "The settlement needs resources. Gather %d units." % amount
	quest.difficulty = QuestDifficulty.EASY
	quest.source = "resource_shortage"
	
	var objective = QuestObjective.new(
		"collect_resource",
		"Collect %d resources" % amount,
		"collect",
		str(resource),
		amount
	)
	quest.add_objective(objective)
	
	# Recompensas
	quest.rewards.caps = amount * 2
	quest.rewards.experience = amount
	quest.rewards.reputation[0] = 5  # Facção principal
	
	_register_quest(quest)
	return quest

func _generate_eliminate_quest() -> Quest:
	"""Gera uma quest de eliminação"""
	var quest_id = "eliminate_%d" % next_quest_id
	next_quest_id += 1
	
	var enemies = ["Raiders", "Mutants", "Feral Ghouls", "Hostile Robots"]
	var enemy = enemies[randi() % enemies.size()]
	var count = randi_range(3, 10)
	
	var quest = Quest.new(quest_id, "Clear Threat", QuestType.ELIMINATE)
	quest.description = "Eliminate %d %s threatening the settlement." % [count, enemy]
	quest.difficulty = QuestDifficulty.MEDIUM
	quest.source = "threat"
	
	var objective = QuestObjective.new(
		"eliminate_enemies",
		"Eliminate %d %s" % [count, enemy],
		"kill",
		enemy,
		count
	)
	quest.add_objective(objective)
	
	# Recompensas
	quest.rewards.caps = count * 10
	quest.rewards.experience = count * 5
	quest.rewards.reputation[0] = 10
	
	_register_quest(quest)
	return quest

func _generate_build_quest() -> Quest:
	"""Gera uma quest de construção"""
	var quest_id = "build_%d" % next_quest_id
	next_quest_id += 1
	
	var buildings = [
		"Water Tower",
		"Guard Tower",
		"Workshop",
		"Medical Clinic"
	]
	
	var building = buildings[randi() % buildings.size()]
	
	var quest = Quest.new(quest_id, "Expand Settlement", QuestType.BUILD)
	quest.description = "Build a %s to improve the settlement." % building
	quest.difficulty = QuestDifficulty.MEDIUM
	quest.source = "expansion"
	
	var objective = QuestObjective.new(
		"build_structure",
		"Build a %s" % building,
		"build",
		building,
		1
	)
	quest.add_objective(objective)
	
	# Recompensas
	quest.rewards.caps = 100
	quest.rewards.experience = 50
	quest.rewards.reputation[0] = 15
	
	_register_quest(quest)
	return quest

func _generate_investigate_quest() -> Quest:
	"""Gera uma quest de investigação"""
	var quest_id = "investigate_%d" % next_quest_id
	next_quest_id += 1
	
	var locations = [
		"Abandoned Vault",
		"Old Military Base",
		"Ruined City",
		"Strange Signal Source"
	]
	
	var location = locations[randi() % locations.size()]
	
	var quest = Quest.new(quest_id, "Investigate Location", QuestType.INVESTIGATE)
	quest.description = "Investigate the %s and report findings." % location
	quest.difficulty = QuestDifficulty.HARD
	quest.source = "exploration"
	
	var objective = QuestObjective.new(
		"reach_location",
		"Reach the %s" % location,
		"reach",
		location,
		1
	)
	quest.add_objective(objective)
	
	var objective2 = QuestObjective.new(
		"search_area",
		"Search the area",
		"search",
		location,
		1
	)
	quest.add_objective(objective2)
	
	# Recompensas
	quest.rewards.caps = 150
	quest.rewards.experience = 100
	quest.rewards.reputation[0] = 20
	quest.rewards.unlocks.append("new_location")
	
	_register_quest(quest)
	return quest

func _register_quest(quest: Quest) -> void:
	"""Registra uma quest no sistema"""
	quests[quest.id] = quest
	available_quests.append(quest.id)
	
	if event_bus:
		event_bus.quest_generated.emit(quest.id, quest.type, quest.source)

# =============================================================================
# QUEST MANAGEMENT
# =============================================================================

func get_quest(quest_id: String) -> Quest:
	"""Obtém uma quest"""
	return quests.get(quest_id)

func get_available_quests() -> Array[Quest]:
	"""Obtém quests disponíveis"""
	var result: Array[Quest] = []
	for quest_id in available_quests:
		if quests.has(quest_id):
			result.append(quests[quest_id])
	return result

func get_active_quests() -> Array[Quest]:
	"""Obtém quests ativas"""
	var result: Array[Quest] = []
	for quest_id in active_quests:
		if quests.has(quest_id):
			result.append(quests[quest_id])
	return result

func get_completed_quests() -> Array[Quest]:
	"""Obtém quests completadas"""
	var result: Array[Quest] = []
	for quest_id in completed_quests:
		if quests.has(quest_id):
			result.append(quests[quest_id])
	return result

func can_accept_quest(quest_id: String, player_level: int = 1) -> bool:
	"""Verifica se uma quest pode ser aceita"""
	if not quests.has(quest_id):
		return false
	
	var quest = quests[quest_id]
	
	# Verifica status
	if quest.status != QuestStatus.AVAILABLE:
		return false
	
	# Verifica limite de quests ativas
	if active_quests.size() >= max_active_quests:
		return false
	
	# Verifica nível
	if player_level < quest.required_level:
		return false
	
	# Verifica reputação (se houver sistema de facções)
	if faction_system:
		for faction_id in quest.required_reputation:
			var required_rep = quest.required_reputation[faction_id]
			var current_rep = faction_system.get_player_reputation(faction_id)
			if current_rep < required_rep:
				return false
	
	return true

func accept_quest(quest_id: String) -> bool:
	"""Aceita uma quest"""
	if not can_accept_quest(quest_id):
		return false
	
	var quest = quests[quest_id]
	quest.status = QuestStatus.ACTIVE
	
	available_quests.erase(quest_id)
	active_quests.append(quest_id)
	
	if event_bus:
		event_bus.quest_accepted.emit(quest_id)
	
	return true

func abandon_quest(quest_id: String) -> bool:
	"""Abandona uma quest"""
	if not quests.has(quest_id):
		return false
	
	var quest = quests[quest_id]
	if quest.status != QuestStatus.ACTIVE:
		return false
	
	quest.status = QuestStatus.ABANDONED
	active_quests.erase(quest_id)
	
	if event_bus:
		event_bus.quest_abandoned.emit(quest_id)
	
	return true

func update_quest_objective(quest_id: String, objective_id: String, progress: int) -> bool:
	"""Atualiza o progresso de um objetivo"""
	if not quests.has(quest_id):
		return false
	
	var quest = quests[quest_id]
	if quest.status != QuestStatus.ACTIVE:
		return false
	
	var updated = quest.update_objective(objective_id, progress)
	
	if updated and event_bus:
		event_bus.quest_objective_updated.emit(quest_id, objective_id, progress)
		
		# Verifica se o objetivo foi completado
		for obj in quest.objectives:
			if obj.id == objective_id and obj.is_complete:
				event_bus.quest_objective_completed.emit(quest_id, objective_id)
	
	# Verifica se a quest foi completada
	if quest.are_all_objectives_complete():
		complete_quest(quest_id)
	
	return updated

func complete_quest(quest_id: String) -> bool:
	"""Completa uma quest"""
	if not quests.has(quest_id):
		return false
	
	var quest = quests[quest_id]
	if quest.status != QuestStatus.ACTIVE:
		return false
	
	quest.status = QuestStatus.COMPLETED
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	
	# Aplica recompensas
	_apply_rewards(quest)
	
	if event_bus:
		event_bus.quest_completed.emit(quest_id, quest.rewards)
	
	# Verifica quest chains
	if not quest.next_quest_id.is_empty():
		_unlock_next_quest(quest.next_quest_id)
	
	return true

func fail_quest(quest_id: String, reason: String = "") -> bool:
	"""Falha uma quest"""
	if not quests.has(quest_id):
		return false
	
	var quest = quests[quest_id]
	if quest.status != QuestStatus.ACTIVE:
		return false
	
	quest.status = QuestStatus.FAILED
	active_quests.erase(quest_id)
	failed_quests.append(quest_id)
	
	if event_bus:
		event_bus.quest_failed.emit(quest_id, reason)
	
	return true

func _update_active_quests(delta: float) -> void:
	"""Atualiza quests ativas"""
	var expired_quests: Array[String] = []
	
	for quest_id in active_quests:
		if not quests.has(quest_id):
			continue
		
		var quest = quests[quest_id]
		quest.update_time(delta)
		
		if quest.is_time_expired():
			expired_quests.append(quest_id)
	
	# Falha quests expiradas
	for quest_id in expired_quests:
		fail_quest(quest_id, "Time expired")

func _apply_rewards(quest: Quest) -> void:
	"""Aplica as recompensas de uma quest"""
	var rewards = quest.rewards
	
	# Adiciona recursos
	if economy_system:
		if rewards.caps > 0:
			economy_system.add_resource(CityConfig.ResourceType.CAPS, rewards.caps)
		
		for resource_type in rewards.resources:
			var amount = rewards.resources[resource_type]
			economy_system.add_resource(resource_type, amount)
	
	# Adiciona reputação
	if faction_system:
		for faction_id in rewards.reputation:
			var amount = rewards.reputation[faction_id]
			faction_system.modify_player_reputation(faction_id, amount)
	
	# Desbloqueia conteúdo
	for unlock_id in rewards.unlocks:
		_unlock_content(unlock_id)

func _unlock_content(unlock_id: String) -> void:
	"""Desbloqueia conteúdo (receitas, áreas, etc)"""
	# Implementação básica - expandir conforme necessário
	pass

func _unlock_next_quest(quest_id: String) -> void:
	"""Desbloqueia a próxima quest em uma chain"""
	if quests.has(quest_id):
		var quest = quests[quest_id]
		quest.status = QuestStatus.AVAILABLE
		available_quests.append(quest_id)

# =============================================================================
# QUEST CHAINS
# =============================================================================

func create_quest_chain(quests_data: Array[Dictionary]) -> Array[String]:
	"""Cria uma cadeia de quests"""
	var chain_ids: Array[String] = []
	
	for i in range(quests_data.size()):
		var data = quests_data[i]
		var quest = _create_quest_from_data(data)
		
		if i < quests_data.size() - 1:
			quest.next_quest_id = "chain_quest_%d" % (next_quest_id + 1)
		
		chain_ids.append(quest.id)
	
	if event_bus and not chain_ids.is_empty():
		event_bus.quest_chain_started.emit(0, chain_ids[0])
	
	return chain_ids

func _create_quest_from_data(data: Dictionary) -> Quest:
	"""Cria uma quest a partir de dados"""
	var quest_id = data.get("id", "quest_%d" % next_quest_id)
	next_quest_id += 1
	
	var quest = Quest.new(quest_id, data.get("title", "Quest"), data.get("type", QuestType.FETCH))
	quest.description = data.get("description", "")
	quest.difficulty = data.get("difficulty", QuestDifficulty.MEDIUM)
	
	_register_quest(quest)
	return quest

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_resource_shortage(resource_type: int, needed: float, available: float) -> void:
	"""Gera quest quando há escassez de recursos"""
	var quest = _generate_fetch_quest()
	quest.source = "resource_shortage"

func _on_raid_started(raid_id: int, attacker_faction: int, strength: float) -> void:
	"""Gera quest de defesa quando há raid"""
	var quest = _generate_eliminate_quest()
	quest.source = "raid"
	quest.time_limit = 600.0  # 10 minutos

func _on_building_destroyed(building_id: int, position: Vector2i) -> void:
	"""Gera quest de reconstrução quando edifício é destruído"""
	var quest = _generate_build_quest()
	quest.source = "reconstruction"

func _on_citizen_need_critical(citizen_id: int, need_type: int, value: float) -> void:
	"""Gera quest quando cidadão tem necessidade crítica"""
	if randf() < 0.3:  # 30% de chance
		_generate_fetch_quest()

# =============================================================================
# STATISTICS
# =============================================================================

func get_quest_count() -> int:
	"""Obtém o número total de quests"""
	return quests.size()

func get_active_quest_count() -> int:
	"""Obtém o número de quests ativas"""
	return active_quests.size()

func get_completed_quest_count() -> int:
	"""Obtém o número de quests completadas"""
	return completed_quests.size()

func get_completion_rate() -> float:
	"""Obtém a taxa de conclusão de quests"""
	var total = completed_quests.size() + failed_quests.size()
	if total == 0:
		return 0.0
	return (float(completed_quests.size()) / float(total)) * 100.0

func get_quest_stats() -> Dictionary:
	"""Obtém estatísticas do sistema de quests"""
	return {
		"total_quests": get_quest_count(),
		"available": available_quests.size(),
		"active": active_quests.size(),
		"completed": completed_quests.size(),
		"failed": failed_quests.size(),
		"completion_rate": get_completion_rate(),
		"quests_by_type": _get_quests_by_type_stats()
	}

func _get_quests_by_type_stats() -> Dictionary:
	"""Obtém estatísticas de quests por tipo"""
	var stats = {}
	for type in QuestType.values():
		stats[type] = 0
	
	for quest in quests.values():
		stats[quest.type] += 1
	
	return stats

# =============================================================================
# SERIALIZATION
# =============================================================================

func serialize() -> Dictionary:
	"""Serializa o estado do sistema de quests"""
	var quest_data: Array[Dictionary] = []
	
	for quest in quests.values():
		var objectives_data: Array[Dictionary] = []
		for obj in quest.objectives:
			objectives_data.append({
				"id": obj.id,
				"description": obj.description,
				"type": obj.type,
				"target": obj.target,
				"current_progress": obj.current_progress,
				"required_progress": obj.required_progress,
				"is_complete": obj.is_complete,
				"is_optional": obj.is_optional
			})
		
		quest_data.append({
			"id": quest.id,
			"title": quest.title,
			"description": quest.description,
			"type": quest.type,
			"difficulty": quest.difficulty,
			"status": quest.status,
			"objectives": objectives_data,
			"time_elapsed": quest.time_elapsed,
			"source": quest.source
		})
	
	return {
		"quests": quest_data,
		"active_quests": active_quests.duplicate(),
		"completed_quests": completed_quests.duplicate(),
		"failed_quests": failed_quests.duplicate(),
		"available_quests": available_quests.duplicate(),
		"next_quest_id": next_quest_id
	}

func deserialize(data: Dictionary) -> void:
	"""Desserializa o estado do sistema de quests"""
	quests.clear()
	active_quests.clear()
	completed_quests.clear()
	failed_quests.clear()
	available_quests.clear()
	
	next_quest_id = data.get("next_quest_id", 0)
	active_quests = data.get("active_quests", [])
	completed_quests = data.get("completed_quests", [])
	failed_quests = data.get("failed_quests", [])
	available_quests = data.get("available_quests", [])
	
	for quest_data in data.get("quests", []):
		var quest = Quest.new(
			quest_data["id"],
			quest_data["title"],
			quest_data["type"]
		)
		
		quest.description = quest_data.get("description", "")
		quest.difficulty = quest_data.get("difficulty", QuestDifficulty.MEDIUM)
		quest.status = quest_data.get("status", QuestStatus.AVAILABLE)
		quest.time_elapsed = quest_data.get("time_elapsed", 0.0)
		quest.source = quest_data.get("source", "")
		
		for obj_data in quest_data.get("objectives", []):
			var obj = QuestObjective.new(
				obj_data["id"],
				obj_data["description"],
				obj_data["type"],
				obj_data["target"],
				obj_data["required_progress"]
			)
			obj.current_progress = obj_data.get("current_progress", 0)
			obj.is_complete = obj_data.get("is_complete", false)
			obj.is_optional = obj_data.get("is_optional", false)
			quest.add_objective(obj)
		
		quests[quest.id] = quest
