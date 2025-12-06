extends BTNode
class_name BTSelector
## Nó seletor - retorna SUCCESS se qualquer filho retorna SUCCESS

## Executa o seletor
func tick(context: Dictionary) -> int:
	for child in children:
		var result = child.tick(context)
		
		if result == BTStatus.SUCCESS:
			return BTStatus.SUCCESS
		elif result == BTStatus.RUNNING:
			return BTStatus.RUNNING
	
	return BTStatus.FAILURE
