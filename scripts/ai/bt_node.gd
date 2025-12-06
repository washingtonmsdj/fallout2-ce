extends Resource
class_name BTNode
## Nó base para árvore de comportamento

## Status de execução do nó
enum BTStatus {
	SUCCESS,
	FAILURE,
	RUNNING
}

var children: Array[BTNode] = []
var parent: BTNode = null

## Executa o nó
func tick(context: Dictionary) -> int:
	return BTStatus.FAILURE

## Adiciona um nó filho
func add_child(child: BTNode) -> void:
	if child == null:
		return
	
	children.append(child)
	child.parent = self

## Remove um nó filho
func remove_child(child: BTNode) -> void:
	if child in children:
		children.erase(child)
		child.parent = null

## Limpa todos os filhos
func clear_children() -> void:
	for child in children:
		child.parent = null
	children.clear()
