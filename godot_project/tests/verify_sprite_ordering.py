#!/usr/bin/env python3
"""
Verify the sprite depth ordering logic
This tests that sprites are ordered consistently by their depth
"""

import random

TILE_WIDTH = 80
TILE_HEIGHT = 36
ELEVATION_OFFSET = 96

def tile_to_screen(tile_x, tile_y, elevation=0):
    """Convert tile coordinates to screen coordinates"""
    screen_x = (tile_x - tile_y) * (TILE_WIDTH / 2)
    screen_y = (tile_x + tile_y) * (TILE_HEIGHT / 2) - (elevation * ELEVATION_OFFSET)
    return (screen_x, screen_y)

def get_sort_order(tile_x, tile_y, elevation=0):
    """Get the sort order for a sprite at given position"""
    screen_x, screen_y = tile_to_screen(tile_x, tile_y, elevation)
    return int(screen_y + elevation * ELEVATION_OFFSET)

def sort_sprites(sprites):
    """Sort sprites by their sort order"""
    # Sort by sort_order
    sorted_sprites = sorted(sprites, key=lambda s: s['order'])
    
    # Assign z_index
    for i, sprite in enumerate(sorted_sprites):
        sprite['z_index'] = i
    
    return sorted_sprites

def verify_ordering(sprites):
    """
    Verify that sprites are ordered correctly:
    - Sprites with lower sort_order should have lower z_index
    """
    for i in range(len(sprites) - 1):
        sprite_a = sprites[i]
        sprite_b = sprites[i + 1]
        
        order_a = sprite_a['order']
        order_b = sprite_b['order']
        z_a = sprite_a['z_index']
        z_b = sprite_b['z_index']
        
        # If order_a < order_b, then z_a should be <= z_b
        if order_a < order_b:
            if z_a > z_b:
                return False
        elif order_a > order_b:
            if z_a >= z_b:
                return False
    
    return True

def test_sprite_ordering(num_iterations=100):
    """Test the sprite ordering property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Generate random sprites
        num_sprites = random.randint(3, 10)
        sprites = []
        
        for j in range(num_sprites):
            tile_x = random.randint(-50, 50)
            tile_y = random.randint(-50, 50)
            elevation = random.randint(0, 2)
            
            order = get_sort_order(tile_x, tile_y, elevation)
            
            sprites.append({
                'id': j,
                'tile': (tile_x, tile_y),
                'elevation': elevation,
                'order': order,
                'z_index': -1  # Will be set by sort
            })
        
        # Sort sprites
        sorted_sprites = sort_sprites(sprites)
        
        # Verify ordering
        if verify_ordering(sorted_sprites):
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'sprites': sorted_sprites[:5]  # Keep first 5 for debugging
            })
    
    print(f"=== Property Test: Sprite Depth Ordering Consistency ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 3) ===")
        for failure in failures[:3]:
            print(f"Iteration {failure['iteration']}:")
            for sprite in failure['sprites']:
                print(f"  Sprite {sprite['id']}: tile={sprite['tile']}, "
                      f"elev={sprite['elevation']}, order={sprite['order']}, "
                      f"z_index={sprite['z_index']}")
        
        if len(failures) > 3:
            print(f"... and {len(failures) - 3} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_sprite_ordering(100)
    exit(0 if success else 1)
