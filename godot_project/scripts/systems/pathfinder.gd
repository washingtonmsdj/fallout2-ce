extends Node

## Sistema de Pathfinding A* para Grade Hexagonal
## Baseado no sistema original do Fallout 2
## Suporta múltiplas elevações e detecção de obstáculos

# Estrutura de nó para A*
class PathNode:
	var position: Vector2i
	var elevation: int
	var g_cost: float = INF  # Custo do início até este nó
	var h_cost: float = 0.0  # Heurística (estimativa até o fim)
	var f_cost: float = INF  # g_cost + h_cost
	var parent: PathNode = null
	var is_walkable: bool = true
	
	func _init(pos: Vector2i, elev: int = 0):
		position = pos
		elevation = elev
	
	func calculate_f_cost():
		f_cost = g_cost + h_cost

# Referências
var renderer: Node = null
var map_system: Node = null

# Cache de obstáculos
var obstacle_cache: Dictionary = {}  # {Vector2i: bool}
var temporary_obstacles: Array = []  # NPCs, etc.

func _ready():
	# Obter referências
	renderer = get_node_or_null("/root/IsometricRenderer")
	map_system = get_node_or_null("/root/MapSystem")
	
	if renderer == null:
		push_error("Pathfinder: IsometricRenderer não encontrado!")
	
	print("Pathfinder: Inicializado")

func find_path(start: Vector2i, end: Vector2i, elevation: int = 0) -> Array:
	"""
	Encontra caminho de start até end usando A*
	Retorna array de posições de tiles (vazio se impossível)
	"""
	# Validar posições
	if not renderer.is_valid_tile(start) or not renderer.is_valid_tile(end):
		return []
	
	# Se start == end, retornar caminho vazio
	if start == end:
		return []
	
	# Verificar se destino é walkable
	if not is_walkable(end, elevation):
		return []
	
	# Inicializar listas
	var open_list: Array = []
	var closed_set: Dictionary = {}  # {Vector2i: bool}
	var node_map: Dictionary = {}  # {Vector2i: PathNode}
	
	# Criar nó inicial
	var start_node = PathNode.new(start, elevation)
	start_node.g_cost = 0
	start_node.h_cost = _heuristic(start, end)
	start_node.calculate_f_cost()
	
	open_list.append(start_node)
	node_map[start] = start_node
	
	# Loop principal do A*
	while open_list.size() > 0:
		# Encontrar nó com menor f_cost
		var current = _get_lowest_f_cost_node(open_list)
		
		# Remover da open list e adicionar à closed
		open_list.erase(current)
		closed_set[current.position] = true
		
		# Chegou ao destino?
		if current.position == end:
			return _reconstruct_path(current)
		
		# Processar vizinhos
		var neighbors = _get_neighbors(current.position, elevation)
		for neighbor_pos in neighbors:
			# Pular se já foi processado
			if closed_set.has(neighbor_pos):
				continue
			
			# Pular se não é walkable
			if not is_walkable(neighbor_pos, elevation):
				continue
			
			# Calcular custo
			var movement_cost = get_movement_cost(current.position, neighbor_pos)
			var tentative_g_cost = current.g_cost + movement_cost
			
			# Obter ou criar nó do vizinho
			var neighbor_node: PathNode
			if node_map.has(neighbor_pos):
				neighbor_node = node_map[neighbor_pos]
			else:
				neighbor_node = PathNode.new(neighbor_pos, elevation)
				neighbor_node.h_cost = _heuristic(neighbor_pos, end)
				node_map[neighbor_pos] = neighbor_node
			
			# Se encontramos um caminho melhor
			if tentative_g_cost < neighbor_node.g_cost:
				neighbor_node.parent = current
				neighbor_node.g_cost = tentative_g_cost
				neighbor_node.calculate_f_cost()
				
				# Adicionar à open list se não estiver
				var already_in_list = false
				for node in open_list:
					if node.position == neighbor_node.position:
						already_in_list = true
						break
				if not already_in_list:
					open_list.append(neighbor_node)
	
	# Não encontrou caminho
	return []

