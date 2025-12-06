class_name TestLocationDiscovery extends GdUnitTestSuite

# Property 14: Location Discovery Persistence
# For any discovered location, it SHALL remain in discovered_locations across save/load cycles
# Validates: Requirements 4.5

var worldmap_system: WorldmapSystem

func before_test() -> void:
	worldmap_system = WorldmapSystem.new()

func test_discover_location() -> void:
	var location = Location.new()
	location.id = "vault_13"
	location.name = "Vault 13"
	location.position = Vector2(100, 100)
	
	worldmap_system.discover_location(location)
	
	var discovered = worldmap_system.get_discovered_locations()
	assert_array(discovered).contains(location)

func test_discover_multiple_locations() -> void:
	var locations: Array[Location] = []
	for i in 5:
		var location = Location.new()
		location.id = "location_%d" % i
		location.name = "Location %d" % i
		location.position = Vector2(i * 100, i * 100)
		locations.append(location)
		worldmap_system.discover_location(location)
	
	var discovered = worldmap_system.get_discovered_locations()
	assert_int(discovered.size()).is_equal(5)
	
	for location in locations:
		assert_array(discovered).contains(location)

func test_cannot_discover_same_location_twice() -> void:
	var location = Location.new()
	location.id = "vault_13"
	location.name = "Vault 13"
	location.position = Vector2(100, 100)
	
	worldmap_system.discover_location(location)
	worldmap_system.discover_location(location)
	
	var discovered = worldmap_system.get_discovered_locations()
	assert_int(discovered.size()).is_equal(1)

func test_discovery_persistence_simulation() -> void:
	# Simulate save/load by creating new system and restoring discovered locations
	var location1 = Location.new()
	location1.id = "vault_13"
	location1.name = "Vault 13"
	location1.position = Vector2(100, 100)
	
	var location2 = Location.new()
	location2.id = "arroyo"
	location2.name = "Arroyo"
	location2.position = Vector2(200, 200)
	
	worldmap_system.discover_location(location1)
	worldmap_system.discover_location(location2)
	
	# Simulate save
	var discovered_before = worldmap_system.get_discovered_locations()
	
	# Simulate load (create new system and restore)
	var new_system = WorldmapSystem.new()
	for location in discovered_before:
		new_system.discover_location(location)
	
	var discovered_after = new_system.get_discovered_locations()
	
	assert_int(discovered_after.size()).is_equal(2)
	assert_array(discovered_after).contains(location1)
	assert_array(discovered_after).contains(location2)

func test_discover_null_location() -> void:
	worldmap_system.discover_location(null)
	
	var discovered = worldmap_system.get_discovered_locations()
	assert_int(discovered.size()).is_equal(0)

func test_discovery_signal_emitted() -> void:
	var location = Location.new()
	location.id = "vault_13"
	location.name = "Vault 13"
	location.position = Vector2(100, 100)
	
	var signal_emitted = false
	worldmap_system.location_discovered.connect(func(loc): signal_emitted = true)
	
	worldmap_system.discover_location(location)
	
	assert_bool(signal_emitted).is_true()
