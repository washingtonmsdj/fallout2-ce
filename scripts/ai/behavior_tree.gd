extends Resource
class_name BehaviorTree
## Árvore de comportamento para IA

var root: BTNode = null

## Executa a árvore de comportamento
func tick(context: Dictionary) -> BTStatus:
	if root == null:
		return BTStatus.FAILURE
	
	return root.tick(context)

## Define o nó raiz da árvore
func set_root(node: BTNode) -> void:
	root = node
