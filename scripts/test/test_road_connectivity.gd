## Test for Road Connectivity Property
## **Feature: city-map-system, Property 7: Road Connectivity**
## **Validates: Requirements 2.2**

extends GutTest

var road_system: RoadSystem
var grid_system: GridSystem
var config: CityConfig

func before_each() -> void:
	config = CityConfig.new()
	grid_system = GridSystem.new()
	grid_system.initialize(100, 100)
	
	road_system = RoadSystem.new()
	road_system.set_grid_system(grid_system)

func test_adjacent_roads_are_connected() -> void:
	"""Property: For any two adjacent road segments, they should be automatically connected"""
	# Create two roads that are adjacent
	var road1_id = road_system.create_road(Vector2i(10, 10), Vector2i(20, 10))
	var road2_id = road_system.create_road(Vector2i(20, 10), Vector2i(30, 10))
	
	# Auto-connect adjacent roads
	road_system.auto_connect_adjacent_roads()
	
	# Verify they are connected
	var road1 = road_system.get_road_segment(road1_id)
	var road2 = road_system.get_road_segment(road2_id)
	
	assert_true(road1.connections.has(road2_id), "Road 1 should be connected to Road 2")
	assert_true(road2.connections.has(road1_id), "Road 2 should be connected to Road 1")

func test_non_adjacent_roads_not_connected() -> void:
	"""Property: For any two non-adjacent road segments, they should not be automatically connected"""
	# Create two roads that are far apart
	var road1_id = road_system.create_road(Vector2i(10, 10), Vector2i(20, 10))
	var road2_id = road_system.create_road(Vector2i(50, 50), Vector2i(60, 50))
	
	# Auto-connect adjacent roads
	road_system.auto_connect_adjacent_roads()
	
	# Verify they are NOT connected
	var road1 = road_system.get_road_segment(road1_id)
	var road2 = road_system.get_road_segment(road2_id)
	
	assert_false(road1.connections.has(road2_id), "Road 1 should NOT be connected to Road 2")
	assert_false(road2.connections.has(road1_id), "Road 2 should NOT be connected to Road 1")

func test_connection_is_bidirectional() -> void:
	"""Property: For any two connected roads, the connection should be bidirectional"""
	var road1_id = road_system.create_road(Vector2i(10, 10), Vector2i(20, 10))
	var road2_id = road_system.create_road(Vector2i(20, 10), Vector2i(30, 10))
	
	# Manually connect
	var result = road_system.connect_roads(road1_id, road2_id)
	assert_true(result, "Roads should be connectable")
	
	var road1 = road_system.get_road_segment(road1_id)
	var road2 = road_system.get_road_segment(road2_id)
	
	# Both should have each other in their connections
	assert_true(road1.connections.has(road2_id), "Road 1 should reference Road 2")
	assert_true(road2.connections.has(road1_id), "Road 2 should reference Road 1")

func test_organic_network_creates_connected_roads() -> void:
	"""Property: For any organic network created, all roads should be connected to at least one other road"""
	var center = Vector2i(50, 50)
	var created_roads = road_system.create_organic_network(center, 5, 30)
	
	# All roads should have at least one connection
	for road_id in created_roads:
		var road = road_system.get_road_segment(road_id)
		assert_true(road.connections.size() > 0, "Road %d should have at least one connection" % road_id)

func test_radial_roads_all_connected_to_center() -> void:
	"""Property: For any radial network, all roads should connect at the center point"""
	var center = Vector2i(50, 50)
	var created_roads = road_system.create_radial_roads(center, 6, 30)
	
	# All roads should be connected to each other through the center
	for i in range(created_roads.size()):
		for j in range(i + 1, created_roads.size()):
			var road_i = road_system.get_road_segment(created_roads[i])
			var road_j = road_system.get_road_segment(created_roads[j])
			
			# They should either be directly connected or share a common connection
			var has_direct_connection = road_i.connections.has(created_roads[j])
			var has_common_connection = false
			
			for conn_i in road_i.connections:
				if road_j.connections.has(conn_i):
					has_common_connection = true
					break
			
			assert_true(has_direct_connection or has_common_connection, 
				"Roads %d and %d should be connected" % [created_roads[i], created_roads[j]])

func test_connection_prevents_duplicates() -> void:
	"""Property: For any two roads, connecting them multiple times should not create duplicate connections"""
	var road1_id = road_system.create_road(Vector2i(10, 10), Vector2i(20, 10))
	var road2_id = road_system.create_road(Vector2i(20, 10), Vector2i(30, 10))
	
	# Connect multiple times
	road_system.connect_roads(road1_id, road2_id)
	road_system.connect_roads(road1_id, road2_id)
	road_system.connect_roads(road1_id, road2_id)
	
	var road1 = road_system.get_road_segment(road1_id)
	var road2 = road_system.get_road_segment(road2_id)
	
	# Count occurrences - should be exactly 1
	var count1 = 0
	for conn in road1.connections:
		if conn == road2_id:
			count1 += 1
	
	var count2 = 0
	for conn in road2.connections:
		if conn == road1_id:
			count2 += 1
	
	assert_equal(count1, 1, "Road 1 should have exactly one connection to Road 2")
	assert_equal(count2, 1, "Road 2 should have exactly one connection to Road 1")
