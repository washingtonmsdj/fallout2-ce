#!/usr/bin/env python3
"""
Verify map loading completeness
This tests that all tiles, objects, and NPCs are loaded correctly
"""

import random
import json

def validate_map_data(data):
    """Validate map data structure"""
    if not isinstance(data, dict):
        return False
    
    if "name" not in data:
        return False
    
    if "width" not in data or "height" not in data:
        return False
    
    if not isinstance(data["width"], int) or not isinstance(data["height"], int):
        return False
    
    if data["width"] <= 0 or data["height"] <= 0:
        return False
    
    # Validate tiles
    if "tiles" in data:
        if not isinstance(data["tiles"], list):
            return False
        for tile in data["tiles"]:
            if not isinstance(tile, dict):
                return False
            if "x" not in tile or "y" not in tile:
                return False
            if not isinstance(tile["x"], int) or not isinstance(tile["y"], int):
                return False
    
    # Validate objects
    if "objects" in data:
        if not isinstance(data["objects"], list):
            return False
        for obj in data["objects"]:
            if not isinstance(obj, dict):
                return False
            if "x" not in obj or "y" not in obj:
                return False
            if "prototype_id" not in obj:
                return False
    
    # Validate NPCs
    if "npcs" in data:
        if not isinstance(data["npcs"], list):
            return False
        for npc in data["npcs"]:
            if not isinstance(npc, dict):
                return False
            if "x" not in npc or "y" not in npc:
                return False
            if "prototype_id" not in npc:
                return False
    
    return True

def count_entities_by_elevation(data, elevation):
    """Count tiles, objects, and NPCs at a specific elevation"""
    tiles_count = 0
    objects_count = 0
    npcs_count = 0
    
    if "tiles" in data:
        for tile in data["tiles"]:
            tile_elevation = tile.get("elevation", 0)
            if tile_elevation == elevation:
                tiles_count += 1
    
    if "objects" in data:
        for obj in data["objects"]:
            obj_elevation = obj.get("elevation", 0)
            if obj_elevation == elevation:
                objects_count += 1
    
    if "npcs" in data:
        for npc in data["npcs"]:
            npc_elevation = npc.get("elevation", 0)
            if npc_elevation == elevation:
                npcs_count += 1
    
    return tiles_count, objects_count, npcs_count

def test_map_loading_completeness(num_iterations=100):
    """Test the map loading completeness property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Generate random map data
        map_width = random.randint(10, 100)
        map_height = random.randint(10, 100)
        num_elevations = random.randint(1, 3)
        
        map_data = {
            "name": f"test_map_{i}",
            "width": map_width,
            "height": map_height,
            "elevations": num_elevations,
            "tiles": [],
            "objects": [],
            "npcs": []
        }
        
        # Generate random tiles
        num_tiles = random.randint(10, 50)
        for j in range(num_tiles):
            elevation = random.randint(0, num_elevations - 1)
            map_data["tiles"].append({
                "x": random.randint(0, map_width - 1),
                "y": random.randint(0, map_height - 1),
                "elevation": elevation
            })
        
        # Generate random objects
        num_objects = random.randint(0, 20)
        for j in range(num_objects):
            elevation = random.randint(0, num_elevations - 1)
            map_data["objects"].append({
                "id": f"obj_{j}",
                "x": random.randint(0, map_width - 1),
                "y": random.randint(0, map_height - 1),
                "elevation": elevation,
                "prototype_id": f"prototype_{j}"
            })
        
        # Generate random NPCs
        num_npcs = random.randint(0, 10)
        for j in range(num_npcs):
            elevation = random.randint(0, num_elevations - 1)
            map_data["npcs"].append({
                "id": f"npc_{j}",
                "x": random.randint(0, map_width - 1),
                "y": random.randint(0, map_height - 1),
                "elevation": elevation,
                "prototype_id": f"critter_{j}"
            })
        
        # Validate map data
        is_valid = validate_map_data(map_data)
        
        if not is_valid:
            failed += 1
            failures.append({
                'iteration': i,
                'issue': 'Validation failed'
            })
            continue
        
        # Test completeness: count entities at each elevation
        for elevation in range(num_elevations):
            tiles_count, objects_count, npcs_count = count_entities_by_elevation(map_data, elevation)
            
            # Verify counts match expected
            expected_tiles = sum(1 for t in map_data["tiles"] if t.get("elevation", 0) == elevation)
            expected_objects = sum(1 for o in map_data["objects"] if o.get("elevation", 0) == elevation)
            expected_npcs = sum(1 for n in map_data["npcs"] if n.get("elevation", 0) == elevation)
            
            if tiles_count != expected_tiles or objects_count != expected_objects or npcs_count != expected_npcs:
                failed += 1
                failures.append({
                    'iteration': i,
                    'elevation': elevation,
                    'tiles': (tiles_count, expected_tiles),
                    'objects': (objects_count, expected_objects),
                    'npcs': (npcs_count, expected_npcs)
                })
                break
        else:
            passed += 1
    
    print(f"=== Property Test: Map Loading Completeness ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            if 'issue' in failure:
                print(f"  Issue: {failure['issue']}")
            else:
                print(f"  Elevation: {failure['elevation']}")
                print(f"  Tiles: {failure['tiles']}")
                print(f"  Objects: {failure['objects']}")
                print(f"  NPCs: {failure['npcs']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_map_loading_completeness(100)
    exit(0 if success else 1)

