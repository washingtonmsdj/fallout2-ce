extends BTNode
class_name BTSequence
## Nó sequência - retorna SUCCESS apenas se todos os filhos retornam SUCCESS

## Executa a sequência
func tick(context: Dictionary) -> int:
	for child in children:
		var result = child.tick(context)
		
		if result == BTStatus.FAILURE:
			return BTStatus.FAILURE
		elif result == BTStatus.RUNNING:
			return BTStatus.RUNNING
	
	return BTStatus.SUCCESS
