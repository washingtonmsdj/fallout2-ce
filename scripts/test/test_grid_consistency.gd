## Test Grid Consistency
## **Feature: city-map-system, Property 1: Grid Consistency**
## **Validates: Requirements 1.4**

class_name TestGridConsistency
extends GdUnitTestSuite

var grid_system: GridSystem

func before_each() -> void:
	grid_system = GridSystem.new()
	grid_system._ready()

## Property 1: Grid Consistency
## For any grid size and any tile position, getting a tile should return consistent data
func test_grid_consistency() -> void:
	var sizes = [
		Vector2i(50, 50),
		Vector2i(100, 100),
		Vector2i(200, 200),
		Vector2i(500, 500)
	]
	
	for size in sizes:
		grid_system.set_grid_size(size.x, size.y)
		var grid_size = grid_system.get_grid_size()
		assert_that(grid_size).is_equal(size)
		
		# Verify all tiles exist and are accessible
		for x in range(size.x):
			for y in range(size.y):
				var pos = Vector2i(x, y)
				var tile = grid_system.get_tile(pos)
				assert_that(tile).is_not_null()
				assert_that(tile.terrain_type).is_greater_than_or_equal_to(0)
				assert_that(tile.elevation).is_greater_than_or_equal_to(0.0)

## Test that setting and getting tiles preserves data
func test_tile_data_preservation() -> void:
	grid_system.set_grid_size(100, 100)
	var pos = Vector2i(50, 50)
	
	var original_tile = GridSystem.TileData.new(
		GridSystem.TerrainType.CONCRETE,
		5.0,
		false,
		2.5
	)
	
	grid_system.set_tile(pos, original_tile)
	var retrieved_tile = grid_system.get_tile(pos)
	
	assert_that(retrieved_tile.terrain_type).is_equal(GridSystem.TerrainType.CONCRETE)
	assert_that(retrieved_tile.elevation).is_equal(5.0)
	assert_that(retrieved_tile.walkable).is_equal(false)
	assert_that(retrieved_tile.radiation_level).is_equal(2.5)

## Test that invalid positions return null
func test_invalid_positions() -> void:
	grid_system.set_grid_size(100, 100)
	
	var invalid_positions = [
		Vector2i(-1, 0),
		Vector2i(0, -1),
		Vector2i(100, 0),
		Vector2i(0, 100),
		Vector2i(150, 150)
	]
	
	for pos in invalid_positions:
		var tile = grid_system.get_tile(pos)
		assert_that(tile).is_null()

## Test walkability checks
func test_walkability() -> void:
	grid_system.set_grid_size(100, 100)
	var pos = Vector2i(50, 50)
	
	# Create walkable tile
	var walkable_tile = GridSystem.TileData.new(GridSystem.TerrainType.GRASS, 0.0, true, 0.0)
	grid_system.set_tile(pos, walkable_tile)
	assert_that(grid_system.is_walkable(pos)).is_true()
	
	# Create non-walkable tile
	var non_walkable_tile = GridSystem.TileData.new(GridSystem.TerrainType.WATER, 0.0, false, 0.0)
	grid_system.set_tile(pos, non_walkable_tile)
	assert_that(grid_system.is_walkable(pos)).is_false()

## Test getting tiles in area
func test_get_tiles_in_area() -> void:
	grid_system.set_grid_size(100, 100)
	var area = Rect2i(Vector2i(10, 10), Vector2i(20, 20))
	
	var tiles = grid_system.get_tiles_in_area(area)
	assert_that(tiles.size()).is_equal(400)  # 20 * 20

## Test getting neighbors
func test_get_neighbors() -> void:
	grid_system.set_grid_size(100, 100)
	var center = Vector2i(50, 50)
	
	# Test orthogonal neighbors
	var orthogonal = grid_system.get_neighbors(center, false)
	assert_that(orthogonal.size()).is_equal(4)
	
	# Test with diagonals
	var with_diagonals = grid_system.get_neighbors(center, true)
	assert_that(with_diagonals.size()).is_equal(8)
	
	# Test corner neighbors
	var corner = Vector2i(0, 0)
	var corner_neighbors = grid_system.get_neighbors(corner, false)
	assert_that(corner_neighbors.size()).is_equal(2)

## Test raycast between two points
func test_raycast() -> void:
	grid_system.set_grid_size(100, 100)
	var from = Vector2i(0, 0)
	var to = Vector2i(10, 10)
	
	var path = grid_system.raycast(from, to)
	assert_that(path.size()).is_greater_than(0)
	assert_that(path[0]).is_equal(from)
	assert_that(path[-1]).is_equal(to)

## Property 9: Save/Load Round Trip
## For any grid, serializing and deserializing should produce equivalent data
func test_serialization_round_trip() -> void:
	grid_system.set_grid_size(50, 50)
	
	# Modify some tiles
	var test_positions = [
		Vector2i(0, 0),
		Vector2i(25, 25),
		Vector2i(49, 49)
	]
	
	for pos in test_positions:
		var tile = GridSystem.TileData.new(
			GridSystem.TerrainType.CONCRETE,
			3.5,
			false,
			1.5
		)
		grid_system.set_tile(pos, tile)
	
	# Serialize
	var serialized = grid_system.serialize()
	assert_that(serialized.size()).is_greater_than(0)
	
	# Create new grid and deserialize
	var new_grid = GridSystem.new()
	new_grid._ready()
	var success = new_grid.deserialize(serialized)
	assert_that(success).is_true()
	
	# Verify grid size
	var new_size = new_grid.get_grid_size()
	assert_that(new_size).is_equal(Vector2i(50, 50))
	
	# Verify modified tiles
	for pos in test_positions:
		var original = grid_system.get_tile(pos)
		var restored = new_grid.get_tile(pos)
		
		assert_that(restored.terrain_type).is_equal(original.terrain_type)
		assert_that(restored.elevation).is_equal(original.elevation)
		assert_that(restored.walkable).is_equal(original.walkable)
		assert_that(restored.radiation_level).is_equal(original.radiation_level)