func _heuristic(from: Vector2i, to: Vector2i) -> float:
	"""
	Heurística de distância hexagonal
	Usa distância de Manhattan adaptada para hex
	"""
	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	return float(max(dx, dy))

func _get_lowest_f_cost_node(nodes: Array) -> PathNode:
	"""Encontra o nó com menor f_cost na lista"""
	var lowest = nodes[0]
	for node in nodes:
		if node.f_cost < lowest.f_cost:
			lowest = node
	return lowest

func _get_neighbors(tile: Vector2i, elevation: int) -> Array:
	"""
	Retorna vizinhos válidos de um tile
	Usa as 6 direções hexagonais
	"""
	var neighbors: Array = []
	
	# 6 direções hexagonais (do IsometricRenderer)
	var hex_offsets = [
		Vector2i(1, -1),   # NE
		Vector2i(1, 0),    # E
		Vector2i(0, 1),    # SE
		Vector2i(-1, 1),   # SW
		Vector2i(-1, 0),   # W
		Vector2i(0, -1)    # NW
	]
	
	for offset in hex_offsets:
		var neighbor = tile + offset
		if renderer.is_valid_tile(neighbor):
			neighbors.append(neighbor)
	
	return neighbors

func _reconstruct_path(end_node: PathNode) -> Array:
	"""Reconstrói o caminho do fim até o início"""
	var path: Array = []
	var current = end_node
	
	while current != null:
		path.push_front(current.position)
		current = current.parent
	
	return path

func is_walkable(tile: Vector2i, elevation: int = 0) -> bool:
	"""
	Verifica se um tile é walkable
	Considera obstáculos permanentes e temporários
	"""
	# Verificar se está fora do mapa
	if not renderer.is_valid_tile(tile):
		return false
	
	# Verificar obstáculos temporários (NPCs)
	if temporary_obstacles.has(tile):
		return false
	
	# Verificar cache de obstáculos
	if obstacle_cache.has(tile):
		return not obstacle_cache[tile]
	
	# Verificar com MapSystem se disponível
	if map_system != null and map_system.has_method("is_tile_blocked"):
		var blocked = map_system.is_tile_blocked(tile, elevation)
		obstacle_cache[tile] = blocked
		return not blocked
	
	# Por padrão, considerar walkable
	return true

func get_movement_cost(from: Vector2i, to: Vector2i) -> float:
	"""
	Retorna o custo de movimento entre dois tiles adjacentes
	Custo base: 1.0 (1 AP no combate)
	"""
	# Custo base
	var cost = 1.0
	
	# Pode adicionar custos extras baseado em terreno
	# Por exemplo: água = 2.0, montanha = 3.0, etc.
	
	return cost

func set_obstacle(tile: Vector2i, blocked: bool):
	"""Define manualmente se um tile é obstáculo"""
	obstacle_cache[tile] = blocked

func add_temporary_obstacle(tile: Vector2i):
	"""Adiciona obstáculo temporário (ex: NPC)"""
	if not temporary_obstacles.has(tile):
		temporary_obstacles.append(tile)

func remove_temporary_obstacle(tile: Vector2i):
	"""Remove obstáculo temporário"""
	temporary_obstacles.erase(tile)

func clear_temporary_obstacles():
	"""Limpa todos os obstáculos temporários"""
	temporary_obstacles.clear()

func clear_obstacle_cache():
	"""Limpa o cache de obstáculos (útil ao mudar de mapa)"""
	obstacle_cache.clear()

func get_path_length(path: Array) -> int:
	"""Retorna o comprimento de um caminho"""
	return path.size()

func get_path_cost(path: Array) -> float:
	"""
	Calcula o custo total de um caminho
	Útil para calcular AP necessário
	"""
	if path.size() <= 1:
		return 0.0
	
	var total_cost = 0.0
	for i in range(path.size() - 1):
		total_cost += get_movement_cost(path[i], path[i + 1])
	
	return total_cost
