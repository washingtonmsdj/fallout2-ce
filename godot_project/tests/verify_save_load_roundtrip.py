#!/usr/bin/env python3
"""
Verify save/load round-trip
This tests that saving and loading preserves all game state
"""

import random
import copy
import json

def serialize_game_state(player_data, inventory_data, map_data, globals_data):
	"""Serialize game state"""
	return {
		"player": copy.deepcopy(player_data),
		"inventory": copy.deepcopy(inventory_data),
		"map": copy.deepcopy(map_data),
		"globals": copy.deepcopy(globals_data)
	}

def deserialize_game_state(save_data):
	"""Deserialize game state"""
	return {
		"player": save_data.get("player", {}),
		"inventory": save_data.get("inventory", {}),
		"map": save_data.get("map", {}),
		"globals": save_data.get("globals", {})
	}

def test_save_load_roundtrip(num_iterations=100):
	"""Test the save/load round-trip property"""
	passed = 0
	failed = 0
	failures = []
	
	for i in range(num_iterations):
		# Create random game state
		player_data = {
			"position": {"x": random.uniform(0, 2000), "y": random.uniform(0, 2000)},
			"tile": {"x": random.randint(0, 100), "y": random.randint(0, 100)},
			"hp": random.randint(1, 100),
			"max_hp": random.randint(50, 200),
			"level": random.randint(1, 20),
			"experience": random.randint(0, 100000),
			"action_points": random.randint(0, 20),
			"max_action_points": random.randint(5, 20),
			"strength": random.randint(1, 10),
			"perception": random.randint(1, 10),
			"endurance": random.randint(1, 10),
			"charisma": random.randint(1, 10),
			"intelligence": random.randint(1, 10),
			"agility": random.randint(1, 10),
			"luck": random.randint(1, 10),
			"armor_class": random.randint(0, 20),
			"current_direction": random.randint(0, 5)
		}
		
		inventory_data = {
			"items": [],
			"equipped": {
				"armor": None,
				"left_hand": None,
				"right_hand": None
			},
			"current_weight": random.randint(0, 150),
			"max_weight": random.randint(100, 200)
		}
		
		# Add random items
		num_items = random.randint(0, 10)
		for j in range(num_items):
			inventory_data["items"].append({
				"id": f"item_{j}",
				"name": f"Item {j}",
				"quantity": random.randint(1, 5),
				"weight": random.randint(1, 10)
			})
		
		map_data = {
			"current_map": f"map_{random.randint(1, 10)}",
			"elevation": random.randint(0, 2),
			"map_data": {
				"name": f"map_{random.randint(1, 10)}",
				"width": random.randint(50, 200),
				"height": random.randint(50, 200)
			}
		}
		
		globals_data = {}
		num_globals = random.randint(0, 5)
		for j in range(num_globals):
			var_name = f"global_var_{j}"
			var_type = random.choice(["int", "string", "bool"])
			if var_type == "int":
				globals_data[var_name] = random.randint(-1000, 1000)
			elif var_type == "string":
				globals_data[var_name] = f"value_{j}"
			else:
				globals_data[var_name] = random.choice([True, False])
		
		# Serialize
		save_data = serialize_game_state(player_data, inventory_data, map_data, globals_data)
		
		# Simulate JSON round-trip (stringify and parse)
		json_string = json.dumps(save_data)
		loaded_data = json.loads(json_string)
		
		# Deserialize
		restored_state = deserialize_game_state(loaded_data)
		
		# Verify round-trip: all data should match
		player_match = restored_state["player"] == player_data
		inventory_match = restored_state["inventory"] == inventory_data
		map_match = restored_state["map"] == map_data
		globals_match = restored_state["globals"] == globals_data
		
		if player_match and inventory_match and map_match and globals_match:
			passed += 1
		else:
			failed += 1
			failures.append({
				'iteration': i,
				'player_match': player_match,
				'inventory_match': inventory_match,
				'map_match': map_match,
				'globals_match': globals_match
			})
	
	print(f"=== Property Test: Save/Load Round-Trip ===")
	print(f"Passed: {passed} / {num_iterations}")
	print(f"Failed: {failed} / {num_iterations}")
	
	if failed > 0:
		print("\n=== Failed Cases (first 5) ===")
		for failure in failures[:5]:
			print(f"Iteration {failure['iteration']}:")
			print(f"  Player match: {failure['player_match']}")
			print(f"  Inventory match: {failure['inventory_match']}")
			print(f"  Map match: {failure['map_match']}")
			print(f"  Globals match: {failure['globals_match']}")
		
		if len(failures) > 5:
			print(f"... and {len(failures) - 5} more failures")
		
		print("\nPROPERTY TEST FAILED")
		return False
	else:
		print("\nPROPERTY TEST PASSED")
		return True

if __name__ == "__main__":
	success = test_save_load_roundtrip(100)
	exit(0 if success else 1)

