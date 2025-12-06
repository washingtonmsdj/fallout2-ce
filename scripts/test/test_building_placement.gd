## Test for Building Placement Integrity Property
## **Feature: city-map-system, Property 3: Building Placement Integrity**
## **Validates: Requirements 4.1, 4.3**

extends GutTest

var building_system: BuildingSystem
var grid_system: GridSystem
var zone_system: ZoneSystem
var config: CityConfig

func before_each() -> void:
	config = CityConfig.new()
	grid_system = GridSystem.new()
	grid_system.initialize(100, 100)
	
	zone_system = ZoneSystem.new()
	zone_system.set_grid_system(grid_system)
	
	building_system = BuildingSystem.new()
	building_system.set_systems(grid_system, zone_system, null)

func test_building_occupies_correct_tiles() -> void:
	"""Property: For any building placement, all tiles in the building's area should be marked as occupied"""
	var building_type = BuildingSystem.BuildingType.SMALL_HOUSE
	var position = Vector2i(10, 10)
	var size = Vector2i(3, 3)
	
	var building_id = building_system.construct_building(building_type, position, size)
	
	assert_true(building_id >= 0, "Building should be constructed successfully")
	
	# Verificar que todos os tiles estão ocupados
	for x in range(position.x, position.x + size.x):
		for y in range(position.y, position.y + size.y):
			var tile_pos = Vector2i(x, y)
			var occupying_building = building_system.get_building_at_tile(tile_pos)
			assert_equal(occupying_building, building_id, 
				"Tile %s should be occupied by building %d" % [tile_pos, building_id])

func test_building_prevents_overlapping() -> void:
	"""Property: For any two buildings, they should not occupy the same tiles"""
	var position1 = Vector2i(10, 10)
	var size1 = Vector2i(3, 3)
	var building_id1 = building_system.construct_building(
		BuildingSystem.BuildingType.SMALL_HOUSE, position1, size1)
	
	# Tentar construir um edifício que se sobrepõe
	var position2 = Vector2i(11, 11)
	var size2 = Vector2i(3, 3)
	var building_id2 = building_system.construct_building(
		BuildingSystem.BuildingType.SMALL_HOUSE, position2, size2)
	
	assert_true(building_id1 >= 0, "First building should be constructed")
	assert_equal(building_id2, -1, "Overlapping building should not be constructed")

func test_building_data_consistency() -> void:
	"""Property: For any constructed building, its data should be consistent with its tiles"""
	var building_type = BuildingSystem.BuildingType.MEDIUM_HOUSE
	var position = Vector2i(20, 20)
	var size = Vector2i(4, 4)
	
	var building_id = building_system.construct_building(building_type, position, size)
	var building = building_system.get_building(building_id)
	
	assert_true(building != null, "Building should exist")
	assert_equal(building.position, position, "Building position should match")
	assert_equal(building.size, size, "Building size should match")
	assert_equal(building.building_type, building_type, "Building type should match")
	assert_equal(building.tiles.size(), size.x * size.y, "Building should have correct number of tiles")

func test_building_outside_grid_fails() -> void:
	"""Property: For building placement outside grid bounds, construction should fail"""
	var position = Vector2i(95, 95)
	var size = Vector2i(10, 10)  # Vai sair do grid 100x100
	
	var building_id = building_system.construct_building(
		BuildingSystem.BuildingType.SMALL_HOUSE, position, size)
	
	assert_equal(building_id, -1, "Building outside grid should not be constructed")

func test_building_on_unwalkable_tile_fails() -> void:
	"""Property: For building placement on unwalkable tiles, construction should fail"""
	# Marcar alguns tiles como não caminháveis
	grid_system.set_tile(Vector2i(10, 10), GridSystem.TerrainType.WATER)
	grid_system.set_tile(Vector2i(10, 11), GridSystem.TerrainType.WATER)
	
	var position = Vector2i(10, 10)
	var size = Vector2i(2, 2)
	
	var building_id = building_system.construct_building(
		BuildingSystem.BuildingType.SMALL_HOUSE, position, size)
	
	assert_equal(building_id, -1, "Building on unwalkable tiles should not be constructed")

