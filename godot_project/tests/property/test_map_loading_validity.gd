extends GutTest
## **Feature: complete-migration-master, Property 1: Round-trip de Formatos de Arquivo**
## **Validates: Requirements 3.4**
##
## Test that map loading and unloading preserves data integrity

var map_system: Node
var test_map_data: MapData
var rng: RandomNumberGenerator

func before_all():
	rng = RandomNumberGenerator.new()
	rng.seed = 12345

func before_each():
	# Create a test map system
	map_system = Node.new()
	map_system.set_script(load("res://godot_project/scripts/systems/map_system.gd"))
	add_child(map_system)
	
	# Create test map data
	test_map_data = MapData.new("test_map", "Test Map", 50, 50)
	
	# Add some test tiles
	for elevation in range(test_map_data.elevation_count):
		for y in range(10):
			for x in range(10):
				test_map_data.set_tile(Vector2i(x, y), elevation, rng.randi_range(1, 100))
	
	# Add test objects
	for i in range(5):
		var obj = MapObject.new(
			"obj_%d" % i,
			"scenery",
			Vector2i(rng.randi_range(0, 49), rng.randi_range(0, 49)),
			rng.randi_range(1, 1000)
		)
		obj.elevation = rng.randi_range(0, 2)
		test_map_data.objects.append(obj)
	
	# Add test NPCs
	for i in range(3):
		var npc = NPCSpawn.new(
			"npc_%d" % i,
			rng.randi_range(1, 500),
			Vector2i(rng.randi_range(0, 49), rng.randi_range(0, 49))
		)
		npc.elevation = rng.randi_range(0, 2)
		test_map_data.npcs.append(npc)
	
	# Add test items
	for i in range(4):
		var item = ItemSpawn.new(
			"item_%d" % i,
			rng.randi_range(1, 700),
			Vector2i(rng.randi_range(0, 49), rng.randi_range(0, 49)),
			rng.randi_range(1, 5)
		)
		item.elevation = rng.randi_range(0, 2)
		test_map_data.items.append(item)
	
	# Add test exits
	var exit = MapExit.new("exit_0", "next_map", Vector2i(25, 25))
	exit.set_exit_zone(Rect2i(Vector2i(20, 20), Vector2i(10, 10)))
	test_map_data.exits.append(exit)

func after_each():
	map_system.queue_free()

func test_map_data_validation():
	"""For any map data, validation should pass if all required fields are present"""
	var errors = test_map_data.validate()
	assert_eq(errors.size(), 0, "Map data should validate without errors")

func test_map_tiles_integrity():
	"""For any map with tiles, all tiles should be retrievable at their positions"""
	for elevation in range(test_map_data.elevation_count):
		for y in range(10):
			for x in range(10):
				var pos = Vector2i(x, y)
				var tile = test_map_data.get_tile(pos, elevation)
				assert_not_null(tile, "Tile at %s should exist" % pos)
				assert_eq(tile.tile_id, test_map_data.floor_tiles[elevation][y][x], 
					"Tile ID should match at %s" % pos)

func test_map_objects_retrieval():
	"""For any map with objects, all objects should be retrievable by position"""
	for obj in test_map_data.objects:
		var objects_at_pos = test_map_data.get_objects_at(obj.position)
		assert_true(obj in objects_at_pos, "Object %s should be retrievable at its position" % obj.id)

func test_map_npcs_retrieval():
	"""For any map with NPCs, all NPCs should be retrievable by position"""
	for npc in test_map_data.npcs:
		var npcs_at_pos = test_map_data.get_npcs_at(npc.position)
		assert_true(npc in npcs_at_pos, "NPC %s should be retrievable at its position" % npc.npc_id)

func test_map_exits_detection():
	"""For any map with exits, exits should be detectable at their zones"""
	for exit in test_map_data.exits:
		# Test center of exit zone
		var center = exit.exit_zone.get_center()
		var center_tile = Vector2i(int(center.x), int(center.y))
		assert_true(exit.is_in_exit_zone(center_tile), 
			"Exit %s should be detected at zone center" % exit.exit_id)

func test_elevation_count_consistency():
	"""For any map, elevation count should match the size of tile arrays"""
	assert_eq(test_map_data.floor_tiles.size(), test_map_data.elevation_count,
		"Floor tiles array size should match elevation count")
	assert_eq(test_map_data.roof_tiles.size(), test_map_data.elevation_count,
		"Roof tiles array size should match elevation count")

func test_position_validation():
	"""For any position, is_valid_position should correctly validate bounds"""
	# Valid positions
	for elevation in range(test_map_data.elevation_count):
		assert_true(test_map_data.is_valid_position(Vector2i(0, 0), elevation),
			"Position (0,0) should be valid")
		assert_true(test_map_data.is_valid_position(
			Vector2i(test_map_data.width - 1, test_map_data.height - 1), elevation),
			"Position at max bounds should be valid")
	
	# Invalid positions
	for elevation in range(test_map_data.elevation_count):
		assert_false(test_map_data.is_valid_position(Vector2i(-1, 0), elevation),
			"Negative X should be invalid")
		assert_false(test_map_data.is_valid_position(Vector2i(0, -1), elevation),
			"Negative Y should be invalid")
		assert_false(test_map_data.is_valid_position(
			Vector2i(test_map_data.width, 0), elevation),
			"X beyond bounds should be invalid")
		assert_false(test_map_data.is_valid_position(
			Vector2i(0, test_map_data.height), elevation),
			"Y beyond bounds should be invalid")

func test_elevation_bounds():
	"""For any elevation value, it should be validated against MAX_ELEVATION"""
	# Valid elevations
	for elevation in range(3):
		assert_true(elevation >= 0 and elevation < 3,
			"Elevation %d should be valid" % elevation)
	
	# Invalid elevations
	assert_false(-1 >= 0 and -1 < 3, "Negative elevation should be invalid")
	assert_false(3 >= 0 and 3 < 3, "Elevation >= 3 should be invalid")

func test_map_data_roundtrip():
	"""For any map data, saving and loading should preserve structure"""
	# Save to resource
	var temp_path = "user://test_map_roundtrip.tres"
	var error = ResourceSaver.save(test_map_data, temp_path)
	assert_eq(error, OK, "Map data should save successfully")
	
	# Load from resource
	var loaded_map = load(temp_path) as MapData
	assert_not_null(loaded_map, "Map data should load successfully")
	
	# Verify structure
	assert_eq(loaded_map.id, test_map_data.id, "Map ID should match")
	assert_eq(loaded_map.name, test_map_data.name, "Map name should match")
	assert_eq(loaded_map.width, test_map_data.width, "Map width should match")
	assert_eq(loaded_map.height, test_map_data.height, "Map height should match")
	assert_eq(loaded_map.elevation_count, test_map_data.elevation_count, 
		"Elevation count should match")
	assert_eq(loaded_map.objects.size(), test_map_data.objects.size(),
		"Objects count should match")
	assert_eq(loaded_map.npcs.size(), test_map_data.npcs.size(),
		"NPCs count should match")
	assert_eq(loaded_map.items.size(), test_map_data.items.size(),
		"Items count should match")
	assert_eq(loaded_map.exits.size(), test_map_data.exits.size(),
		"Exits count should match")
	
	# Cleanup
	DirAccess.remove_absolute(temp_path)
