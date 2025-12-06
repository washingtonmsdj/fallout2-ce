## Test suite for VehicleSystem
## Tests vehicle creation, fuel management, cargo, and upgrades
extends GdUnitTestSuite

var vehicle_system: VehicleSystem
var grid_system: GridSystem
var config: CityConfig

func before_test() -> void:
	"""Setup before each test"""
	config = CityConfig.new()
	grid_system = GridSystem.new()
	grid_system.initialize(config.GRID_SIZE_DEFAULT)
	
	vehicle_system = VehicleSystem.new()
	vehicle_system.grid_system = grid_system
	vehicle_system._initialize_upgrades()

# =============================================================================
# VEHICLE CREATION TESTS
# =============================================================================

func test_create_vehicle() -> void:
	"""Test creating a vehicle"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	
	assert_that(vehicle_id).is_equal(0)
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	assert_that(vehicle).is_not_null()
	assert_that(vehicle.type).is_equal(CityConfig.VehicleType.CAR)
	assert_that(vehicle.position).is_equal(Vector2i(10, 10))

func test_create_multiple_vehicles() -> void:
	"""Test creating multiple vehicles"""
	var id1 = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	var id2 = vehicle_system.create_vehicle(CityConfig.VehicleType.TRUCK, Vector2i(20, 20))
	var id3 = vehicle_system.create_vehicle(CityConfig.VehicleType.MOTORCYCLE, Vector2i(30, 30))
	
	assert_that(vehicle_system.get_vehicle_count()).is_equal(3)
	assert_that(id1).is_not_equal(id2)
	assert_that(id2).is_not_equal(id3)

func test_destroy_vehicle() -> void:
	"""Test destroying a vehicle"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	assert_that(vehicle_system.get_vehicle_count()).is_equal(1)
	
	vehicle_system.destroy_vehicle(vehicle_id)
	assert_that(vehicle_system.get_vehicle_count()).is_equal(0)
	assert_that(vehicle_system.get_vehicle(vehicle_id)).is_null()

# =============================================================================
# FUEL MANAGEMENT TESTS
# =============================================================================

func test_fuel_consumption() -> void:
	"""Test fuel consumption"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	var initial_fuel = vehicle.fuel
	
	var consumed = vehicle_system.consume_fuel(vehicle_id, 10.0)
	assert_that(consumed).is_true()
	assert_that(vehicle.fuel).is_equal(initial_fuel - 10.0)

func test_fuel_consumption_insufficient() -> void:
	"""Test fuel consumption with insufficient fuel"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	vehicle.fuel = 5.0
	
	var consumed = vehicle_system.consume_fuel(vehicle_id, 10.0)
	assert_that(consumed).is_false()
	assert_that(vehicle.fuel).is_equal(5.0)

func test_fuel_percentage() -> void:
	"""Test fuel percentage calculation"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	
	# At 50% fuel (default)
	var percentage = vehicle_system.get_fuel_percentage(vehicle_id)
	assert_that(percentage).is_equal(50.0)
	
	# Consume half
	vehicle_system.consume_fuel(vehicle_id, vehicle.max_fuel * 0.25)
	percentage = vehicle_system.get_fuel_percentage(vehicle_id)
	assert_that(percentage).is_equal(25.0)

func test_fuel_critical() -> void:
	"""Test fuel critical detection"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	
	# Not critical at 50%
	assert_that(vehicle_system.is_fuel_critical(vehicle_id)).is_false()
	
	# Critical at 15%
	vehicle.fuel = vehicle.max_fuel * 0.15
	assert_that(vehicle_system.is_fuel_critical(vehicle_id)).is_true()

# =============================================================================
# CARGO MANAGEMENT TESTS
# =============================================================================

func test_add_cargo() -> void:
	"""Test adding cargo"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.TRUCK, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	
	var added = vehicle_system.add_cargo(vehicle_id, 50.0)
	assert_that(added).is_true()
	assert_that(vehicle.cargo).is_equal(50.0)

func test_add_cargo_overflow() -> void:
	"""Test adding cargo beyond capacity"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	
	var added = vehicle_system.add_cargo(vehicle_id, vehicle.max_cargo + 10.0)
	assert_that(added).is_false()
	assert_that(vehicle.cargo).is_equal(0.0)

func test_cargo_percentage() -> void:
	"""Test cargo percentage calculation"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.TRUCK, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	
	vehicle_system.add_cargo(vehicle_id, vehicle.max_cargo * 0.5)
	var percentage = vehicle_system.get_cargo_percentage(vehicle_id)
	assert_that(percentage).is_equal(50.0)

# =============================================================================
# PASSENGER MANAGEMENT TESTS
# =============================================================================

func test_add_passenger() -> void:
	"""Test adding passengers"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	
	var added = vehicle_system.add_passenger(vehicle_id)
	assert_that(added).is_true()
	assert_that(vehicle.passengers).is_equal(1)

func test_add_passenger_overflow() -> void:
	"""Test adding passengers beyond capacity"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.MOTORCYCLE, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	
	# Motorcycle has 2 passenger capacity
	vehicle_system.add_passenger(vehicle_id)
	vehicle_system.add_passenger(vehicle_id)
	
	var added = vehicle_system.add_passenger(vehicle_id)
	assert_that(added).is_false()
	assert_that(vehicle.passengers).is_equal(2)

func test_remove_passenger() -> void:
	"""Test removing passengers"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	
	vehicle_system.add_passenger(vehicle_id)
	var removed = vehicle_system.remove_passenger(vehicle_id)
	assert_that(removed).is_true()
	assert_that(vehicle_system.get_passenger_count(vehicle_id)).is_equal(0)