func test_building_destruction_frees_tiles() -> void:
	"""Property: For destroyed building, all its tiles should be freed"""
	var position = Vector2i(30, 30)
	var size = Vector2i(3, 3)
	
	var building_id = building_system.construct_building(
		BuildingSystem.BuildingType.SMALL_HOUSE, position, size)
	
	# Destruir o edifício
	building_system.destroy_building(building_id)
	
	# Verificar que os tiles foram liberados
	for x in range(position.x, position.x + size.x):
		for y in range(position.y, position.y + size.y):
			var tile_pos = Vector2i(x, y)
			var occupying_building = building_system.get_building_at_tile(tile_pos)
			assert_equal(occupying_building, -1, 
				"Tile %s should be free after building destruction" % tile_pos)

func test_building_count_increases() -> void:
	"""Property: For each constructed building, building count should increase by 1"""
	var initial_count = building_system.get_building_count()
	
	var building_id = building_system.construct_building(
		BuildingSystem.BuildingType.SMALL_HOUSE, Vector2i(40, 40), Vector2i(3, 3))
	
	assert_true(building_id >= 0, "Building should be constructed")
	assert_equal(building_system.get_building_count(), initial_count + 1, 
		"Building count should increase by 1")

func test_building_retrieval_by_type() -> void:
	"""Property: For buildings of a specific type, get_buildings_by_type should return all of them"""
	var building_type = BuildingSystem.BuildingType.SMALL_HOUSE
	
	# Construir vários edifícios do mesmo tipo
	var building_id1 = building_system.construct_building(building_type, Vector2i(10, 10), Vector2i(3, 3))
	var building_id2 = building_system.construct_building(building_type, Vector2i(20, 20), Vector2i(3, 3))
	var building_id3 = building_system.construct_building(
		BuildingSystem.BuildingType.MEDIUM_HOUSE, Vector2i(30, 30), Vector2i(4, 4))
	
	var buildings_of_type = building_system.get_buildings_by_type(building_type)
	
	assert_equal(buildings_of_type.size(), 2, "Should find 2 buildings of the specified type")
	assert_true(buildings_of_type[0].id == building_id1 or buildings_of_type[0].id == building_id2)
	assert_true(buildings_of_type[1].id == building_id1 or buildings_of_type[1].id == building_id2)

func test_building_zone_restriction() -> void:
	"""Property: For building in a zone, building type should respect zone restrictions"""
	# Criar uma zona residencial
	var zone_tiles = []
	for x in range(50, 60):
		for y in range(50, 60):
			zone_tiles.append(Vector2i(x, y))
	
	var zone_id = zone_system.create_zone(zone_tiles, ZoneSystem.ZoneType.RESIDENTIAL)
	
	# Tentar construir um edifício industrial em zona residencial
	var building_id = building_system.construct_building(
		BuildingSystem.BuildingType.FACTORY, Vector2i(50, 50), Vector2i(3, 3), zone_id)
	
	assert_equal(building_id, -1, "Industrial building should not be allowed in residential zone")
	
	# Construir um edifício residencial deve funcionar
	var building_id2 = building_system.construct_building(
		BuildingSystem.BuildingType.SMALL_HOUSE, Vector2i(50, 50), Vector2i(3, 3), zone_id)
	
	assert_true(building_id2 >= 0, "Residential building should be allowed in residential zone")

func test_building_statistics() -> void:
	"""Property: Building statistics should accurately reflect the state of all buildings"""
	# Construir alguns edifícios
	var building_id1 = building_system.construct_building(
		BuildingSystem.BuildingType.SMALL_HOUSE, Vector2i(10, 10), Vector2i(3, 3))
	var building_id2 = building_system.construct_building(
		BuildingSystem.BuildingType.FACTORY, Vector2i(20, 20), Vector2i(5, 5))
	
	var stats = building_system.get_building_statistics()
	
	assert_equal(stats["total_buildings"], 2, "Should have 2 buildings")
	assert_true(stats["by_type"].has("SMALL_HOUSE"), "Should track SMALL_HOUSE")
	assert_true(stats["by_type"].has("FACTORY"), "Should track FACTORY")

