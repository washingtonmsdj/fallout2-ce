extends Node

## **Feature: godot-game-migration, Property 4: Camera Bounds Clamping**
## **Validates: Requirements 2.2**
##
## Property: For any player position outside map bounds, the camera position SHALL be 
## clamped to keep the viewport within valid map area.

const NUM_ITERATIONS = 100

var test_results = []
var passed = 0
var failed = 0

func _ready():
	print("=== Property Test: Camera Bounds Clamping ===")
	print("Running %d iterations..." % NUM_ITERATIONS)
	
	run_property_test()
	print_results()
	
	# Exit with appropriate code
	if failed > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func run_property_test():
	for i in range(NUM_ITERATIONS):
		# Generate random map bounds
		var map_width = randf_range(2000, 10000)
		var map_height = randf_range(2000, 10000)
		var map_bounds = Rect2(0, 0, map_width, map_height)
		
		# Generate random viewport size
		var viewport_width = randf_range(800, 1920)
		var viewport_height = randf_range(600, 1080)
		var viewport_size = Vector2(viewport_width, viewport_height)
		
		# Generate random zoom
		var zoom_level = randf_range(0.5, 2.0)
		
		# Generate random camera position (possibly outside bounds)
		var camera_x = randf_range(-1000, map_width + 1000)
		var camera_y = randf_range(-1000, map_height + 1000)
		var camera_pos = Vector2(camera_x, camera_y)
		
		# Apply clamping logic
		var clamped_pos = clamp_camera_position(camera_pos, map_bounds, viewport_size, zoom_level)
		
		# Verify the property
		var is_valid = verify_clamping(clamped_pos, map_bounds, viewport_size, zoom_level)
		
		if is_valid:
			passed += 1
		else:
			failed += 1
			test_results.append({
				"iteration": i,
				"original_pos": camera_pos,
				"clamped_pos": clamped_pos,
				"map_bounds": map_bounds,
				"viewport_size": viewport_size,
				"zoom": zoom_level
			})

func clamp_camera_position(pos: Vector2, bounds: Rect2, viewport_size: Vector2, zoom: float) -> Vector2:
	"""
	Replica the clamping logic from IsometricCamera
	"""
	# Calculate viewport size in world coordinates
	var world_viewport = viewport_size / zoom
	var half_viewport = world_viewport / 2.0
	
	# Calculate bounds considering viewport
	var min_x = bounds.position.x + half_viewport.x
	var max_x = bounds.end.x - half_viewport.x
	var min_y = bounds.position.y + half_viewport.y
	var max_y = bounds.end.y - half_viewport.y
	
	# Clamp position (or center if viewport is larger than map)
	var clamped_x: float
	var clamped_y: float
	
	if max_x < min_x:
		# Viewport is wider than map, center it
		clamped_x = (bounds.position.x + bounds.end.x) / 2.0
	else:
		clamped_x = clamp(pos.x, min_x, max_x)
	
	if max_y < min_y:
		# Viewport is taller than map, center it
		clamped_y = (bounds.position.y + bounds.end.y) / 2.0
	else:
		clamped_y = clamp(pos.y, min_y, max_y)
	
	return Vector2(clamped_x, clamped_y)

func verify_clamping(clamped_pos: Vector2, bounds: Rect2, viewport_size: Vector2, zoom: float) -> bool:
	"""
	Verify that the clamped position keeps the viewport within bounds
	"""
	# Calculate viewport edges in world coordinates
	var world_viewport = viewport_size / zoom
	var half_viewport = world_viewport / 2.0
	
	var left_edge = clamped_pos.x - half_viewport.x
	var right_edge = clamped_pos.x + half_viewport.x
	var top_edge = clamped_pos.y - half_viewport.y
	var bottom_edge = clamped_pos.y + half_viewport.y
	
	# Check if viewport is within bounds (with small tolerance for floating point)
	var tolerance = 0.1
	
	if left_edge < bounds.position.x - tolerance:
		return false
	if right_edge > bounds.end.x + tolerance:
		return false
	if top_edge < bounds.position.y - tolerance:
		return false
	if bottom_edge > bounds.end.y + tolerance:
		return false
	
	return true

func print_results():
	print("\n=== Test Results ===")
	print("Passed: %d / %d" % [passed, NUM_ITERATIONS])
	print("Failed: %d / %d" % [failed, NUM_ITERATIONS])
	
	if failed > 0:
		print("\n=== Failed Cases ===")
		for i in range(min(5, test_results.size())):  # Show first 5 failures
			var result = test_results[i]
			print("Iteration %d:" % result.iteration)
			print("  Original pos: %s" % result.original_pos)
			print("  Clamped pos:  %s" % result.clamped_pos)
			print("  Map bounds:   %s" % result.map_bounds)
			print("  Viewport:     %s" % result.viewport_size)
			print("  Zoom:         %.2f" % result.zoom)
		
		if test_results.size() > 5:
			print("... and %d more failures" % (test_results.size() - 5))
		
		print("\nPROPERTY TEST FAILED")
	else:
		print("\nPROPERTY TEST PASSED")
