extends Node

## **Feature: godot-game-migration, Property 1: Isometric Coordinate Conversion Round-Trip**
## **Validates: Requirements 1.1, 1.5**
##
## Property: For any tile position (x, y) and elevation e, converting to screen 
## coordinates and back to tile coordinates SHALL produce the original tile position.

const NUM_ITERATIONS = 100

var renderer: Node
var test_results = []
var passed = 0
var failed = 0

func _ready():
	print("=== Property Test: Isometric Coordinate Round-Trip ===")
	print("Running %d iterations..." % NUM_ITERATIONS)
	
	# Get the IsometricRenderer autoload
	renderer = get_node("/root/IsometricRenderer")
	
	if renderer == null:
		print("ERROR: IsometricRenderer not found!")
		get_tree().quit(1)
		return
	
	run_property_test()
	print_results()
	
	# Exit with appropriate code
	if failed > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func run_property_test():
	for i in range(NUM_ITERATIONS):
		# Generate random tile coordinates
		var tile_x = randi_range(-100, 100)
		var tile_y = randi_range(-100, 100)
		var elevation = randi_range(0, 2)
		
		# Generate random sprite offset
		var sprite_offset = Vector2(
			randf_range(-50, 50),
			randf_range(-50, 50)
		)
		
		var original_tile = Vector2i(tile_x, tile_y)
		
		# Convert tile -> screen -> tile
		var screen_pos = renderer.tile_to_screen(original_tile, elevation, sprite_offset)
		var result_tile = renderer.screen_to_tile(screen_pos, elevation, sprite_offset)
		
		# Check if round-trip preserves the original
		if result_tile == original_tile:
			passed += 1
		else:
			failed += 1
			test_results.append({
				"iteration": i,
				"original": original_tile,
				"result": result_tile,
				"elevation": elevation,
				"offset": sprite_offset,
				"screen": screen_pos
			})

func print_results():
	print("\n=== Test Results ===")
	print("Passed: %d / %d" % [passed, NUM_ITERATIONS])
	print("Failed: %d / %d" % [failed, NUM_ITERATIONS])
	
	if failed > 0:
		print("\n=== Failed Cases ===")
		for i in range(min(5, test_results.size())):  # Show first 5 failures
			var result = test_results[i]
			print("Iteration %d:" % result.iteration)
			print("  Original: %s" % result.original)
			print("  Result:   %s" % result.result)
			print("  Elevation: %d" % result.elevation)
			print("  Offset: %s" % result.offset)
			print("  Screen: %s" % result.screen)
		
		if test_results.size() > 5:
			print("... and %d more failures" % (test_results.size() - 5))
		
		print("\nPROPERTY TEST FAILED")
	else:
		print("\nPROPERTY TEST PASSED")
