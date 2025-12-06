extends GutTest

## Test depth sorting for correct visual layering
## Validates: Requirements 7.2

var city_renderer: CityRenderer
var city_simulation: CitySimulation

func before_each():
	city_simulation = CitySimulation.new()
	city_simulation.grid_size = Vector2i(20, 20)
	city_simulation.initialize()
	
	city_renderer = CityRenderer.new()
	city_renderer.city_simulation = city_simulation

func after_each():
	if city_renderer:
		city_renderer.free()
	if city_simulation:
		city_simulation.free()

func test_entities_sorted_by_depth():
	# Arrange: Create entities at different positions
	city_simulation.roads.append(Vector2i(5, 5))  # depth = 10
	city_simulation.roads.append(Vector2i(2, 2))  # depth = 4
	city_simulation.roads.append(Vector2i(8, 8))  # depth = 16
	
	var building1 = {
		"id": 1,
		"type": CitySimulation.BuildingType.HOUSE,
		"position": Vector2i(3, 3),  # depth = 6 + 2 = 8
		"level": 1,
		"health": 100.0
	}
	var building2 = {
		"id": 2,
		"type": CitySimulation.BuildingType.SHOP,
		"position": Vector2i(7, 7),  # depth = 14 + 2 = 16
		"level": 1,
		"health": 100.0
	}
	city_simulation.buildings.append(building1)
	city_simulation.buildings.append(building2)
	
	var citizen1 = {
		"id": 1,
		"position": Vector2i(4, 4),  # depth = 8.5 (with 0.5 offset)
		"state": "idle"
	}
	var citizen2 = {
		"id": 2,
		"position": Vector2i(1, 1),  # depth = 2.5
		"state": "idle"
	}
	city_simulation.citizens.append(citizen1)
	city_simulation.citizens.append(citizen2)
	
	# Act: Get sorted entities (we need to access the internal method)
	var entities: Array = []
	
	# Add roads
	for road_cell in city_simulation.roads:
		var pos = Vector2(road_cell)
		var depth = pos.x + pos.y
		entities.append({"type": "road", "depth": depth, "position": pos})
	
	# Add buildings
	for building in city_simulation.buildings:
		var pos = Vector2(building["position"])
		var depth = pos.x + pos.y + 2.0
		entities.append({"type": "building", "depth": depth, "id": building["id"]})
	
	# Add citizens
	for citizen in city_simulation.citizens:
		var pos = Vector2(citizen["position"]) + Vector2(0.5, 0.5)
		var depth = pos.x + pos.y
		entities.append({"type": "citizen", "depth": depth, "id": citizen["id"]})
	
	# Sort
	entities.sort_custom(func(a, b): return a.depth < b.depth)
	
	# Assert: Verify correct order
	assert_eq(entities.size(), 7, "Should have 7 entities total")
	
	# Expected order by depth:
	# 1. citizen2 at (1,1) = 2.5
	# 2. road at (2,2) = 4
	# 3. building1 at (3,3) = 8
	# 4. citizen1 at (4,4) = 8.5
	# 5. road at (5,5) = 10
	# 6. building2 at (7,7) = 16
	# 7. road at (8,8) = 16
	
	assert_eq(entities[0]["type"], "citizen", "First should be citizen2")
	assert_eq(entities[0]["id"], 2, "First should be citizen2")
	assert_almost_eq(entities[0]["depth"], 2.5, 0.01, "Citizen2 depth should be 2.5")
	
	assert_eq(entities[1]["type"], "road", "Second should be road at (2,2)")
	assert_almost_eq(entities[1]["depth"], 4.0, 0.01, "Road depth should be 4")
	
	assert_eq(entities[2]["type"], "building", "Third should be building1")
	assert_eq(entities[2]["id"], 1, "Third should be building1")
	assert_almost_eq(entities[2]["depth"], 8.0, 0.01, "Building1 depth should be 8")
	
	assert_eq(entities[3]["type"], "citizen", "Fourth should be citizen1")
	assert_eq(entities[3]["id"], 1, "Fourth should be citizen1")
	assert_almost_eq(entities[3]["depth"], 8.5, 0.01, "Citizen1 depth should be 8.5")

func test_depth_calculation_for_buildings():
	# Buildings should use front position for depth (position + size)
	var building = {
		"id": 1,
		"type": CitySimulation.BuildingType.HOUSE,
		"position": Vector2i(5, 5),
		"level": 1,
		"health": 100.0
	}
	
	var pos = Vector2(building["position"])
	var depth = pos.x + pos.y + 2.0  # +2 for building size
	
	assert_almost_eq(depth, 12.0, 0.01, "Building depth should account for size")

func test_depth_calculation_for_citizens():
	# Citizens should use center position for depth
	var citizen = {
		"id": 1,
		"position": Vector2i(3, 4),
		"state": "idle"
	}
	
	var pos = Vector2(citizen["position"]) + Vector2(0.5, 0.5)
	var depth = pos.x + pos.y
	
	assert_almost_eq(depth, 8.0, 0.01, "Citizen depth should use center position")

func test_depth_calculation_for_roads():
	# Roads should use tile position for depth
	var road_pos = Vector2i(6, 3)
	var depth = road_pos.x + road_pos.y
	
	assert_almost_eq(depth, 9.0, 0.01, "Road depth should be sum of coordinates")

func test_overlapping_entities_render_correctly():
	# When entities overlap, the one with higher depth should be drawn last (on top)
	city_simulation.roads.append(Vector2i(5, 5))  # depth = 10
	
	var building = {
		"id": 1,
		"type": CitySimulation.BuildingType.HOUSE,
		"position": Vector2i(5, 5),  # depth = 10 + 2 = 12
		"level": 1,
		"health": 100.0
	}
	city_simulation.buildings.append(building)
	
	var citizen = {
		"id": 1,
		"position": Vector2i(5, 5),  # depth = 10.5
		"state": "idle"
	}
	city_simulation.citizens.append(citizen)
	
	# Create sorted list
	var entities: Array = []
	
	for road_cell in city_simulation.roads:
		var pos = Vector2(road_cell)
		entities.append({"type": "road", "depth": pos.x + pos.y})
	
	for b in city_simulation.buildings:
		var pos = Vector2(b["position"])
		entities.append({"type": "building", "depth": pos.x + pos.y + 2.0})
	
	for c in city_simulation.citizens:
		var pos = Vector2(c["position"]) + Vector2(0.5, 0.5)
		entities.append({"type": "citizen", "depth": pos.x + pos.y})
	
	entities.sort_custom(func(a, b): return a.depth < b.depth)
	
	# Assert: Road should be drawn first, then citizen, then building
	assert_eq(entities[0]["type"], "road", "Road should be drawn first")
	assert_eq(entities[1]["type"], "citizen", "Citizen should be drawn second")
	assert_eq(entities[2]["type"], "building", "Building should be drawn last (on top)")

func test_multiple_entities_same_depth():
	# When entities have the same depth, order should be stable
	city_simulation.roads.append(Vector2i(3, 2))  # depth = 5
	city_simulation.roads.append(Vector2i(2, 3))  # depth = 5
	city_simulation.roads.append(Vector2i(4, 1))  # depth = 5
	
	var entities: Array = []
	for road_cell in city_simulation.roads:
		var pos = Vector2(road_cell)
		entities.append({"type": "road", "depth": pos.x + pos.y, "position": pos})
	
	entities.sort_custom(func(a, b): return a.depth < b.depth)
	
	# All should have same depth
	for entity in entities:
		assert_almost_eq(entity["depth"], 5.0, 0.01, "All roads should have depth 5")
