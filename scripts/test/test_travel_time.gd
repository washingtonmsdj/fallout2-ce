class_name TestTravelTime extends GdUnitTestSuite

# Property 12: Travel Time Calculation
# For any two locations, travel time SHALL equal distance / (base_speed * outdoorsman_modifier * vehicle_modifier)
# Validates: Requirements 4.2, 4.6

var worldmap_system: WorldmapSystem

func before_test() -> void:
	worldmap_system = WorldmapSystem.new()

func test_travel_time_without_vehicle() -> void:
	var from = Vector2(0, 0)
	var to = Vector2(100, 0)
	
	var travel_time = worldmap_system.calculate_travel_time(from, to)
	
	# Distance = 100, base_speed = 10.0
	# Expected: 100 / 10.0 = 10.0 hours
	assert_float(travel_time).is_equal(10.0)

func test_travel_time_with_vehicle() -> void:
	var vehicle = Vehicle.new()
	vehicle.speed_multiplier = 2.0
	worldmap_system.set_current_vehicle(vehicle)
	
	var from = Vector2(0, 0)
	var to = Vector2(100, 0)
	
	var travel_time = worldmap_system.calculate_travel_time(from, to)
	
	# Distance = 100, base_speed = 10.0, vehicle_multiplier = 2.0
	# Expected: 100 / (10.0 * 2.0) = 5.0 hours
	assert_float(travel_time).is_equal(5.0)

func test_travel_time_diagonal_distance() -> void:
	var from = Vector2(0, 0)
	var to = Vector2(30, 40)
	
	var travel_time = worldmap_system.calculate_travel_time(from, to)
	
	# Distance = sqrt(30^2 + 40^2) = 50
	# Expected: 50 / 10.0 = 5.0 hours
	assert_float(travel_time).is_equal(5.0)

func test_travel_time_zero_distance() -> void:
	var from = Vector2(0, 0)
	var to = Vector2(0, 0)
	
	var travel_time = worldmap_system.calculate_travel_time(from, to)
	
	# Distance = 0, Expected: 0 hours
	assert_float(travel_time).is_equal(0.0)

func test_travel_time_property_multiple_vehicles() -> void:
	# Property test: travel time scales correctly with vehicle multiplier
	for i in 10:
		var vehicle = Vehicle.new()
		vehicle.speed_multiplier = randf_range(1.0, 5.0)
		worldmap_system.set_current_vehicle(vehicle)
		
		var from = Vector2(0, 0)
		var to = Vector2(100, 0)
		
		var travel_time = worldmap_system.calculate_travel_time(from, to)
		var expected = 100.0 / (10.0 * vehicle.speed_multiplier)
		
		assert_float(travel_time).is_equal(expected)
