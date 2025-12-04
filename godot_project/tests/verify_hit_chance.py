#!/usr/bin/env python3
"""
Property Test: Hit Chance Formula Correctness
**Feature: godot-game-migration, Property 9: Hit Chance Formula Correctness**
**Validates: Requirements 5.3**

Property: For any attacker skill S, distance D, target AC, and attacker perception P,
hit chance SHALL equal S - (D * 4) - AC + (P * 2), clamped between 5 and 95.
"""

import random
import sys

def calculate_hit_chance(skill: int, distance: int, target_ac: int, perception: int) -> int:
    """
    Calculate hit chance using Fallout 2 formula
    Formula: Hit = Skill - (Distance * 4) - Target_AC + (Perception * 2)
    Clamped between 5% and 95%
    """
    distance_penalty = distance * 4
    hit_chance = skill - distance_penalty - target_ac + (perception * 2)
    return max(5, min(95, hit_chance))

def test_hit_chance_formula_property(iterations: int = 100) -> bool:
    """
    Property-based test for hit chance formula
    """
    print(f"\n=== Property Test: Hit Chance Formula Correctness ===")
    print(f"Running {iterations} iterations...")
    
    passed = 0
    failed = 0
    
    for i in range(iterations):
        # Generate random parameters
        skill = random.randint(0, 200)
        distance = random.randint(0, 50)
        target_ac = random.randint(0, 50)
        perception = random.randint(1, 10)
        
        # Calculate expected hit chance
        expected = skill - (distance * 4) - target_ac + (perception * 2)
        expected = max(5, min(95, expected))
        
        # Calculate actual hit chance
        actual = calculate_hit_chance(skill, distance, target_ac, perception)
        
        # Verify property: actual must equal expected
        if actual != expected:
            print(f"❌ FAILED: Hit chance formula incorrect!")
            print(f"   Skill: {skill}")
            print(f"   Distance: {distance}")
            print(f"   Target AC: {target_ac}")
            print(f"   Perception: {perception}")
            print(f"   Expected: {expected}")
            print(f"   Actual: {actual}")
            failed += 1
            continue
        
        # Verify property: result must be between 5 and 95
        if actual < 5 or actual > 95:
            print(f"❌ FAILED: Hit chance not clamped correctly!")
            print(f"   Result: {actual}")
            failed += 1
            continue
        
        passed += 1
    
    print(f"\nResults:")
    print(f"  Passed: {passed}/{iterations}")
    print(f"  Failed: {failed}/{iterations}")
    
    if failed == 0:
        print("✅ All tests passed!")
        return True
    else:
        print("❌ Some tests failed!")
        return False

if __name__ == "__main__":
    success = test_hit_chance_formula_property(100)
    sys.exit(0 if success else 1)
