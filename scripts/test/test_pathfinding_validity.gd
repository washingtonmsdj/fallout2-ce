## Test for Pathfinding Validity Property
## **Feature: city-map-system, Property 2: Pathfinding Validity**
## **Validates: Requirements 2.3, 2.5**

extends GutTest

var pathfinding: Pathfinding
var grid_system: GridSystem
var road_system: RoadSystem
var config: CityConfig

func before_each() -> void:
	config = CityConfig.new()
	grid_system = GridSystem.new()
	grid_system.initialize(100, 100)
	
	road_system = RoadSystem.new()
	road_system.set_grid_system(grid_system)
	
	pathfinding = Pathfinding.new(grid_system, road_system, config)

func test_path_connects_start_to_goal() -> void:
	"""Property: For any valid start and goal, the returned path should connect them"""
	var start = Vector2i(10, 10)
	var goal = Vector2i(30, 30)
	
	var result = pathfinding.find_path(start, goal, Pathfinding.PathMode.OFF_ROAD)
	
	assert_true(result.is_valid, "Path should be valid")
	assert_equal(result.path[0], start, "Path should start at start position")
	assert_equal(result.path[-1], goal, "Path should end at goal position")

func test_path_is_continuous() -> void:
	"""Property: For any valid path, consecutive waypoints should be adjacent or diagonal"""
	var start = Vector2i(10, 10)
	var goal = Vector2i(30, 30)
	
	var result = pathfinding.find_path(start, goal, Pathfinding.PathMode.OFF_ROAD)
	
	assert_true(result.is_valid, "Path should be valid")
	
	# Check continuity
	for i in range(1, result.path.size()):
		var prev = result.path[i - 1]
		var curr = result.path[i]
		var distance = prev.distance_to(curr)
		
		# Should be adjacent (distance <= sqrt(2) for diagonal)
		assert_true(distance <= 1.5, "Path should be continuous at step %d" % i)

func test_path_respects_walkability() -> void:
	"""Property: For any valid path, all tiles should be walkable"""
	var start = Vector2i(10, 10)
	var goal = Vector2i(30, 30)
	
	var result = pathfinding.find_path(start, goal, Pathfinding.PathMode.OFF_ROAD)
	
	if result.is_valid:
		for tile_pos in result.path:
			assert_true(grid_system.is_walkable(tile_pos), 
				"All path tiles should be walkable at %s" % tile_pos)

func test_invalid_start_returns_invalid_path() -> void:
	"""Property: For invalid start position, path should be invalid"""
	var start = Vector2i(-10, -10)  # Outside grid
	var goal = Vector2i(30, 30)
	
	var result = pathfinding.find_path(start, goal, Pathfinding.PathMode.OFF_ROAD)
	
	assert_false(result.is_valid, "Path should be invalid for invalid start")

func test_invalid_goal_returns_invalid_path() -> void:
	"""Property: For invalid goal position, path should be invalid"""
	var start = Vector2i(10, 10)
	var goal = Vector2i(-10, -10)  # Outside grid
	
	var result = pathfinding.find_path(start, goal, Pathfinding.PathMode.OFF_ROAD)
	
	assert_false(result.is_valid, "Path should be invalid for invalid goal")

func test_same_start_and_goal() -> void:
	"""Property: For same start and goal, path should be valid with single tile"""
	var position = Vector2i(20, 20)
	
	var result = pathfinding.find_path(position, position, Pathfinding.PathMode.OFF_ROAD)
	
	assert_true(result.is_valid, "Path should be valid")
	assert_equal(result.path.size(), 1, "Path should have single tile")
	assert_equal(result.path[0], position, "Path should be at the position")

func test_path_cost_is_positive() -> void:
	"""Property: For any valid path, cost should be positive or zero"""
	var start = Vector2i(10, 10)
	var goal = Vector2i(30, 30)
	
	var result = pathfinding.find_path(start, goal, Pathfinding.PathMode.OFF_ROAD)
	
	if result.is_valid:
		assert_true(result.cost >= 0.0, "Path cost should be non-negative")

func test_path_time_is_positive() -> void:
	"""Property: For any valid path, estimated time should be positive or zero"""
	var start = Vector2i(10, 10)
	var goal = Vector2i(30, 30)
	
	var result = pathfinding.find_path(start, goal, Pathfinding.PathMode.OFF_ROAD)
	
	if result.is_valid:
		assert_true(result.estimated_time >= 0.0, "Path time should be non-negative")

func test_road_only_path_uses_roads() -> void:
	"""Property: For road-only pathfinding, all tiles should be on roads"""
	# Create some roads
	road_system.create_road(Vector2i(10, 10), Vector2i(30, 10))
	road_system.create_road(Vector2i(30, 10), Vector2i(30, 30))
	
	var start = Vector2i(10, 10)
	var goal = Vector2i(30, 30)
	
	var result = pathfinding.find_path(start, goal, Pathfinding.PathMode.ROAD_ONLY)
	
	if result.is_valid:
		for tile_pos in result.path:
			assert_true(road_system.is_road_tile(tile_pos), 
				"Road-only path should use road tiles at %s" % tile_pos)

func test_path_length_reasonable() -> void:
	"""Property: For any valid path, length should be reasonable (not too long)"""
	var start = Vector2i(10, 10)
	var goal = Vector2i(30, 30)
	
	var result = pathfinding.find_path(start, goal, Pathfinding.PathMode.OFF_ROAD)
	
	if result.is_valid:
		# Manhattan distance is minimum possible
		var manhattan = abs(goal.x - start.x) + abs(goal.y - start.y)
		# Path should not be more than 2x manhattan distance
		assert_true(result.path.size() <= manhattan * 2, 
			"Path length should be reasonable")

func test_cache_returns_same_result() -> void:
	"""Property: For cached pathfinding, repeated queries should return same result"""
	var start = Vector2i(10, 10)
	var goal = Vector2i(30, 30)
	
	pathfinding.set_cache_enabled(true)
	
	var result1 = pathfinding.find_path_cached(start, goal, Pathfinding.PathMode.OFF_ROAD)
	var result2 = pathfinding.find_path_cached(start, goal, Pathfinding.PathMode.OFF_ROAD)
	
	assert_equal(result1.path, result2.path, "Cached results should be identical")
	assert_equal(result1.cost, result2.cost, "Cached costs should be identical")

func test_smoothed_path_is_shorter() -> void:
	"""Property: For smoothed path, waypoint count should be less than or equal to original"""
	var start = Vector2i(10, 10)
	var goal = Vector2i(30, 30)
	
	var result = pathfinding.find_path(start, goal, Pathfinding.PathMode.OFF_ROAD)
	
	if result.is_valid:
		var smoothed = pathfinding.smooth_path(result.path)
		assert_true(smoothed.size() <= result.path.size(), 
			"Smoothed path should have fewer or equal waypoints")
