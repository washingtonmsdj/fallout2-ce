extends Node
class_name QuestSystem
## Sistema de gerenciamento de quests

signal quest_added(quest: Quest)
signal quest_updated(quest: Quest)
signal quest_completed(quest: Quest)
signal quest_failed(quest: Quest)
signal objective_completed(quest: Quest, objective: QuestObjective)
signal objective_updated(quest: Quest, objective: QuestObjective)

var active_quests: Array[Quest] = []
var completed_quests: Array[Quest] = []
var failed_quests: Array[Quest] = []
var inactive_quests: Array[Quest] = []

var player: Critter = null

## Define o jogador para aplicar recompensas
func set_player(player_critter: Critter) -> void:
	player = player_critter

## Adiciona uma quest ao sistema
func add_quest(quest: Quest) -> void:
	if not quest:
		push_error("QuestSystem: Cannot add null quest")
		return
	
	# Verifica se a quest já existe
	if has_quest(quest.id):
		push_warning("QuestSystem: Quest '%s' already exists" % quest.id)
		return
	
	# Verifica pré-requisitos
	if not _check_prerequisites(quest):
		inactive_quests.append(quest)
		return
	
	# Adiciona como ativa
	quest.activate()
	active_quests.append(quest)
	quest_added.emit(quest)
	quest_updated.emit(quest)

## Verifica se uma quest existe
func has_quest(quest_id: String) -> bool:
	return get_quest(quest_id) != null

## Obtém uma quest pelo ID
func get_quest(quest_id: String) -> Quest:
	# Procura em todas as listas
	for quest in active_quests:
		if quest and quest.id == quest_id:
			return quest
	
	for quest in completed_quests:
		if quest and quest.id == quest_id:
			return quest
	
	for quest in failed_quests:
		if quest and quest.id == quest_id:
			return quest
	
	for quest in inactive_quests:
		if quest and quest.id == quest_id:
			return quest
	
	return null

## Atualiza um objetivo de uma quest
func update_objective(quest_id: String, objective_id: String, progress: int = 1) -> bool:
	var quest = get_quest(quest_id)
	if not quest:
		push_warning("QuestSystem: Quest '%s' not found" % quest_id)
		return false
	
	if not quest.is_active():
		push_warning("QuestSystem: Quest '%s' is not active" % quest_id)
		return false
	
	var objective = quest.get_objective(objective_id)
	if not objective:
		push_warning("QuestSystem: Objective '%s' not found in quest '%s'" % [objective_id, quest_id])
		return false
	
	var was_complete = objective.is_complete()
	quest.update_objective(objective_id, progress)
	
	objective_updated.emit(quest, objective)
	
	# Se o objetivo foi completado agora
	if objective.is_complete() and not was_complete:
		objective_completed.emit(quest, objective)
		
		# Verifica se a quest pode ser completada
		if quest.are_all_objectives_complete():
			complete_quest(quest_id)
	
	quest_updated.emit(quest)
	return true

## Completa uma quest
func complete_quest(quest_id: String) -> bool:
	var quest = get_quest(quest_id)
	if not quest:
		push_warning("QuestSystem: Quest '%s' not found" % quest_id)
		return false
	
	if not quest.is_active():
		push_warning("QuestSystem: Quest '%s' is not active" % quest_id)
		return false
	
	# Marca como completa
	quest.complete()
	
	# Move para lista de completas
	active_quests.erase(quest)
	completed_quests.append(quest)
	
	# Aplica recompensas
	_apply_rewards(quest.rewards)
	
	quest_completed.emit(quest)
	quest_updated.emit(quest)
	
	# Verifica se há quests inativas que podem ser ativadas agora
	_check_inactive_quests()
	
	return true

## Falha uma quest
func fail_quest(quest_id: String) -> bool:
	var quest = get_quest(quest_id)
	if not quest:
		push_warning("QuestSystem: Quest '%s' not found" % quest_id)
		return false
	
	if not quest.is_active():
		push_warning("QuestSystem: Quest '%s' is not active" % quest_id)
		return false
	
	# Marca como falhada
	quest.fail()
	
	# Marca todos os objetivos como falhados
	for objective in quest.objectives:
		if objective and not objective.is_complete():
			objective.fail()
	
	# Move para lista de falhadas
	active_quests.erase(quest)
	failed_quests.append(quest)
	
	# Aplica recompensas de falha (se houver)
	if quest.failure_rewards:
		_apply_rewards(quest.failure_rewards)
	
	quest_failed.emit(quest)
	quest_updated.emit(quest)
	
	return true

## Aplica recompensas de uma quest
func _apply_rewards(rewards: Quest.QuestRewards) -> void:
	if not player or not rewards:
		return
	
	# Experiência
	if rewards.experience > 0:
		player.experience += rewards.experience
		# TODO: Verificar level up
	
	# Caps (dinheiro)
	if rewards.caps > 0:
		# TODO: Adicionar ao inventário quando sistema de inventário estiver pronto
		pass
	
	# Itens
	for item_id in rewards.items:
		# TODO: Adicionar itens ao inventário quando sistema estiver pronto
		pass
	
	# Karma
	if rewards.karma != 0:
		player.karma += rewards.karma
	
	# Reputação
	for faction in rewards.reputation_changes:
		var amount = rewards.reputation_changes[faction]
		# TODO: Aplicar mudança de reputação quando sistema estiver pronto
		pass

## Verifica pré-requisitos de uma quest
func _check_prerequisites(quest: Quest) -> bool:
	if quest.prerequisites.is_empty():
		return true
	
	for prereq_id in quest.prerequisites:
		var prereq = get_quest(prereq_id)
		if not prereq or not prereq.is_completed():
			return false
	
	return true

## Verifica se há quests inativas que podem ser ativadas
func _check_inactive_quests() -> void:
	var to_activate: Array[Quest] = []
	
	for quest in inactive_quests:
		if _check_prerequisites(quest):
			to_activate.append(quest)
	
	for quest in to_activate:
		inactive_quests.erase(quest)
		quest.activate()
		active_quests.append(quest)
		quest_added.emit(quest)
		quest_updated.emit(quest)

## Obtém todas as quests ativas
func get_active_quests() -> Array[Quest]:
	return active_quests.duplicate()

## Obtém todas as quests completas
func get_completed_quests() -> Array[Quest]:
	return completed_quests.duplicate()

## Obtém todas as quests falhadas
func get_failed_quests() -> Array[Quest]:
	return failed_quests.duplicate()

## Obtém todas as quests (de todos os estados)
func get_all_quests() -> Array[Quest]:
	var all: Array[Quest] = []
	all.append_array(active_quests)
	all.append_array(completed_quests)
	all.append_array(failed_quests)
	all.append_array(inactive_quests)
	return all

## Verifica se uma quest está ativa
func is_quest_active(quest_id: String) -> bool:
	var quest = get_quest(quest_id)
	return quest != null and quest.is_active()

## Verifica se uma quest está completa
func is_quest_completed(quest_id: String) -> bool:
	var quest = get_quest(quest_id)
	return quest != null and quest.is_completed()

## Verifica se uma quest falhou
func is_quest_failed(quest_id: String) -> bool:
	var quest = get_quest(quest_id)
	return quest != null and quest.is_failed()

## Limpa todas as quests (útil para resetar o jogo)
func clear_all_quests() -> void:
	active_quests.clear()
	completed_quests.clear()
	failed_quests.clear()
	inactive_quests.clear()
