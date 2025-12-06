extends BTNode
class_name BTAction
## Nó de ação - executa uma ação específica

var action_name: String = ""

## Executa a ação
func tick(context: Dictionary) -> int:
	if action_name.is_empty():
		return BTStatus.FAILURE
	
	# Chamar a ação no contexto
	if "actor" in context:
		var actor = context["actor"]
		if actor.has_method(action_name):
			var result = actor.call(action_name, context)
			if result is bool:
				return BTStatus.SUCCESS if result else BTStatus.FAILURE
			elif result is int:
				return result
	
	return BTStatus.FAILURE

## Define o nome da ação
func set_action(name: String) -> void:
	action_name = name
