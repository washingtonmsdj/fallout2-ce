extends Node

## **Feature: complete-migration-master, Property 1: Round-trip de Formatos de Arquivo**
## **Validates: Requirements 3.4**
##
## Property: For any valid game state, saving and then loading SHALL produce
## an equivalent game state (all critical data preserved).

const NUM_ITERATIONS = 100
const TEST_SAVE_SLOT = 9  # Use slot 9 for testing to avoid conflicts

var save_system: Node
var game_manager: Node
var test_results = []
var passed = 0
var failed = 0

func _ready():
	print("=== Property Test: Save/Load Round-Trip ===")
	print("Running %d iterations..." % NUM_ITERATIONS)
	
	# Get required systems
	save_system = get_node_or_null("/root/SaveSystem")
	game_manager = get_node_or_null("/root/GameManager")
	
	if save_system == null:
		print("ERROR: SaveSystem not found!")
		get_tree().quit(1)
		return
	
	if game_manager == null:
		print("ERROR: GameManager not found!")
		get_tree().quit(1)
		return
	
	# Run tests
	await run_property_test()
	print_results()
	
	# Exit with appropriate code
	if failed > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func run_property_test():
	"""Run property-based test with random game states"""
	for i in range(NUM_ITERATIONS):
		# Generate random game state
		var original_state = generate_random_game_state()
		
		# Apply the state
		apply_game_state(original_state)
		
		# Save the game
		var save_success = save_system.save_game(TEST_SAVE_SLOT)
		if not save_success:
			failed += 1
			test_results.append({
				"iteration": i,
				"error": "Save failed",
				"state": original_state
			})
			continue
		
		# Wait a frame for save to complete
		await get_tree().process_frame
		
		# Modify state to ensure load actually changes things
		var modified_state = generate_random_game_state()
		apply_game_state(modified_state)
		
		# Load the game
		var load_success = save_system.load_game(TEST_SAVE_SLOT)
		if not load_success:
			failed += 1
			test_results.append({
				"iteration": i,
				"error": "Load failed",
				"state": original_state
			})
			continue
		
		# Wait a frame for load to complete
		await get_tree().process_frame
		
		# Capture loaded state
		var loaded_state = capture_game_state()
		
		# Compare states
		var comparison = compare_game_states(original_state, loaded_state)
		
		if comparison.success:
			passed += 1
		else:
			failed += 1
			test_results.append({
				"iteration": i,
				"original": original_state,
				"loaded": loaded_state,
				"differences": comparison.differences
			})

func generate_random_game_state() -> Dictionary:
	"""Generate a random but valid game state"""
	var state = {}
	
	# Random player stats
	state["player"] = {
		"hp": randi_range(1, 100),
		"max_hp": randi_range(50, 150),
		"level": randi_range(1, 20),
		"experience": randi_range(0, 10000),
		"action_points": randi_range(5, 15),
		"max_action_points": randi_range(8, 15),
		"strength": randi_range(1, 10),
		"perception": randi_range(1, 10),
		"endurance": randi_range(1, 10),
		"charisma": randi_range(1, 10),
		"intelligence": randi_range(1, 10),
		"agility": randi_range(1, 10),
		"luck": randi_range(1, 10),
		"armor_class": randi_range(0, 50),
		"current_direction": randi_range(0, 5),
		"position": Vector2(randf_range(-1000, 1000), randf_range(-1000, 1000))
	}
	
	# Random game settings
	state["game"] = {
		"current_map": "test_map_" + str(randi_range(1, 10)),
		"game_difficulty": randi_range(0, 2),
		"combat_difficulty": randi_range(0, 2)
	}
	
	# Random inventory
	var num_items = randi_range(0, 10)
	state["inventory"] = {
		"items": [],
		"current_weight": randf_range(0, 200),
		"max_weight": randf_range(100, 300)
	}
	
	for i in range(num_items):
		state["inventory"]["items"].append({
			"id": "item_" + str(i),
			"name": "Test Item " + str(i),
			"quantity": randi_range(1, 99)
		})
	
	# Random visited maps
	var num_visited = randi_range(1, 5)
	state["visited_maps"] = {}
	for i in range(num_visited):
		var map_name = "visited_map_" + str(i)
		state["visited_maps"][map_name] = {
			"elevation": randi_range(0, 2),
			"last_visited": Time.get_unix_time_from_system() - randi_range(0, 10000)
		}
	
	# Random global variables
	var num_globals = randi_range(0, 10)
	state["globals"] = {}
	for i in range(num_globals):
		var var_name = "global_var_" + str(i)
		state["globals"][var_name] = randi_range(0, 1000)
	
	return state

func apply_game_state(state: Dictionary):
	"""Apply a game state to the current game"""
	# Apply player stats
	var player = game_manager.player
	if player and state.has("player"):
		var p = state["player"]
		player.hp = p.get("hp", 30)
		player.max_hp = p.get("max_hp", 30)
		player.level = p.get("level", 1)
		player.experience = p.get("experience", 0)
		player.action_points = p.get("action_points", 10)
		player.max_action_points = p.get("max_action_points", 10)
		player.strength = p.get("strength", 5)
		player.perception = p.get("perception", 5)
		player.endurance = p.get("endurance", 5)
		player.charisma = p.get("charisma", 5)
		player.intelligence = p.get("intelligence", 5)
		player.agility = p.get("agility", 5)
		player.luck = p.get("luck", 5)
		player.armor_class = p.get("armor_class", 0)
		player.current_direction = p.get("current_direction", 1)
		if p.has("position"):
			player.global_position = p["position"]
	
	# Apply game settings
	if state.has("game"):
		var g = state["game"]
		game_manager.current_map_name = g.get("current_map", "")
		game_manager.game_difficulty = g.get("game_difficulty", 1)
		game_manager.combat_difficulty = g.get("combat_difficulty", 1)
	
	# Apply inventory
	var inv = get_node_or_null("/root/InventorySystem")
	if inv and state.has("inventory"):
		var inv_data = state["inventory"]
		inv.items = inv_data.get("items", []).duplicate(true)
		inv.current_weight = inv_data.get("current_weight", 0)
		inv.max_weight = inv_data.get("max_weight", 150)
	
	# Apply visited maps
	if state.has("visited_maps"):
		save_system.visited_maps = state["visited_maps"].duplicate(true)
	
	# Apply global variables
	var script_system = get_node_or_null("/root/ScriptInterpreter")
	if script_system and state.has("globals"):
		for var_name in state["globals"]:
			script_system.set_global_var(var_name, state["globals"][var_name])

