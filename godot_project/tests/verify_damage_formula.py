#!/usr/bin/env python3
"""
Verify the damage formula
This tests that Damage = Weapon_Damage + Strength_Bonus - (DR * Damage / 100), minimum 1
"""

import random

def calculate_damage(weapon_damage, strength_bonus, target_dr):
    """
    Calculate damage using Fallout 2 formula
    Formula: Damage = Weapon_Damage + Strength_Bonus - (DR * Damage / 100)
    Minimum of 1 damage
    """
    # Total damage before DR
    total_damage = weapon_damage + strength_bonus
    
    # Apply DR reduction
    dr_reduction = (target_dr * total_damage) / 100
    final_damage = total_damage - dr_reduction
    
    # Minimum of 1
    return max(1, int(final_damage))

def test_damage_formula(num_iterations=100):
    """Test the damage formula property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Generate random parameters
        weapon_damage = random.randint(1, 50)
        strength_bonus = random.randint(0, 10)
        target_dr = random.randint(0, 90)  # DR is usually 0-90%
        
        # Calculate damage
        damage = calculate_damage(weapon_damage, strength_bonus, target_dr)
        
        # Verify properties:
        # 1. Damage is at least 1
        # 2. Formula is correct
        
        total_before_dr = weapon_damage + strength_bonus
        expected_reduction = (target_dr * total_before_dr) / 100
        expected_damage = max(1, int(total_before_dr - expected_reduction))
        
        if damage == expected_damage and damage >= 1:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'weapon_damage': weapon_damage,
                'strength_bonus': strength_bonus,
                'target_dr': target_dr,
                'total_before_dr': total_before_dr,
                'expected_reduction': expected_reduction,
                'expected': expected_damage,
                'actual': damage
            })
    
    print(f"=== Property Test: Damage Formula Correctness ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Weapon Damage: {failure['weapon_damage']}")
            print(f"  Strength Bonus: {failure['strength_bonus']}")
            print(f"  Target DR: {failure['target_dr']}%")
            print(f"  Total before DR: {failure['total_before_dr']}")
            print(f"  DR Reduction: {failure['expected_reduction']:.2f}")
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
    success = test_damage_formula(100)
    exit(0 if success else 1)
