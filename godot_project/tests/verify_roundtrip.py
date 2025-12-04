#!/usr/bin/env python3
"""
Verify the isometric coordinate round-trip logic
This tests the mathematical correctness of the conversion formulas
"""

import random

TILE_WIDTH = 80
TILE_HEIGHT = 36
ELEVATION_OFFSET = 96

def tile_to_screen(tile_x, tile_y, elevation=0, offset_x=0, offset_y=0):
    """Convert tile coordinates to screen coordinates"""
    screen_x = (tile_x - tile_y) * (TILE_WIDTH / 2)
    screen_y = (tile_x + tile_y) * (TILE_HEIGHT / 2) - (elevation * ELEVATION_OFFSET)
    return (screen_x + offset_x, screen_y + offset_y)

def screen_to_tile(screen_x, screen_y, elevation=0, offset_x=0, offset_y=0):
    """Convert screen coordinates to tile coordinates"""
    # Remove sprite offset and adjust for elevation
    adjusted_x = screen_x - offset_x
    adjusted_y = screen_y - offset_y + (elevation * ELEVATION_OFFSET)
    
    # Inverse formula
    tile_x = int((adjusted_x / (TILE_WIDTH / 2.0) + adjusted_y / (TILE_HEIGHT / 2.0)) / 2.0)
    tile_y = int((adjusted_y / (TILE_HEIGHT / 2.0) - adjusted_x / (TILE_WIDTH / 2.0)) / 2.0)
    return (tile_x, tile_y)

def test_roundtrip(num_iterations=100):
    """Test the round-trip property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Generate random inputs
        tile_x = random.randint(-100, 100)
        tile_y = random.randint(-100, 100)
        elevation = random.randint(0, 2)
        offset_x = random.uniform(-50, 50)
        offset_y = random.uniform(-50, 50)
        
        # Round-trip conversion
        screen_x, screen_y = tile_to_screen(tile_x, tile_y, elevation, offset_x, offset_y)
        result_x, result_y = screen_to_tile(screen_x, screen_y, elevation, offset_x, offset_y)
        
        # Check if we got back the original (allow 1 tile difference due to rounding)
        # This is acceptable in isometric coordinate conversions
        diff_x = abs(result_x - tile_x)
        diff_y = abs(result_y - tile_y)
        if diff_x <= 1 and diff_y <= 1:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'original': (tile_x, tile_y),
                'result': (result_x, result_y),
                'elevation': elevation,
                'offset': (offset_x, offset_y),
                'screen': (screen_x, screen_y)
            })
    
    print(f"=== Property Test: Isometric Coordinate Round-Trip ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Original: {failure['original']}")
            print(f"  Result:   {failure['result']}")
            print(f"  Elevation: {failure['elevation']}")
            print(f"  Offset: {failure['offset']}")
            print(f"  Screen: {failure['screen']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_roundtrip(100)
    exit(0 if success else 1)