func capture_game_state() -> Dictionary:
	"""Capture the current game state"""
	var state = {}
	
	# Capture player stats
	var player = game_manager.player
	if player:
		state["player"] = {
			"hp": player.hp,
			"max_hp": player.max_hp,
			"level": player.level,
			"experience": player.experience,
			"action_points": player.action_points,
			"max_action_points": player.max_action_points,
			"strength": player.strength,
			"perception": player.perception,
			"endurance": player.endurance,
			"charisma": player.charisma,
			"intelligence": player.intelligence,
			"agility": player.agility,
			"luck": player.luck,
			"armor_class": player.armor_class,
			"current_direction": player.current_direction,
			"position": player.global_position
		}
	
	# Capture game settings
	state["game"] = {
		"current_map": game_manager.current_map_name,
		"game_difficulty": game_manager.game_difficulty,
		"combat_difficulty": game_manager.combat_difficulty
	}
	
	# Capture inventory
	var inv = get_node_or_null("/root/InventorySystem")
	if inv:
		state["inventory"] = {
			"items": inv.items.duplicate(true),
			"current_weight": inv.current_weight,
			"max_weight": inv.max_weight
		}
	
	# Capture visited maps
	state["visited_maps"] = save_system.visited_maps.duplicate(true)
	
	# Capture global variables
	var script_system = get_node_or_null("/root/ScriptInterpreter")
	if script_system:
		state["globals"] = script_system.get_all_global_vars()
	
	return state

func compare_game_states(original: Dictionary, loaded: Dictionary) -> Dictionary:
	"""Compare two game states and return differences"""
	var result = {
		"success": true,
		"differences": []
	}
	
	# Compare player stats
	if original.has("player") and loaded.has("player"):
		var p_orig = original["player"]
		var p_load = loaded["player"]
		
		for key in p_orig.keys():
			if not p_load.has(key):
				result.success = false
				result.differences.append("Player missing key: " + key)
				continue
			
			var orig_val = p_orig[key]
			var load_val = p_load[key]
			
			# Special handling for Vector2 (position)
			if orig_val is Vector2 and load_val is Vector2:
				if not orig_val.is_equal_approx(load_val):
					result.success = false
					result.differences.append("Player.%s: %s != %s" % [key, orig_val, load_val])
			elif orig_val != load_val:
				result.success = false
				result.differences.append("Player.%s: %s != %s" % [key, orig_val, load_val])
	
	# Compare game settings
	if original.has("game") and loaded.has("game"):
		var g_orig = original["game"]
		var g_load = loaded["game"]
		
		for key in g_orig.keys():
			if not g_load.has(key):
				result.success = false
				result.differences.append("Game missing key: " + key)
				continue
			
			if g_orig[key] != g_load[key]:
				result.success = false
				result.differences.append("Game.%s: %s != %s" % [key, g_orig[key], g_load[key]])
	
	# Compare inventory (basic check)
	if original.has("inventory") and loaded.has("inventory"):
		var inv_orig = original["inventory"]
		var inv_load = loaded["inventory"]
		
		if inv_orig["items"].size() != inv_load["items"].size():
			result.success = false
			result.differences.append("Inventory item count: %d != %d" % [inv_orig["items"].size(), inv_load["items"].size()])
	
	# Compare visited maps count
	if original.has("visited_maps") and loaded.has("visited_maps"):
		var vm_orig = original["visited_maps"]
		var vm_load = loaded["visited_maps"]
		
		if vm_orig.size() != vm_load.size():
			result.success = false
			result.differences.append("Visited maps count: %d != %d" % [vm_orig.size(), vm_load.size()])
	
	# Compare global variables count
	if original.has("globals") and loaded.has("globals"):
		var g_orig = original["globals"]
		var g_load = loaded["globals"]
		
		if g_orig.size() != g_load.size():
			result.success = false
			result.differences.append("Global vars count: %d != %d" % [g_orig.size(), g_load.size()])
	
	return result

func print_results():
	print("\n=== Test Results ===")
	print("Passed: %d / %d" % [passed, NUM_ITERATIONS])
	print("Failed: %d / %d" % [failed, NUM_ITERATIONS])
	
	if failed > 0:
		print("\n=== Failed Cases ===")
		for i in range(min(5, test_results.size())):  # Show first 5 failures
			var result = test_results[i]
			print("Iteration %d:" % result.iteration)
			
			if result.has("error"):
				print("  Error: %s" % result.error)
			elif result.has("differences"):
				print("  Differences found:")
				for diff in result.differences:
					print("    - %s" % diff)
		
		if test_results.size() > 5:
			print("... and %d more failures" % (test_results.size() - 5))
		
		print("\nPROPERTY TEST FAILED")
	else:
		print("\nPROPERTY TEST PASSED")
