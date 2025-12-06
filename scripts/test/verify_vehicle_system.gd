## Quick verification script for VehicleSystem
## This script verifies that the VehicleSystem is properly implemented
extends Node

func _ready() -> void:
	print("=== VehicleSystem Verification ===")
	
	# Create systems
	var config = CityConfig.new()
	var grid_system = GridSystem.new()
	grid_system.initialize(config.GRID_SIZE_DEFAULT)
	
	var vehicle_system = VehicleSystem.new()
	vehicle_system.grid_system = grid_system
	vehicle_system._initialize_upgrades()
	
	# Test 1: Create vehicle
	print("\n[Test 1] Creating vehicle...")
	var vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(10, 10))
	var vehicle = vehicle_system.get_vehicle(vehicle_id)
	assert(vehicle != null, "Vehicle creation failed")
	assert(vehicle.type == CityConfig.VehicleType.CAR, "Vehicle type mismatch")
	print("✓ Vehicle created successfully")
	
	# Test 2: Fuel management
	print("\n[Test 2] Testing fuel management...")
	var initial_fuel = vehicle.fuel
	var consumed = vehicle_system.consume_fuel(vehicle_id, 10.0)
	assert(consumed, "Fuel consumption failed")
	assert(vehicle.fuel == initial_fuel - 10.0, "Fuel not consumed correctly")
	var fuel_pct = vehicle_system.get_fuel_percentage(vehicle_id)
	assert(fuel_pct > 0 and fuel_pct < 100, "Fuel percentage calculation failed")
	print("✓ Fuel management working")
	
	# Test 3: Cargo management
	print("\n[Test 3] Testing cargo management...")
	var truck_id = vehicle_system.create_vehicle(CityConfig.VehicleType.TRUCK, Vector2i(20, 20))
	var added = vehicle_system.add_cargo(truck_id, 50.0)
	assert(added, "Cargo addition failed")
	var cargo_pct = vehicle_system.get_cargo_percentage(truck_id)
	assert(cargo_pct > 0, "Cargo percentage calculation failed")
	print("✓ Cargo management working")
	
	# Test 4: Passenger management
	print("\n[Test 4] Testing passenger management...")
	var added_passenger = vehicle_system.add_passenger(vehicle_id)
	assert(added_passenger, "Passenger addition failed")
	var passenger_count = vehicle_system.get_passenger_count(vehicle_id)
	assert(passenger_count == 1, "Passenger count incorrect")
	print("✓ Passenger management working")
	
	# Test 5: Vehicle damage and repair
	print("\n[Test 5] Testing damage and repair...")
	var initial_health = vehicle.health
	vehicle_system.damage_vehicle(vehicle_id, 25.0)
	assert(vehicle.health < initial_health, "Damage not applied")
	vehicle_system.repair_vehicle(vehicle_id, 10.0)
	assert(vehicle.health > initial_health - 25.0, "Repair not applied")
	print("✓ Damage and repair working")
	
	# Test 6: Operational status
	print("\n[Test 6] Testing operational status...")
	assert(vehicle_system.is_operational(vehicle_id), "Vehicle should be operational")
	vehicle.health = 0.0
	assert(not vehicle_system.is_operational(vehicle_id), "Vehicle should not be operational")
	assert(vehicle_system.is_destroyed(vehicle_id), "Vehicle should be destroyed")
	print("✓ Operational status working")
	
	# Test 7: Upgrades
	print("\n[Test 7] Testing upgrades...")
	var new_vehicle_id = vehicle_system.create_vehicle(CityConfig.VehicleType.CAR, Vector2i(30, 30))
	var new_vehicle = vehicle_system.get_vehicle(new_vehicle_id)
	var initial_speed = new_vehicle.speed
	
	# Mock economy system
	var mock_economy = MockEconomySystem.new()
	vehicle_system.economy_system = mock_economy
	
	var upgrade_applied = vehicle_system.apply_upgrade(new_vehicle_id, "Turbo Engine")
	assert(upgrade_applied, "Upgrade application failed")
	assert(new_vehicle.speed > initial_speed, "Speed not increased by upgrade")
	print("✓ Upgrades working")
	
	# Test 8: Weapons
	print("\n[Test 8] Testing weapons...")
	assert(not vehicle_system.has_weapon(new_vehicle_id), "Vehicle should not have weapon initially")
	vehicle_system.apply_upgrade(new_vehicle_id, "Weapon Mount")
	assert(vehicle_system.has_weapon(new_vehicle_id), "Vehicle should have weapon after upgrade")
	var damage = vehicle_system.get_weapon_damage(new_vehicle_id)
	assert(damage > 0, "Weapon damage should be positive")
	print("✓ Weapons working")
	
	# Test 9: Statistics
	print("\n[Test 9] Testing statistics...")
	var stats = vehicle_system.get_vehicle_stats(vehicle_id)
	assert(stats.has("id"), "Stats missing id")
	assert(stats.has("type"), "Stats missing type")
	assert(stats.has("fuel_percentage"), "Stats missing fuel_percentage")
	assert(stats.has("is_operational"), "Stats missing is_operational")
	print("✓ Statistics working")
	
	# Test 10: Serialization
	print("\n[Test 10] Testing serialization...")
	var serialized = vehicle_system.serialize()
	assert(serialized.has("vehicles"), "Serialization missing vehicles")
	assert(serialized.has("next_vehicle_id"), "Serialization missing next_vehicle_id")
	
	var new_system = VehicleSystem.new()
	new_system.deserialize(serialized)
	var restored = new_system.get_vehicle(new_vehicle_id)
	assert(restored != null, "Deserialization failed")
	print("✓ Serialization working")
	
	print("\n=== All Tests Passed! ===")
	print("VehicleSystem implementation is complete and functional.")

class MockEconomySystem:
	func consume_resource(resource_type: int, amount: float) -> bool:
		return true
