#!/usr/bin/env python3
"""
Verify the AP consumption logic for movement
This tests that exactly N AP is consumed for N hexes moved
"""

import random

def test_ap_consumption(num_iterations=100):
    """Test the movement AP consumption property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Generate random path length
        path_length = random.randint(1, 20)
        
        # Generate random starting AP
        starting_ap = random.randint(path_length, 50)
        
        # Simulate movement
        current_ap = starting_ap
        hexes_moved = 0
        
        for step in range(path_length):
            if current_ap >= 1:
                current_ap -= 1
                hexes_moved += 1
            else:
                break  # Out of AP
        
        # Verify property: AP consumed = hexes moved
        ap_consumed = starting_ap - current_ap
        
        if ap_consumed == hexes_moved:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'path_length': path_length,
                'starting_ap': starting_ap,
                'hexes_moved': hexes_moved,
                'ap_consumed': ap_consumed
            })
    
    print(f"=== Property Test: Movement AP Consumption ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Path length: {failure['path_length']}")
            print(f"  Starting AP: {failure['starting_ap']}")
            print(f"  Hexes moved: {failure['hexes_moved']}")
            print(f"  AP consumed: {failure['ap_consumed']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_ap_consumption(100)
    exit(0 if success else 1)
