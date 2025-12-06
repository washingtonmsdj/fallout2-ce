extends Node
class_name Pathfinding
## Sistema de pathfinding A* para movimento em tile-based

class PathNode:
	var position: Vector2i
	var g_cost: float  # Custo do início até este nó
	var h_cost: float  # Custo heurístico até o destino
	var f_cost: float  # g_cost + h_cost
	var parent: PathNode = null
	
	func _init(pos: Vector2i, g: float, h: float) -> void:
		position = pos
		g_cost = g
		h_cost = h
		f_cost = g + h

## Encontra um caminho usando A*
static func find_path(map: MapData, start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	if not map.is_valid_position(start) or not map.is_valid_position(end):
		return []
	
	if not map.is_walkable(end):
		return []
	
	var open_set: Array[PathNode] = []
	var closed_set: Array[Vector2i] = []
	
	# Nó inicial
	var start_node = PathNode.new(start, 0.0, _heuristic(start, end))
	open_set.append(start_node)
	
	while open_set.size() > 0:
		# Encontrar nó com menor f_cost
		var current_index = 0
		for i in range(open_set.size()):
			if open_set[i].f_cost < open_set[current_index].f_cost:
				current_index = i
		
		var current = open_set[current_index]
		
		# Verificar se chegou ao destino
		if current.position == end:
			return _reconstruct_path(current)
		
		open_set.remove_at(current_index)
		closed_set.append(current.position)
		
		# Verificar vizinhos
		var neighbors = map.get_walkable_neighbors(current.position)
		
		for neighbor_pos in neighbors:
			if neighbor_pos in closed_set:
				continue
			
			var g_cost = current.g_cost + 1.0
			var h_cost = _heuristic(neighbor_pos, end)
			var neighbor_node = PathNode.new(neighbor_pos, g_cost, h_cost)
			neighbor_node.parent = current
			
			# Verificar se já existe um nó melhor
			var existing_node = null
			for node in open_set:
				if node.position == neighbor_pos:
					existing_node = node
					break
			
			if existing_node == null:
				open_set.append(neighbor_node)
			elif g_cost < existing_node.g_cost:
				existing_node.g_cost = g_cost
				existing_node.f_cost = g_cost + existing_node.h_cost
				existing_node.parent = current
	
	# Sem caminho encontrado
	return []

## Calcula a heurística (distância Manhattan)
static func _heuristic(from: Vector2i, to: Vector2i) -> float:
	return float(abs(from.x - to.x) + abs(from.y - to.y))

## Reconstrói o caminho a partir do nó final
static func _reconstruct_path(node: PathNode) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current = node
	
	while current != null:
		path.insert(0, current.position)
		current = current.parent
	
	return path

## Encontra o caminho mais curto evitando obstáculos
static func find_path_avoiding_obstacles(map: MapData, start: Vector2i, end: Vector2i, obstacles: Array[Vector2i]) -> Array[Vector2i]:
	# Marcar obstáculos temporariamente
	var blocked_tiles: Dictionary = {}
	
	for obstacle in obstacles:
		var tile = map.get_tile(obstacle)
		if tile:
			blocked_tiles[obstacle] = tile.is_blocking
			tile.is_blocking = true
	
	# Encontrar caminho
	var path = find_path(map, start, end)
	
	# Restaurar estado dos tiles
	for obstacle in blocked_tiles:
		var tile = map.get_tile(obstacle)
		if tile:
			tile.is_blocking = blocked_tiles[obstacle]
	
	return path

## Verifica se há linha de visão entre dois pontos
static func has_line_of_sight(map: MapData, from: Vector2i, to: Vector2i) -> bool:
	var line = _bresenham_line(from, to)
	
	for pos in line:
		if not map.is_walkable(pos):
			return false
	
	return true

## Algoritmo de Bresenham para linha
static func _bresenham_line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var line: Array[Vector2i] = []
	
	var x0 = from.x
	var y0 = from.y
	var x1 = to.x
	var y1 = to.y
	
	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy
	
	var x = x0
	var y = y0
	
	while true:
		line.append(Vector2i(x, y))
		
		if x == x1 and y == y1:
			break
		
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy
	
	return line

## Encontra o ponto mais próximo passável
static func find_nearest_walkable(map: MapData, position: Vector2i, max_distance: int = 10) -> Vector2i:
	if map.is_walkable(position):
		return position
	
	var checked: Array[Vector2i] = []
	var to_check: Array[Vector2i] = [position]
	
	for distance in range(1, max_distance + 1):
		var next_to_check: Array[Vector2i] = []
		
		for pos in to_check:
			var neighbors = map.get_neighbors(pos)
			
			for neighbor in neighbors:
				if neighbor not in checked:
					checked.append(neighbor)
					
					if map.is_walkable(neighbor):
						return neighbor
					
					if neighbor not in next_to_check:
						next_to_check.append(neighbor)
		
		to_check = next_to_check
	
	return position

## Calcula o custo de movimento entre dois pontos
static func calculate_movement_cost(map: MapData, from: Vector2i, to: Vector2i) -> float:
	if not map.is_valid_position(to):
		return 999.0
	
	var tile = map.get_tile(to)
	if tile == null or not tile.is_passable():
		return 999.0
	
	# Custo base é 1, mas pode variar por tipo de terreno
	var cost = 1.0
	
	# Movimento diagonal custa mais
	if from.x != to.x and from.y != to.y:
		cost *= 1.414  # sqrt(2)
	
	return cost
