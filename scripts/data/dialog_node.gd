extends Resource
class_name DialogNode
## Nó de diálogo contendo texto e opções

@export var id: String = ""
@export var speaker: String = ""
@export var text: String = ""
@export var options: Array[DialogOption] = []
@export var conditions: Array[DialogCondition] = []
@export var effects: Array[DialogEffect] = []
@export var is_greeting: bool = false
@export var is_end_node: bool = false

## Verifica se este nó pode ser exibido para um personagem
func is_available(critter: Critter) -> bool:
	if not critter:
		return false
	
	# Todas as condições devem ser atendidas
	for condition in conditions:
		if condition and not condition.evaluate(critter):
			return false
	
	return true

## Obtém as opções disponíveis para um personagem
func get_available_options(critter: Critter) -> Array[DialogOption]:
	var available: Array[DialogOption] = []
	
	if not critter:
		return available
	
	for option in options:
		if option and option.is_available(critter):
			available.append(option)
	
	return available

## Aplica os efeitos do nó
func apply_effects(critter: Critter) -> void:
	if not critter:
		return
	
	for effect in effects:
		if effect:
			effect.apply(critter)

## Retorna o texto do nó formatado
func get_display_text() -> String:
	var display = ""
	if speaker:
		display += "[%s]: " % speaker
	display += text
	return display
