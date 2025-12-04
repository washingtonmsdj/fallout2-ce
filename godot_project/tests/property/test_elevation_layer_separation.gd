extends Node

## **Feature: godot-game-migration, Property 3: Elevation Layer Separation**
## **Validates: Requirements 1.4**
##
## Property: For any map with N distinct elevations, the renderer SHALL create 
## exactly N separate rendering layers.

const NUM_ITERATIONS = 100

var renderer: Node
var test_results = []
var passed = 0
var failed = 0

func _ready():
	print("=== Property Test: Elevation Layer Separation ===")
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
		# Generate random number of elevations (1-5)
		var num_elevations = randi_range(1, 5)
		
		# Create a temporary parent node
		var parent = Node2D.new()
		add_child(parent)
		
		# Create elevation layers
		var layers = renderer.create_elevation_layers(parent, num_elevations)
		
		# Verify the property
		var is_valid = verify_layer_separation(layers, num_elevations)
		
		if is_valid:
			passed += 1
		else:
			failed += 1
			test_results.append({
				"iteration": i,
				"expected_layers": num_elevations,
				"actual_layers": layers.size(),
				"layer_names": get_layer_names(layers)
			})
		
		# Clean up
		parent.queue_free()

func verify_layer_separation(layers: Array[Node2D], expected_count: int) -> bool:
	"""
	Verify that:
	1. Exactly N layers were created
	2. Each layer has unique elevation metadata
	3. Layers are properly named
	"""
	# Check count
	if layers.size() != expected_count:
		return false
	
	# Check each layer
	var elevations_seen = {}
	for i in range(layers.size()):
		var layer = layers[i]
		
		# Check if it's a Node2D
		if not layer is Node2D:
			return false
		
		# Check if it has elevation metadata
		if not layer.has_meta("elevation"):
			return false
		
		var elevation = layer.get_meta("elevation")
		
		# Check if elevation is unique
		if elevation in elevations_seen:
			return false
		elevations_seen[elevation] = true
		
		# Check if elevation matches index
		if elevation != i:
			return false
		
		# Check naming convention
		var expected_name = "ElevationLayer_" + str(i)
		if layer.name != expected_name:
			return false
	
	return true

func get_layer_names(layers: Array[Node2D]) -> Array:
	"""Get names of all layers for debugging"""
	var names = []
	for layer in layers:
		names.append(layer.name)
	return names

func print_results():
	print("\n=== Test Results ===")
	print("Passed: %d / %d" % [passed, NUM_ITERATIONS])
	print("Failed: %d / %d" % [failed, NUM_ITERATIONS])
	
	if failed > 0:
		print("\n=== Failed Cases ===")
		for i in range(min(5, test_results.size())):  # Show first 5 failures
			var result = test_results[i]
			print("Iteration %d:" % result.iteration)
			print("  Expected layers: %d" % result.expected_layers)
			print("  Actual layers: %d" % result.actual_layers)
			print("  Layer names: %s" % result.layer_names)
		
		if test_results.size() > 5:
			print("... and %d more failures" % (test_results.size() - 5))
		
		print("\nPROPERTY TEST FAILED")
	else:
		print("\nPROPERTY TEST PASSED")
