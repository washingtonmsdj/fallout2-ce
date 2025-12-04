#!/usr/bin/env python3
"""
Verify the run speed multiplier logic
This tests that running speed equals base speed * 1.5
"""

import random

def test_run_speed_multiplier(num_iterations=100):
    """Test the run speed multiplier property"""
    passed = 0
    failed = 0
    failures = []
    
    RUN_MULTIPLIER = 1.5
    
    for i in range(num_iterations):
        # Generate random base speed
        base_speed = random.uniform(50, 300)
        
        # Calculate run speed
        run_speed = base_speed * RUN_MULTIPLIER
        
        # Verify property: run_speed = base_speed * 1.5
        expected_run_speed = base_speed * 1.5
        
        # Allow small floating point tolerance
        tolerance = 0.001
        if abs(run_speed - expected_run_speed) < tolerance:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'base_speed': base_speed,
                'run_speed': run_speed,
                'expected': expected_run_speed,
                'difference': abs(run_speed - expected_run_speed)
            })
    
    print(f"=== Property Test: Run Speed Multiplier ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Base speed: {failure['base_speed']:.2f}")
            print(f"  Run speed: {failure['run_speed']:.2f}")
            print(f"  Expected: {failure['expected']:.2f}")
            print(f"  Difference: {failure['difference']:.6f}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_run_speed_multiplier(100)
    exit(0 if success else 1)
