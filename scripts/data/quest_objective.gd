extends Resource
class_name QuestObjective
## Objetivo de uma quest

enum ObjectiveType {
	KILL,           # Matar um alvo
	COLLECT,        # Coletar item
	DELIVER,        # Entregar item
	TALK,           # Falar com NPC
	GO_TO,          # Ir para localização
	USE,            # Usar objeto
	PROTECT,        # Proteger NPC/localização
	ESCAPE,         # Escapar de área
	INVESTIGATE,    # Investigar área
	CUSTOM          # Objetivo customizado
}

enum ObjectiveState {
	INCOMPLETE,     # Não completado
	COMPLETE,       # Completado
	FAILED          # Falhou
}

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var objective_type: ObjectiveType = ObjectiveType.CUSTOM
@export var state: ObjectiveState = ObjectiveState.INCOMPLETE
@export var target_id: String = ""  # ID do alvo (NPC, item, location, etc)
@export var target_name: String = ""  # Nome do alvo para exibição
@export var required_count: int = 1  # Quantidade necessária
@export var current_count: int = 0   # Quantidade atual
@export var is_optional: bool = false  # Se o objetivo é opcional
@export var is_hidden: bool = false    # Se o objetivo está oculto até ser descoberto

## Verifica se o objetivo está completo
func is_complete() -> bool:
	return state == ObjectiveState.COMPLETE

## Verifica se o objetivo falhou
func is_failed() -> bool:
	return state == ObjectiveState.FAILED

## Marca o objetivo como completo
func complete() -> void:
	if state != ObjectiveState.FAILED:
		state = ObjectiveState.COMPLETE
		current_count = required_count

## Marca o objetivo como falhado
func fail() -> void:
	state = ObjectiveState.FAILED

## Atualiza o progresso do objetivo
func update_progress(amount: int = 1) -> void:
	if state == ObjectiveState.FAILED:
		return
	
	current_count = min(current_count + amount, required_count)
	
	if current_count >= required_count:
		complete()

## Retorna o progresso como porcentagem
func get_progress_percentage() -> float:
	if required_count <= 0:
		return 1.0
	return float(current_count) / float(required_count)

## Retorna o texto de progresso formatado
func get_progress_text() -> String:
	if is_complete():
		return "%s (Completo)" % title
	elif is_failed():
		return "%s (Falhou)" % title
	elif required_count > 1:
		return "%s (%d/%d)" % [title, current_count, required_count]
	else:
		return title
