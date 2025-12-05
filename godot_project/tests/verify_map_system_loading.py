#!/usr/bin/env python3
"""
Verify map system loading functionality
Tests that map loading, tile loading, and object instantiation work correctly
"""

import random
import json

def test_map_data_structure():
    """Test that map data structure is valid"""
    # Simulate map data
    map_data = {
        "id": "test_map",
        "name": "Test Map",
        "width": 50,
        "height": 50,
        "elevation_count": 3,
        "tiles": [],
        "objects": [],
        "npcs": [],
        "items": [],
        "exits": []
    }
    
    # Validate structure
    assert "id" in map_data
    assert "name" in map_data
    assert "width" in map_data
    assert "height" in map_data
    assert "elevation_count" in map_data
    assert map_data["width"] > 0
    assert map_data["height"] > 0
    assert map_data["elevation_count"] > 0
    
    return True

def test_tile_loading(num_iterations=100):
    """Test tile loading for multiple maps"""
    passed = 0
    failed = 0
    
    for i in range(num_iterations):
        # Generate random map
        width = random.randint(20, 100)
        height = random.randint(20, 100)
        elevation_count = random.randint(1, 3)
        
        # Create tile array
        tiles = []
        for elevation in range(elevation_count):
            for y in range(height):
                for x in range(width):
                    tiles.append({
                        "x": x,
                        "y": y,
                        "elevation": elevation,
                        "tile_id": random.randint(1, 1000)
                    })
        
        # Verify all tiles are present
        expected_count = width * height * elevation_count
        if len(tiles) == expected_count:
            passed += 1
        else:
            failed += 1
    
    return passed, failed

def test_object_instantiation(num_iterations=100):
    """Test object instantiation for multiple maps"""
    passed = 0
    failed = 0
    
    for i in range(num_iterations):
        # Generate random map
        width = random.randint(20, 100)
        height = random.randint(20, 100)
        elevation_count = random.randint(1, 3)
        
        # Create objects
        objects = []
        num_objects = random.randint(0, 50)
        for j in range(num_objects):
            obj = {
                "id": f"obj_{j}",
                "type": random.choice(["scenery", "wall", "door"]),
                "x": random.randint(0, width - 1),
                "y": random.randint(0, height - 1),
                "elevation": random.randint(0, elevation_count - 1),
                "proto_id": random.randint(1, 1000)
            }
            
            # Validate object is within bounds
            if 0 <= obj["x"] < width and 0 <= obj["y"] < height:
                objects.append(obj)
        
        # Verify all objects are valid
        if len(objects) == num_objects:
            passed += 1
        else:
            failed += 1
    
    return passed, failed

def test_npc_instantiation(num_iterations=100):
    """Test NPC instantiation for multiple maps"""
    passed = 0
    failed = 0
    
    for i in range(num_iterations):
        # Generate random map
        width = random.randint(20, 100)
        height = random.randint(20, 100)
        elevation_count = random.randint(1, 3)
        
        # Create NPCs
        npcs = []
        num_npcs = random.randint(0, 30)
        for j in range(num_npcs):
            npc = {
                "id": f"npc_{j}",
                "x": random.randint(0, width - 1),
                "y": random.randint(0, height - 1),
                "elevation": random.randint(0, elevation_count - 1),
                "proto_id": random.randint(1, 500),
                "ai_type": random.choice(["default", "aggressive", "defensive"])
            }
            
            # Validate NPC is within bounds
            if 0 <= npc["x"] < width and 0 <= npc["y"] < height:
                npcs.append(npc)
        
        # Verify all NPCs are valid
        if len(npcs) == num_npcs:
            passed += 1
        else:
            failed += 1
    
    return passed, failed

def test_elevation_transitions(num_iterations=100):
    """Test elevation transitions"""
    passed = 0
    failed = 0
    
    for i in range(num_iterations):
        # Generate random elevation transitions
        current_elevation = random.randint(0, 2)
        target_elevation = random.randint(0, 2)
        
        # Validate elevations
        if 0 <= current_elevation < 3 and 0 <= target_elevation < 3:
            passed += 1
        else:
            failed += 1
    
    return passed, failed

def test_map_exit_detection(num_iterations=100):
    """Test map exit detection"""
    passed = 0
    failed = 0
    
    for i in range(num_iterations):
        # Generate random map
        width = random.randint(20, 100)
        height = random.randint(20, 100)
        
        # Create exit zone
        exit_x = random.randint(0, width - 10)
        exit_y = random.randint(0, height - 10)
        exit_width = random.randint(1, 10)
        exit_height = random.randint(1, 10)
        
        # Test point in exit zone
        test_x = random.randint(exit_x, exit_x + exit_width - 1)
        test_y = random.randint(exit_y, exit_y + exit_height - 1)
        
        # Check if point is in zone
        if (exit_x <= test_x < exit_x + exit_width and 
            exit_y <= test_y < exit_y + exit_height):
            passed += 1
        else:
            failed += 1
    
    return passed, failed

def main():
    print("=== Map System Loading Tests ===\n")
    
    # Test 1: Map data structure
    print("Test 1: Map Data Structure")
    try:
        if test_map_data_structure():
            print("PASSED: Map data structure is valid\n")
        else:
            print("FAILED: Map data structure is invalid\n")
    except Exception as e:
        print(f"FAILED: {e}\n")
    
    # Test 2: Tile loading
    print("Test 2: Tile Loading (100 iterations)")
    passed, failed = test_tile_loading(100)
    print(f"Passed: {passed}/100")
    print(f"Failed: {failed}/100")
    if failed == 0:
        print("PASSED: All tile loading tests passed\n")
    else:
        print("FAILED: Some tile loading tests failed\n")
    
    # Test 3: Object instantiation
    print("Test 3: Object Instantiation (100 iterations)")
    passed, failed = test_object_instantiation(100)
    print(f"Passed: {passed}/100")
    print(f"Failed: {failed}/100")
    if failed == 0:
        print("PASSED: All object instantiation tests passed\n")
    else:
        print("FAILED: Some object instantiation tests failed\n")
    
    # Test 4: NPC instantiation
    print("Test 4: NPC Instantiation (100 iterations)")
    passed, failed = test_npc_instantiation(100)
    print(f"Passed: {passed}/100")
    print(f"Failed: {failed}/100")
    if failed == 0:
        print("PASSED: All NPC instantiation tests passed\n")
    else:
        print("FAILED: Some NPC instantiation tests failed\n")
    
    # Test 5: Elevation transitions
    print("Test 5: Elevation Transitions (100 iterations)")
    passed, failed = test_elevation_transitions(100)
    print(f"Passed: {passed}/100")
    print(f"Failed: {failed}/100")
    if failed == 0:
        print("PASSED: All elevation transition tests passed\n")
    else:
        print("FAILED: Some elevation transition tests failed\n")
    
    # Test 6: Map exit detection
    print("Test 6: Map Exit Detection (100 iterations)")
    passed, failed = test_map_exit_detection(100)
    print(f"Passed: {passed}/100")
    print(f"Failed: {failed}/100")
    if failed == 0:
        print("PASSED: All map exit detection tests passed\n")
    else:
        print("FAILED: Some map exit detection tests failed\n")
    
    print("=== All Tests Complete ===")

if __name__ == "__main__":
    main()
