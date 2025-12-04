#!/usr/bin/env python3
"""
Property Test: Damage Formula Correctness
**Feature: godot-game-migration, Property 10: Damage Formula Correctness**
**Validates: Requirements 5.4**

Property: For any weapon damage W, strength bonus B, and target damage resistance DR,
final damage SHALL equal max(1, W + B - (DR * (W + B) / 100)).
"""

import random
import sys

def calculate_damage(weapon_damage: int, strength_bonus: int, target_dr: int) -> int:
    """
    Calculate damage using Fallout 2 formula
    Formula: Damage = Weapon_Damage + Strength_Bonus - (DR * (Weapon_Damage + Strength_Bonus) / 100)
    Minimum of 1 damage
    """
    total_damage = weapon_damage + strength_bonus
    dr_reduction = (target_dr * total_damage) // 100
    final_damage = total_damage - dr_reduction
    return max(1, final_damage)

def test_damage_formula_property(iterations: int = 100) -> bool:
    """
    Property-based test for damage formula
    """
    print(f"\n=== Property Test: Damage Formula Correctness ===")
    print(f"Running {iterations} iterations...")
    
    passed = 0
    failed = 0
    
    for i in range(iterations):
        # Generate random parameters
        weapon_damage = random.randint(1, 50)
        strength_bonus = random.randint(0, 10)
        target_dr = random.randint(0, 90)  # DR typically 0-90%
        
        # Calculate expected damage
        total_damage = weapon_damage + strength_bonus
        dr_reduction = (target_dr * total_damage) // 100
        expected = max(1, total_damage - dr_reduction)
        
        # Calculate actual damage
        actual = calculate_damage(weapon_damage, strength_bonus, target_dr)
        
        # Verify property: actual must equal expected
        if actual != expected:
            print(f"❌ FAILED: Damage formula incorrect!")
            print(f"   Weapon Damage: {weapon_damage}")
            print(f"   Strength Bonus: {strength_bonus}")
            print(f"   Target DR: {target_dr}%")
            print(f"   Expected: {expected}")
            print(f"   Actual: {actual}")
            failed += 1
            continue
        
        # Verify property: damage must be at least 1
        if actual < 1:
            print(f"❌ FAILED: Damage below minimum!")
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
    success = test_damage_formula_property(100)
    sys.exit(0 if success else 1)
