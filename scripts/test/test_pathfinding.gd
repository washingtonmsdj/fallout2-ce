extends Node
## Teste de propriedade para sistema de pathfinding
## **Feature: fallout2-complete-migration, Property 10: Pathfinding Validity**
## **Validates: Requirements 3.2**

class_name TestPathfinding

## Testa que todos os tiles no caminho são passáveis
func test_all_path_tiles_walkable() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	var start = Vector2i(5, 5)
	var end = Vector2i(20, 20)
	
	var path = Pathfinding.find_path(map, start, end)
	
	# Verificar que todos os tiles no caminho são passáveis
	for pos in path:
		assert(map.is_walkable(pos),
			"All tiles in path should be walkable")

## Testa que o caminho começa no ponto inicial
func test_path_starts_at_start() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	var start = Vector2i(5, 5)
	var end = Vector2i(20, 20)
	
	var path = Pathfinding.find_path(map, start, end)
	
	if path.size() > 0:
		assert(path[0] == start,
			"Path should start at start position")

## Testa que o caminho termina no ponto final
func test_path_ends_at_end() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	var start = Vector2i(5, 5)
	var end = Vector2i(20, 20)
	
	var path = Pathfinding.find_path(map, start, end)
	
	if path.size() > 0:
		assert(path[path.size() - 1] == end,
			"Path should end at end position")

## Testa que o caminho é contínuo
func test_path_is_continuous() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	var start = Vector2i(5, 5)
	var end = Vector2i(20, 20)
	
	var path = Pathfinding.find_path(map, start, end)
	
	# Verificar que cada tile é vizinho do anterior
	for i in range(1, path.size()):
		var prev = path[i - 1]
		var curr = path[i]
		var neighbors = map.get_neighbors(prev)
		
		assert(curr in neighbors,
			"Each tile in path should be neighbor of previous")

## Testa que não há caminho para destino bloqueado
func test_no_path_to_blocked_destination() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	var start = Vector2i(5, 5)
	var end = Vector2i(20, 20)
	
	# Bloquear o destino
	var tile = map.get_tile(end)
	tile.is_blocking = true
	
	var path = Pathfinding.find_path(map, start, end)
	
	assert(path.size() == 0,
		"Should not find path to blocked destination")

## Testa que o caminho é o mais curto possível
func test_path_is_shortest() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	var start = Vector2i(5, 5)
	var end = Vector2i(15, 15)
	
	var path = Pathfinding.find_path(map, start, end)
	
	# Distância Manhattan é 20
	var manhattan_distance = abs(end.x - start.x) + abs(end.y - start.y)
	
	# Caminho deve ser próximo à distância Manhattan
	assert(path.size() <= manhattan_distance + 2,
		"Path should be close to Manhattan distance")

## Testa linha de visão
func test_line_of_sight() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	var from = Vector2i(5, 5)
	var to = Vector2i(15, 15)
	
	# Deve haver linha de visão em mapa aberto
	var has_los = Pathfinding.has_line_of_sight(map, from, to)
	assert(has_los,
		"Should have line of sight in open map")

## Testa linha de visão bloqueada
func test_line_of_sight_blocked() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	var from = Vector2i(5, 5)
	var to = Vector2i(15, 15)
	
	# Bloquear o meio do caminho
	var tile = map.get_tile(Vector2i(10, 10))
	tile.is_blocking = true
	
	# Não deve haver linha de visão
	var has_los = Pathfinding.has_line_of_sight(map, from, to)
	assert(not has_los,
		"Should not have line of sight when blocked")

## Testa encontrar ponto passável mais próximo
func test_find_nearest_walkable() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	var blocked_pos = Vector2i(10, 10)
	var tile = map.get_tile(blocked_pos)
	tile.is_blocking = true
	
	var nearest = Pathfinding.find_nearest_walkable(map, blocked_pos, 5)
	
	# Deve encontrar um tile passável próximo
	assert(map.is_walkable(nearest),
		"Should find a walkable tile")
	assert(nearest != blocked_pos,
		"Should not return blocked position")

## Testa cálculo de custo de movimento
func test_movement_cost_calculation() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	var from = Vector2i(10, 10)
	var to = Vector2i(11, 10)  # Movimento horizontal
	
	var cost = Pathfinding.calculate_movement_cost(map, from, to)
	
	# Custo deve ser 1.0 para movimento horizontal
	assert(cost == 1.0,
		"Horizontal movement cost should be 1.0")
	
	# Movimento diagonal
	var diagonal_to = Vector2i(11, 11)
	var diagonal_cost = Pathfinding.calculate_movement_cost(map, from, diagonal_to)
	
	# Custo deve ser maior para movimento diagonal
	assert(diagonal_cost > 1.0,
		"Diagonal movement cost should be greater than 1.0")

## Testa caminho evitando obstáculos
func test_path_avoiding_obstacles() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	var start = Vector2i(5, 5)
	var end = Vector2i(20, 20)
	
	# Criar linha de obstáculos
	var obstacles: Array[Vector2i] = []
	for i in range(10, 15):
		obstacles.append(Vector2i(i, 12))
	
	var path = Pathfinding.find_path_avoiding_obstacles(map, start, end, obstacles)
	
	# Verificar que nenhum tile no caminho é um obstáculo
	for pos in path:
		assert(pos not in obstacles,
			"Path should avoid obstacles")

## Testa que posições inválidas retornam caminho vazio
func test_invalid_positions_return_empty_path() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	var start = Vector2i(5, 5)
	var invalid_end = Vector2i(100, 100)
	
	var path = Pathfinding.find_path(map, start, invalid_end)
	
	assert(path.size() == 0,
		"Should return empty path for invalid destination")

## Testa que mesmo ponto retorna caminho com um elemento
func test_same_point_returns_single_element() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	var pos = Vector2i(10, 10)
	
	var path = Pathfinding.find_path(map, pos, pos)
	
	assert(path.size() == 1,
		"Path from point to itself should have one element")
	assert(path[0] == pos,
		"Path should contain the same point")

## Executa todos os testes
func run_all_tests() -> void:
	print("=== Running Pathfinding Property Tests ===")
	
	test_all_path_tiles_walkable()
	print("✓ test_all_path_tiles_walkable passed")
	
	test_path_starts_at_start()
	print("✓ test_path_starts_at_start passed")
	
	test_path_ends_at_end()
	print("✓ test_path_ends_at_end passed")
	
	test_path_is_continuous()
	print("✓ test_path_is_continuous passed")
	
	test_no_path_to_blocked_destination()
	print("✓ test_no_path_to_blocked_destination passed")
	
	test_path_is_shortest()
	print("✓ test_path_is_shortest passed")
	
	test_line_of_sight()
	print("✓ test_line_of_sight passed")
	
	test_line_of_sight_blocked()
	print("✓ test_line_of_sight_blocked passed")
	
	test_find_nearest_walkable()
	print("✓ test_find_nearest_walkable passed")
	
	test_movement_cost_calculation()
	print("✓ test_movement_cost_calculation passed")
	
	test_path_avoiding_obstacles()
	print("✓ test_path_avoiding_obstacles passed")
	
	test_invalid_positions_return_empty_path()
	print("✓ test_invalid_positions_return_empty_path passed")
	
	test_same_point_returns_single_element()
	print("✓ test_same_point_returns_single_element passed")
	
	print("=== All Pathfinding tests passed! ===")