# =============================================================================
# VEHICLE CONDITION TESTS
# =============================================================================

func test_vehicle_damage() -> void:
	"""Test vehicle damage"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	var initial_health = vehicle.health
	
	vehicle_system.damage_vehicle(vehicle_id, 25.0)
	assert_that(vehicle.health).is_equal(initial_health - 25.0)
	assert_that(vehicle.condition).is_less_than(100.0)

func test_vehicle_repair() -> void:
	"""Test vehicle repair"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	
	vehicle_system.damage_vehicle(vehicle_id, 50.0)
	var damaged_health = vehicle.health
	
	vehicle_system.repair_vehicle(vehicle_id, 25.0)
	assert_that(vehicle.health).is_equal(damaged_health + 25.0)

func test_vehicle_operational() -> void:
	"""Test vehicle operational status"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	
	assert_that(vehicle_system.is_operational(vehicle_id)).is_true()
	
	# Destroy vehicle
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	vehicle.health = 0.0
	assert_that(vehicle_system.is_operational(vehicle_id)).is_false()

func test_vehicle_destroyed() -> void:
	"""Test vehicle destroyed detection"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	
	assert_that(vehicle_system.is_destroyed(vehicle_id)).is_false()
	
	vehicle.health = 0.0
	assert_that(vehicle_system.is_destroyed(vehicle_id)).is_true()

# =============================================================================
# UPGRADE TESTS
# =============================================================================

func test_apply_upgrade() -> void:
	"""Test applying an upgrade"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	var initial_speed = vehicle.speed
	
	# Mock economy system to allow upgrade
	var mock_economy = MockEconomySystem.new()
	vehicle_system.economy_system = mock_economy
	
	var applied = vehicle_system.apply_upgrade(vehicle_id, "Turbo Engine")
	assert_that(applied).is_true()
	assert_that(vehicle.speed).is_greater_than(initial_speed)
	assert_that("Turbo Engine" in vehicle.upgrades).is_true()

func test_duplicate_upgrade() -> void:
	"""Test applying duplicate upgrade"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	
	var mock_economy = MockEconomySystem.new()
	vehicle_system.economy_system = mock_economy
	
	vehicle_system.apply_upgrade(vehicle_id, "Turbo Engine")
	var applied_again = vehicle_system.apply_upgrade(vehicle_id, "Turbo Engine")
	assert_that(applied_again).is_false()

func test_get_available_upgrades() -> void:
	"""Test getting available upgrades"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	
	var available = vehicle_system.get_available_upgrades(vehicle_id)
	assert_that(available.size()).is_equal(5)  # All upgrades available initially

# =============================================================================
# WEAPON TESTS
# =============================================================================

func test_has_weapon() -> void:
	"""Test weapon detection"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	
	assert_that(vehicle_system.has_weapon(vehicle_id)).is_false()
	
	var mock_economy = MockEconomySystem.new()
	vehicle_system.economy_system = mock_economy
	vehicle_system.apply_upgrade(vehicle_id, "Weapon Mount")
	
	assert_that(vehicle_system.has_weapon(vehicle_id)).is_true()

func test_get_weapon_damage() -> void:
	"""Test getting weapon damage"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	
	assert_that(vehicle_system.get_weapon_damage(vehicle_id)).is_equal(0.0)
	
	var mock_economy = MockEconomySystem.new()
	vehicle_system.economy_system = mock_economy
	vehicle_system.apply_upgrade(vehicle_id, "Weapon Mount")
	
	assert_that(vehicle_system.get_weapon_damage(vehicle_id)).is_equal(25.0)

# =============================================================================
# STATISTICS TESTS
# =============================================================================

func test_get_vehicle_stats() -> void:
	"""Test getting vehicle statistics"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	
	var stats = vehicle_system.get_vehicle_stats(vehicle_id)
	assert_that(stats).is_not_empty()
	assert_that(stats.has("id")).is_true()
	assert_that(stats.has("type")).is_true()
	assert_that(stats.has("fuel_percentage")).is_true()
	assert_that(stats.has("is_operational")).is_true()

func test_get_all_vehicles() -> void:
	"""Test getting all vehicles"""
	vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	vehicle_system.create_vehicle(CityConfig.VehicleType.TRUCK, Vector2i(20, 20))
	
	var all_vehicles = vehicle_system.get_all_vehicles()
	assert_that(all_vehicles.size()).is_equal(2)

# =============================================================================
# SERIALIZATION TESTS
# =============================================================================

func test_serialize_vehicle_system() -> void:
	"""Test serializing vehicle system"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	vehicle.fuel = 75.0
	vehicle.cargo = 25.0
	
	var serialized = vehicle_system.serialize()
	assert_that(serialized).is_not_empty()
	assert_that(serialized.has("vehicles")).is_true()
	assert_that(serialized["vehicles"].size()).is_equal(1)

func test_deserialize_vehicle_system() -> void:
	"""Test deserializing vehicle system"""
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	vehicle.fuel = 75.0
	vehicle.cargo = 25.0
	
	var serialized = vehicle_system.serialize()
	
	# Create new system and deserialize
	var new_system = VehicleSystem.new()
	new_system.deserialize(serialized)
	
	var restored_vehicle = new_system.get_vehicle(vehicle_id)
	assert_that(restored_vehicle).is_not_null()
	assert_that(restored_vehicle.fuel).is_equal(75.0)
	assert_that(restored_vehicle.cargo).is_equal(25.0)

# =============================================================================
# HELPER CLASSES
# =============================================================================

class MockEconomySystem:
	func consume_resource(resource_type: int, amount: float) -> bool:
		return true

