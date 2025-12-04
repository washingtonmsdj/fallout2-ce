#!/usr/bin/env python3
"""
Verify the hit chance formula
This tests that hit chance = Skill - (Distance * 4) - Target_AC + (Perception * 2), clamped 5-95
"""

import random

def calculate_hit_chance(skill, distance, target_ac, perception):
    """
    Calculate hit chance using Fallout 2 formula
    Formula: Hit = Skill - (Distance * 4) - Target_AC + (Perception * 2)
    Clamped between 5% and 95%
    """
    hit_chance = skill - (distance * 4) - target_ac + (perception * 2)
    return max(5, min(95, hit_chance))

def test_hit_chance_formula(num_iterations=100):
    """Test the hit chance formula property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Generate random parameters
        skill = random.randint(0, 200)
        distance = random.randint(0, 50)
        target_ac = random.randint(0, 50)
        perception = random.randint(1, 10)
        
        # Calculate hit chance
        hit_chance = calculate_hit_chance(skill, distance, target_ac, perception)
        
        # Verify properties:
        # 1. Result is between 5 and 95
        # 2. Formula is correct before clamping
        
        unclamped = skill - (distance * 4) - target_ac + (perception * 2)
        expected = max(5, min(95, unclamped))
        
        if hit_chance == expected and 5 <= hit_chance <= 95:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'skill': skill,
                'distance': distance,
                'target_ac': target_ac,
                'perception': perception,
                'unclamped': unclamped,
                'expected': expected,
                'actual': hit_chance
            })
    
    print(f"=== Property Test: Hit Chance Formula Correctness ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Skill: {failure['skill']}")
            print(f"  Distance: {failure['distance']}")
            print(f"  Target AC: {failure['target_ac']}")
            print(f"  Perception: {failure['perception']}")
            print(f"  Unclamped: {failure['unclamped']}")
            print(f"  Expected: {failure['expected']}")
            print(f"  Actual: {failure['actual']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_hit_chance_formula(100)
    exit(0 if success else 1)
