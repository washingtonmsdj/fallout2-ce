extends Resource
class_name DialogTree
## Árvore de diálogo contendo todos os nós e estrutura

@export var id: String = ""
@export var npc_id: String = ""
@export var npc_name: String = ""
@export var root_node_id: String = ""
@export var greeting_node_ids: Array[String] = []
@export var nodes: Dictionary = {}  # {node_id: DialogNode}

## Obtém um nó pelo ID
func get_node(node_id: String) -> DialogNode:
	if node_id in nodes:
		return nodes[node_id]
	return null

## Obtém o nó raiz
func get_root_node() -> DialogNode:
	return get_node(root_node_id)

## Obtém um nó de saudação apropriado para um personagem
func get_greeting(critter: Critter) -> DialogNode:
	if not critter:
		return get_root_node()
	
	# Procura por um nó de saudação disponível
	for greeting_id in greeting_node_ids:
		var node = get_node(greeting_id)
		if node and node.is_available(critter):
			return node
	
	# Retorna o nó raiz como fallback
	return get_root_node()

## Adiciona um nó à árvore
func add_node(node: DialogNode) -> void:
	if node and node.id:
		nodes[node.id] = node

## Remove um nó da árvore
func remove_node(node_id: String) -> void:
	if node_id in nodes:
		nodes.erase(node_id)

## Valida a integridade da árvore
func validate() -> Array[String]:
	var errors: Array[String] = []
	
	# Verifica se o nó raiz existe
	if not root_node_id or not root_node_id in nodes:
		errors.append("Root node '%s' not found" % root_node_id)
	
	# Verifica se todos os nós de saudação existem
	for greeting_id in greeting_node_ids:
		if not greeting_id in nodes:
			errors.append("Greeting node '%s' not found" % greeting_id)
	
	# Verifica se todas as referências de nós são válidas
	for node_id in nodes:
		var node = nodes[node_id]
		if not node:
			continue
		
		for option in node.options:
			if not option:
				continue
			
			var next_id = option.next_node_id
			if next_id and not next_id in nodes:
				errors.append("Option in node '%s' references non-existent node '%s'" % [node_id, next_id])
			
			if option.is_skill_check:
				var success_id = option.success_node_id
				var failure_id = option.failure_node_id
				
				if success_id and not success_id in nodes:
					errors.append("Skill check option in node '%s' references non-existent success node '%s'" % [node_id, success_id])
				
				if failure_id and not failure_id in nodes:
					errors.append("Skill check option in node '%s' references non-existent failure node '%s'" % [node_id, failure_id])
	
	return errors

## Retorna todas as IDs de nós
func get_all_node_ids() -> Array[String]:
	return nodes.keys()

## Retorna o número de nós
func get_node_count() -> int:
	return nodes.size()
