extends Node

## **Feature: godot-game-migration, Property 2: Sprite Depth Ordering Consistency**
## **Validates: Requirements 1.2**
##
## Property: For any set of sprites with different positions, the sort order SHALL be 
## deterministic and consistent with the rule: sprites with higher y + elevation * offset 
## appear in front.

const NUM_ITERATIONS = 100

var renderer: Node
var test_results = []
var passed = 0
var failed = 0

func _ready():
	print("=== Property Test: Sprite Depth Ordering Consistency ===")
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
		# Generate random sprites with different positions
		var num_sprites = randi_range(3, 10)
		var sprites = []
		
		for j in range(num_sprites):
			var sprite = Node2D.new()
			var tile_x = randi_range(-50, 50)
			var tile_y = randi_range(-50, 50)
			var elevation = randi_range(0, 2)
			
			# Set sprite metadata
			sprite.set_meta("elevation", elevation)
			sprite.set_meta("tile_pos", Vector2i(tile_x, tile_y))
			
			# Convert to screen position
			var screen_pos = renderer.tile_to_screen(Vector2i(tile_x, tile_y), elevation)
			sprite.global_position = screen_pos
			
			sprites.append(sprite)
		
		# Sort sprites
		renderer.sort_sprites(sprites)
		
		# Verify ordering is consistent with the rule
		var is_valid = verify_ordering(sprites)
		
		if is_valid:
			passed += 1
		else:
			failed += 1
			test_results.append({
				"iteration": i,
				"sprites": sprites.duplicate()
			})
		
		# Clean up
		for sprite in sprites:
			sprite.queue_free()

func verify_ordering(sprites: Array[Node2D]) -> bool:
	"""
	Verify that sprites are ordered correctly:
	- z_index should be monotonically increasing
	- Sprites with higher sort_order should have higher z_index
	"""
	for i in range(sprites.size() - 1):
		var sprite_a = sprites[i]
		var sprite_b = sprites[i + 1]
		
		var elevation_a = sprite_a.get_meta("elevation")
		var elevation_b = sprite_b.get_meta("elevation")
		var tile_a = sprite_a.get_meta("tile_pos")
		var tile_b = sprite_b.get_meta("tile_pos")
		
		var order_a = renderer.get_sort_order(tile_a, elevation_a)
		var order_b = renderer.get_sort_order(tile_b, elevation_b)
		
		# If order_a < order_b, then z_index_a should be <= z_index_b
		if order_a < order_b:
			if sprite_a.z_index > sprite_b.z_index:
				return false
		elif order_a > order_b:
			if sprite_a.z_index >= sprite_b.z_index:
				return false
		# If equal, z_index can be anything (stable sort)
	
	return true

func print_results():
	print("\n=== Test Results ===")
	print("Passed: %d / %d" % [passed, NUM_ITERATIONS])
	print("Failed: %d / %d" % [failed, NUM_ITERATIONS])
	
	if failed > 0:
		print("\n=== Failed Cases ===")
		for i in range(min(3, test_results.size())):  # Show first 3 failures
			var result = test_results[i]
			print("Iteration %d:" % result.iteration)
			print("  Number of sprites: %d" % result.sprites.size())
			
			for j in range(min(5, result.sprites.size())):
				var sprite = result.sprites[j]
				var tile = sprite.get_meta("tile_pos")
				var elev = sprite.get_meta("elevation")
				var order = renderer.get_sort_order(tile, elev)
				print("    Sprite %d: tile=%s, elev=%d, order=%d, z_index=%d" % 
					[j, tile, elev, order, sprite.z_index])
		
		if test_results.size() > 3:
			print("... and %d more failures" % (test_results.size() - 3))
		
		print("\nPROPERTY TEST FAILED")
	else:
		print("\nPROPERTY TEST PASSED")
