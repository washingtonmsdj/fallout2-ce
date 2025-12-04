#!/usr/bin/env python3
"""
Verify the camera bounds clamping logic
This tests that the camera stays within map bounds
"""

import random

class Rect2:
    """Simple Rect2 implementation"""
    def __init__(self, x, y, width, height):
        self.position = (x, y)
        self.size = (width, height)
        self.end = (x + width, y + height)

def clamp_camera_position(pos, bounds, viewport_size, zoom):
    """
    Clamp camera position to keep viewport within bounds
    """
    # Calculate viewport size in world coordinates
    world_viewport_x = viewport_size[0] / zoom
    world_viewport_y = viewport_size[1] / zoom
    half_viewport_x = world_viewport_x / 2.0
    half_viewport_y = world_viewport_y / 2.0
    
    # Calculate bounds considering viewport
    min_x = bounds.position[0] + half_viewport_x
    max_x = bounds.end[0] - half_viewport_x
    min_y = bounds.position[1] + half_viewport_y
    max_y = bounds.end[1] - half_viewport_y
    
    # Clamp position (or center if viewport is larger than map)
    if max_x < min_x:
        # Viewport is wider than map, center it
        clamped_x = (bounds.position[0] + bounds.end[0]) / 2.0
    else:
        clamped_x = max(min_x, min(pos[0], max_x))
    
    if max_y < min_y:
        # Viewport is taller than map, center it
        clamped_y = (bounds.position[1] + bounds.end[1]) / 2.0
    else:
        clamped_y = max(min_y, min(pos[1], max_y))
    
    return (clamped_x, clamped_y)

def verify_clamping(clamped_pos, bounds, viewport_size, zoom):
    """
    Verify that the clamped position keeps the viewport within bounds
    When viewport is larger than map, camera should be centered
    """
    # Calculate viewport size in world coordinates
    world_viewport_x = viewport_size[0] / zoom
    world_viewport_y = viewport_size[1] / zoom
    half_viewport_x = world_viewport_x / 2.0
    half_viewport_y = world_viewport_y / 2.0
    
    map_width = bounds.end[0] - bounds.position[0]
    map_height = bounds.end[1] - bounds.position[1]
    
    # Check if viewport is larger than map in each dimension
    viewport_larger_x = world_viewport_x > map_width
    viewport_larger_y = world_viewport_y > map_height
    
    # Calculate viewport edges
    left_edge = clamped_pos[0] - half_viewport_x
    right_edge = clamped_pos[0] + half_viewport_x
    top_edge = clamped_pos[1] - half_viewport_y
    bottom_edge = clamped_pos[1] + half_viewport_y
    
    # Tolerance for floating point errors
    tolerance = 0.1
    
    # If viewport is larger than map in X, camera should be centered
    if viewport_larger_x:
        expected_center_x = (bounds.position[0] + bounds.end[0]) / 2.0
        if abs(clamped_pos[0] - expected_center_x) > tolerance:
            return False
    else:
        # Viewport fits, check edges
        if left_edge < bounds.position[0] - tolerance:
            return False
        if right_edge > bounds.end[0] + tolerance:
            return False
    
    # If viewport is larger than map in Y, camera should be centered
    if viewport_larger_y:
        expected_center_y = (bounds.position[1] + bounds.end[1]) / 2.0
        if abs(clamped_pos[1] - expected_center_y) > tolerance:
            return False
    else:
        # Viewport fits, check edges
        if top_edge < bounds.position[1] - tolerance:
            return False
        if bottom_edge > bounds.end[1] + tolerance:
            return False
    
    return True

def test_camera_clamping(num_iterations=100):
    """Test the camera bounds clamping property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Generate random map bounds
        map_width = random.uniform(2000, 10000)
        map_height = random.uniform(2000, 10000)
        map_bounds = Rect2(0, 0, map_width, map_height)
        
        # Generate random viewport size
        viewport_width = random.uniform(800, 1920)
        viewport_height = random.uniform(600, 1080)
        viewport_size = (viewport_width, viewport_height)
        
        # Generate random zoom
        zoom_level = random.uniform(0.5, 2.0)
        
        # Generate random camera position (possibly outside bounds)
        camera_x = random.uniform(-1000, map_width + 1000)
        camera_y = random.uniform(-1000, map_height + 1000)
        camera_pos = (camera_x, camera_y)
        
        # Apply clamping
        clamped_pos = clamp_camera_position(camera_pos, map_bounds, viewport_size, zoom_level)
        
        # Verify the property
        if verify_clamping(clamped_pos, map_bounds, viewport_size, zoom_level):
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'original_pos': camera_pos,
                'clamped_pos': clamped_pos,
                'map_bounds': (map_bounds.position, map_bounds.size),
                'viewport_size': viewport_size,
                'zoom': zoom_level
            })
    
    print(f"=== Property Test: Camera Bounds Clamping ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Original pos: {failure['original_pos']}")
            print(f"  Clamped pos:  {failure['clamped_pos']}")
            print(f"  Map bounds:   {failure['map_bounds']}")
            print(f"  Viewport:     {failure['viewport_size']}")
            print(f"  Zoom:         {failure['zoom']:.2f}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_camera_clamping(100)
    exit(0 if success else 1)
