extends Node

## **Feature: godot-game-migration, Property 5: Pathfinding Validity**
## **Validates: Requirements 4.1, 4.2**
##
## Property: For any start and end positions on a map with obstacles, if a path is 
## returned it SHALL not pass through any blocked tiles, and if no path exists the 
## result SHALL be empty.

const NUM_ITERATIONS = 100
const MAP_WIDTH = 50
const MAP_HEIGHT = 50

var pathfinder: Node
var renderer: Node
var test_results = []
var passed = 0
var failed = 0

func _ready():
	print("=== Property Test: Pathfinding Validity ===")
	print("Running %d iterations..." % NUM_ITERATIONS)
	
	# Get references
	pathfinder = get_node("/root/Pathfinder")
	renderer = get_node("/root/IsometricRenderer")
	
	if pathfinder == null:
		print("ERROR: Pathfinder not found!")
		get_tree().quit(1)
		return
	
	if renderer == null:
		print("ERROR: IsometricRenderer not found!")
		get_tree().quit(1)
		return
	
	# Set map size for testing
	renderer.map_width = MAP_WIDTH
	renderer.map_height = MAP_HEIGHT
	
	run_property_test()
	print_results()
	
	# Exit with appropriate code
	if failed > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func run_property_test():
	for i in range(NUM_ITERATIONS):
		# Clear obstacles from previous iteration
		pathfinder.clear_obstacle_cache()
		pathfinder.clear_temporary_obstacles()
		
		# Generate random obstacles
		var num_obstacles = randi_range(10, 100)
		var obstacles = []
		for j in range(num_obstacles):
			var obs_x = randi_range(0, MAP_WIDTH - 1)
			var obs_y = randi_range(0, MAP_HEIGHT - 1)
			var obs_pos = Vector2i(obs_x, obs_y)
			obstacles.append(obs_pos)
			pathfinder.set_obstacle(obs_pos, true)
		
		# Generate random start and end
		var start = Vector2i(randi_range(0, MAP_WIDTH - 1), randi_range(0, MAP_HEIGHT - 1))
		var end = Vector2i(randi_range(0, MAP_WIDTH - 1), randi_range(0, MAP_HEIGHT - 1))
		
		# Make sure start and end are not obstacles
		pathfinder.set_obstacle(start, false)
		pathfinder.set_obstacle(end, false)
		
		# Find path
		var path = pathfinder.find_path(start, end, 0)
		
		# Verify properties
		var valid = verify_path_validity(path, obstacles)
		
		if valid:
			passed += 1
		else:
			failed += 1
			test_results.append({
				"iteration": i,
				"start": start,
				"end": end,
				"path_length": path.size(),
				"num_obstacles": obstacles.size()
			})

func verify_path_validity(path: Array[Vector2i], obstacles: Array) -> bool:
	"""
	Verify that:
	1. Path doesn't pass through obstacles
	2. Path tiles are connected (adjacent)
	"""
	if path.is_empty():
		return true  # Empty path is valid (no path possible)
	
	# Check no obstacles in path
	for tile in path:
		if obstacles.has(tile):
			return false
	
	# Check connectivity
	if path.size() > 1:
		var hex_offsets = [
			Vector2i(1, -1), Vector2i(1, 0), Vector2i(0, 1),
			Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1)
		]
		
		for i in range(path.size() - 1):
			var current = path[i]
			var next_tile = path[i + 1]
			var diff = next_tile - current
			
			if not hex_offsets.has(diff):
				return false
	
	return true

func print_results():
	print("\n=== Test Results ===")
	print("Passed: %d / %d" % [passed, NUM_ITERATIONS])
	print("Failed: %d / %d" % [failed, NUM_ITERATIONS])
	
	if failed > 0:
		print("\n=== Failed Cases ===")
		for i in range(min(5, test_results.size())):
			var result = test_results[i]
			print("Iteration %d:" % result.iteration)
			print("  Start: %s" % result.start)
			print("  End: %s" % result.end)
			print("  Path length: %d" % result.path_length)
			print("  Obstacles: %d" % result.num_obstacles)
		
		if test_results.size() > 5:
			print("... and %d more failures" % (test_results.size() - 5))
		
		print("\nPROPERTY TEST FAILED")
	else:
		print("\nPROPERTY TEST PASSED")
