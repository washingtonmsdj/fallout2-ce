#!/usr/bin/env python3
"""
Verify map state persistence
This tests that map state can be saved and restored correctly
"""

import random
import copy

def save_map_state(map_data, modified_entities):
    """Save modified map state"""
    state = {
        "map_name": map_data.get("name", ""),
        "objects": [],
        "npcs": [],
        "tiles": []
    }
    
    # Save modified objects
    if "objects" in map_data:
        for obj in map_data["objects"]:
            obj_id = obj.get("id", "")
            if obj_id in modified_entities.get("objects", {}):
                state["objects"].append({
                    "id": obj_id,
                    "x": obj.get("x", 0),
                    "y": obj.get("y", 0),
                    "custom_data": modified_entities["objects"][obj_id]
                })
    
    # Save modified NPCs
    if "npcs" in map_data:
        for npc in map_data["npcs"]:
            npc_id = npc.get("id", "")
            if npc_id in modified_entities.get("npcs", {}):
                state["npcs"].append({
                    "id": npc_id,
                    "x": npc.get("x", 0),
                    "y": npc.get("y", 0),
                    "hp": modified_entities["npcs"][npc_id].get("hp", npc.get("hp", 50)),
                    "custom_data": modified_entities["npcs"][npc_id]
                })
    
    return state

def restore_map_state(map_data, saved_state):
    """Restore map state from save"""
    if saved_state.get("map_name", "") != map_data.get("name", ""):
        return False
    
    # Restore objects
    for obj_state in saved_state.get("objects", []):
        obj_id = obj_state.get("id", "")
        for obj in map_data.get("objects", []):
            if obj.get("id") == obj_id:
                obj.update(obj_state.get("custom_data", {}))
                break
    
    # Restore NPCs
    for npc_state in saved_state.get("npcs", []):
        npc_id = npc_state.get("id", "")
        for npc in map_data.get("npcs", []):
            if npc.get("id") == npc_id:
                npc["hp"] = npc_state.get("hp", 50)
                npc.update(npc_state.get("custom_data", {}))
                break
    
    return True

def test_map_persistence(num_iterations=100):
    """Test the map persistence property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Create original map data
        map_data = {
            "name": f"test_map_{i}",
            "width": random.randint(10, 100),
            "height": random.randint(10, 100),
            "objects": [],
            "npcs": []
        }
        
        # Add some objects
        num_objects = random.randint(1, 10)
        for j in range(num_objects):
            map_data["objects"].append({
                "id": f"obj_{j}",
                "x": random.randint(0, map_data["width"] - 1),
                "y": random.randint(0, map_data["height"] - 1),
                "prototype_id": f"prototype_{j}"
            })
        
        # Add some NPCs
        num_npcs = random.randint(1, 5)
        for j in range(num_npcs):
            map_data["npcs"].append({
                "id": f"npc_{j}",
                "x": random.randint(0, map_data["width"] - 1),
                "y": random.randint(0, map_data["height"] - 1),
                "prototype_id": f"critter_{j}",
                "hp": 50
            })
        
        # Create modified entities
        modified_entities = {
            "objects": {},
            "npcs": {}
        }
        
        # Modify some objects
        num_modified_objects = random.randint(1, min(3, num_objects))
        for j in range(num_modified_objects):
            obj_id = f"obj_{j}"
            modified_entities["objects"][obj_id] = {
                "custom_prop": random.randint(1, 100)
            }
        
        # Modify some NPCs
        num_modified_npcs = random.randint(1, min(2, num_npcs))
        for j in range(num_modified_npcs):
            npc_id = f"npc_{j}"
            modified_entities["npcs"][npc_id] = {
                "hp": random.randint(1, 50),
                "custom_prop": random.randint(1, 100)
            }
        
        # Save state
        saved_state = save_map_state(map_data, modified_entities)
        
        # Create fresh map data (simulating reload)
        fresh_map_data = copy.deepcopy(map_data)
        # Reset modifications
        for obj in fresh_map_data["objects"]:
            if "custom_prop" in obj:
                del obj["custom_prop"]
        for npc in fresh_map_data["npcs"]:
            npc["hp"] = 50
            if "custom_prop" in npc:
                del npc["custom_prop"]
        
        # Restore state
        restore_success = restore_map_state(fresh_map_data, saved_state)
        
        if not restore_success:
            failed += 1
            failures.append({
                'iteration': i,
                'issue': 'Restore failed'
            })
            continue
        
        # Verify round-trip: modifications should be restored
        all_restored = True
        
        # Check objects
        for obj_id, mod_data in modified_entities["objects"].items():
            found = False
            for obj in fresh_map_data["objects"]:
                if obj.get("id") == obj_id:
                    if obj.get("custom_prop") == mod_data.get("custom_prop"):
                        found = True
                        break
            if not found:
                all_restored = False
                break
        
        # Check NPCs
        if all_restored:
            for npc_id, mod_data in modified_entities["npcs"].items():
                found = False
                for npc in fresh_map_data["npcs"]:
                    if npc.get("id") == npc_id:
                        if npc.get("hp") == mod_data.get("hp") and npc.get("custom_prop") == mod_data.get("custom_prop"):
                            found = True
                            break
                if not found:
                    all_restored = False
                    break
        
        if all_restored:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'issue': 'Round-trip failed'
            })
    
    print(f"=== Property Test: Map State Persistence ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Issue: {failure['issue']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_map_persistence(100)
    exit(0 if success else 1)

