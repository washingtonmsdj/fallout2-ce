extends Resource
class_name Quest
## Quest do jogo

enum QuestState {
	INACTIVE,   # Quest não foi iniciada
	ACTIVE,     # Quest está ativa
	COMPLETED,  # Quest foi completada
	FAILED      # Quest falhou
}

## Estrutura de recompensas
class QuestRewards:
	var experience: int = 0
	var caps: int = 0
	var items: Array[String] = []  # IDs dos itens
	var karma: int = 0
	var reputation_changes: Dictionary = {}  # {faction: amount}
	
	func _init(exp: int = 0, caps_amount: int = 0, items_list: Array = [], karma_amount: int = 0, rep_changes: Dictionary = {}):
		experience = exp
		caps = caps_amount
		items = items_list
		karma = karma_amount
		reputation_changes = rep_changes

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var state: QuestState = QuestState.INACTIVE
@export var objectives: Array[QuestObjective] = []
@export var rewards: QuestRewards = QuestRewards.new()
@export var failure_rewards: QuestRewards = QuestRewards.new()  # Recompensas se falhar
@export var giver_id: String = ""  # ID do NPC que deu a quest
@export var turn_in_id: String = ""  # ID do NPC para entregar (pode ser diferente do giver)
@export var is_main_quest: bool = false
@export var is_repeatable: bool = false
@export var prerequisites: Array[String] = []  # IDs de quests que devem ser completadas primeiro
@export var completion_path: String = ""  # Caminho escolhido para completar (para quests com múltiplos caminhos)

## Verifica se a quest está ativa
func is_active() -> bool:
	return state == QuestState.ACTIVE

## Verifica se a quest está completa
func is_completed() -> bool:
	return state == QuestState.COMPLETED

## Verifica se a quest falhou
func is_failed() -> bool:
	return state == QuestState.FAILED

## Verifica se todos os objetivos obrigatórios estão completos
func are_all_objectives_complete() -> bool:
	if objectives.is_empty():
		return false
	
	for objective in objectives:
		if objective and not objective.is_optional and not objective.is_complete():
			return false
	
	return true

## Verifica se algum objetivo obrigatório falhou
func has_failed_objective() -> bool:
	for objective in objectives:
		if objective and not objective.is_optional and objective.is_failed():
			return true
	return false

## Obtém um objetivo pelo ID
func get_objective(objective_id: String) -> QuestObjective:
	for objective in objectives:
		if objective and objective.id == objective_id:
			return objective
	return null

## Obtém todos os objetivos completos
func get_completed_objectives() -> Array[QuestObjective]:
	var completed: Array[QuestObjective] = []
	for objective in objectives:
		if objective and objective.is_complete():
			completed.append(objective)
	return completed

## Obtém todos os objetivos incompletos
func get_incomplete_objectives() -> Array[QuestObjective]:
	var incomplete: Array[QuestObjective] = []
	for objective in objectives:
		if objective and not objective.is_complete() and not objective.is_failed():
			incomplete.append(objective)
	return incomplete

## Obtém todos os objetivos falhados
func get_failed_objectives() -> Array[QuestObjective]:
	var failed: Array[QuestObjective] = []
	for objective in objectives:
		if objective and objective.is_failed():
			failed.append(objective)
	return failed

## Atualiza um objetivo
func update_objective(objective_id: String, progress: int = 1) -> bool:
	var objective = get_objective(objective_id)
	if objective:
		objective.update_progress(progress)
		return true
	return false

## Marca a quest como ativa
func activate() -> void:
	if state == QuestState.INACTIVE:
		state = QuestState.ACTIVE

## Marca a quest como completa
func complete() -> void:
	if state == QuestState.ACTIVE:
		state = QuestState.COMPLETED

## Marca a quest como falhada
func fail() -> void:
	if state == QuestState.ACTIVE:
		state = QuestState.FAILED

## Retorna o progresso geral da quest como porcentagem
func get_progress_percentage() -> float:
	if objectives.is_empty():
		return 0.0
	
	var total_progress = 0.0
	var total_weight = 0.0
	
	for objective in objectives:
		if objective and not objective.is_optional:
			var weight = 1.0
			total_weight += weight
			total_progress += objective.get_progress_percentage() * weight
	
	if total_weight <= 0:
		return 0.0
	
	return total_progress / total_weight
