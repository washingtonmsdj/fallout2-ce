extends Node
## Teste de propriedade para integridade de dados do mapa
## **Feature: fallout2-complete-migration, Property 9: Map Data Integrity**
## **Validates: Requirements 3.1**

class_name TestMapDataIntegrity

## Testa que todos os tiles existem após inicialização
func test_all_tiles_exist_after_init() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	# Verificar que todos os tiles foram criados
	assert(map.tiles.size() == 50 * 50,
		"All tiles should be created after initialization")
	
	# Verificar que cada tile tem posição válida
	for pos in map.tiles:
		var tile = map.tiles[pos]
		assert(tile.position == pos,
			"Tile position should match dictionary key")

## Testa que tiles têm propriedades válidas
func test_tiles_have_valid_properties() -> void:
	var map = MapData.new()
	map.width = 30
	map.height = 30
	map.initialize()
	
	for pos in map.tiles:
		var tile = map.tiles[pos]
		
		# Verificar propriedades básicas
		assert(tile.terrain_type >= 0,
			"Tile terrain type should be valid")
		assert(tile.height >= 0.0,
			"Tile height should be non-negative")
		assert(tile.light_level >= 0.0 and tile.light_level <= 1.0,
			"Tile light level should be between 0 and 1")

## Testa que posições inválidas retornam null
func test_invalid_positions_return_null() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	# Tentar acessar tiles fora do mapa
	var outside_tile = map.get_tile(Vector2i(-1, 0))
	assert(outside_tile == null,
		"Getting tile outside map should return null")
	
	outside_tile = map.get_tile(Vector2i(100, 100))
	assert(outside_tile == null,
		"Getting tile outside map should return null")

## Testa que tiles passáveis são identificados corretamente
func test_walkable_tiles_identification() -> void:
	var map = MapData.new()
	map.width = 20
	map.height = 20
	map.initialize()
	
	# Obter tiles passáveis
	var walkable = map.get_walkable_tiles()
	
	# Todos os tiles devem ser passáveis por padrão
	assert(walkable.size() == 20 * 20,
		"All tiles should be walkable by default")
	
	# Modificar um tile para não passável
	var tile = map.get_tile(Vector2i(0, 0))
	tile.is_blocking = true
	
	# Obter tiles passáveis novamente
	walkable = map.get_walkable_tiles()
	assert(walkable.size() == (20 * 20) - 1,
		"Blocking tile should not be in walkable list")

## Testa que vizinhos são retornados corretamente
func test_neighbors_returned_correctly() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	# Verificar vizinhos de um tile no meio do mapa
	var center = Vector2i(25, 25)
	var neighbors = map.get_neighbors(center)
	
	# Deve ter 8 vizinhos
	assert(neighbors.size() == 8,
		"Tile in middle of map should have 8 neighbors")
	
	# Verificar vizinhos de um tile no canto
	var corner = Vector2i(0, 0)
	neighbors = map.get_neighbors(corner)
	
	# Deve ter 3 vizinhos
	assert(neighbors.size() == 3,
		"Tile in corner should have 3 neighbors")

## Testa que objetos são adicionados e removidos corretamente
func test_objects_add_remove() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	# Criar um objeto
	var obj = MapObject.new()
	obj.object_id = "door_1"
	obj.object_type = MapObject.ObjectType.DOOR
	
	# Adicionar objeto
	map.add_object("door_1", obj, Vector2i(10, 10))
	assert("door_1" in map.objects,
		"Object should be added to map")
	
	# Verificar que tile referencia o objeto
	var tile = map.get_tile(Vector2i(10, 10))
	assert(tile.object_id == "door_1",
		"Tile should reference the object")
	
	# Remover objeto
	map.remove_object("door_1")
	assert("door_1" not in map.objects,
		"Object should be removed from map")
	
	# Verificar que tile não referencia mais o objeto
	tile = map.get_tile(Vector2i(10, 10))
	assert(tile.object_id == "",
		"Tile should not reference removed object")

## Testa que critters são adicionados e removidos corretamente
func test_critters_add_remove() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	# Criar um critter
	var critter = Critter.new()
	critter.critter_name = "Enemy"
	
	# Adicionar critter
	map.add_critter("enemy_1", critter, Vector2i(20, 20))
	assert("enemy_1" in map.critters,
		"Critter should be added to map")
	
	# Verificar que tile referencia o critter
	var tile = map.get_tile(Vector2i(20, 20))
	assert(tile.critter_id == "enemy_1",
		"Tile should reference the critter")
	
	# Remover critter
	map.remove_critter("enemy_1")
	assert("enemy_1" not in map.critters,
		"Critter should be removed from map")
	
	# Verificar que tile não referencia mais o critter
	tile = map.get_tile(Vector2i(20, 20))
	assert(tile.critter_id == "",
		"Tile should not reference removed critter")

## Testa que distâncias são calculadas corretamente
func test_distance_calculation() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	# Calcular distância entre dois pontos
	var from = Vector2i(0, 0)
	var to = Vector2i(3, 4)
	var distance = map.get_distance(from, to)
	
	# Distância deve ser 5 (3-4-5 triângulo)
	assert(distance == 5.0,
		"Distance calculation should be correct")

## Testa que tiles em raio são retornados corretamente
func test_tiles_in_radius() -> void:
	var map = MapData.new()
	map.width = 50
	map.height = 50
	map.initialize()
	
	# Obter tiles em raio de 5 do centro
	var center = Vector2i(25, 25)
	var tiles_in_radius = map.get_tiles_in_radius(center, 5)
	
	# Verificar que todos os tiles estão dentro do raio
	for pos in tiles_in_radius:
		var distance = center.distance_to(pos)
		assert(distance <= 5.0,
			"All tiles should be within radius")

## Testa que mapa info é retornado corretamente
func test_map_info_returned() -> void:
	var map = MapData.new()
	map.map_name = "Test Map"
	map.map_id = "test_map_1"
	map.width = 40
	map.height = 40
	map.initialize()
	
	var info = map.get_map_info()
	
	assert(info["name"] == "Test Map",
		"Map name should be correct")
	assert(info["id"] == "test_map_1",
		"Map ID should be correct")
	assert(info["width"] == 40,
		"Map width should be correct")
	assert(info["height"] == 40,
		"Map height should be correct")
	assert(info["tile_count"] == 40 * 40,
		"Tile count should be correct")

## Executa todos os testes
func run_all_tests() -> void:
	print("=== Running Map Data Integrity Property Tests ===")
	
	test_all_tiles_exist_after_init()
	print("✓ test_all_tiles_exist_after_init passed")
	
	test_tiles_have_valid_properties()
	print("✓ test_tiles_have_valid_properties passed")
	
	test_invalid_positions_return_null()
	print("✓ test_invalid_positions_return_null passed")
	
	test_walkable_tiles_identification()
	print("✓ test_walkable_tiles_identification passed")
	
	test_neighbors_returned_correctly()
	print("✓ test_neighbors_returned_correctly passed")
	
	test_objects_add_remove()
	print("✓ test_objects_add_remove passed")
	
	test_critters_add_remove()
	print("✓ test_critters_add_remove passed")
	
	test_distance_calculation()
	print("✓ test_distance_calculation passed")
	
	test_tiles_in_radius()
	print("✓ test_tiles_in_radius passed")
	
	test_map_info_returned()
	print("✓ test_map_info_returned passed")
	
	print("=== All Map Data Integrity tests passed! ===")
