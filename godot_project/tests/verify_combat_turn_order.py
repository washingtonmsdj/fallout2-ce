#!/usr/bin/env python3
"""
Verify the combat turn order logic
This tests that combatants are ordered by Sequence (Perception * 2) in descending order
"""

import random

def calculate_sequence(perception):
    """Calculate Sequence = Perception * 2"""
    return perception * 2

def sort_combatants_by_sequence(combatants):
    """Sort combatants by Sequence in descending order"""
    return sorted(combatants, key=lambda c: c['sequence'], reverse=True)

def verify_turn_order(sorted_combatants):
    """
    Verify that combatants are in descending order by Sequence
    """
    for i in range(len(sorted_combatants) - 1):
        current_seq = sorted_combatants[i]['sequence']
        next_seq = sorted_combatants[i + 1]['sequence']
        
        # Current should have >= sequence than next
        if current_seq < next_seq:
            return False
    
    return True

def test_combat_turn_order(num_iterations=100):
    """Test the combat turn order property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Generate random combatants
        num_combatants = random.randint(2, 10)
        combatants = []
        
        for j in range(num_combatants):
            perception = random.randint(1, 10)
            sequence = calculate_sequence(perception)
            combatants.append({
                'id': j,
                'name': f'Combatant_{j}',
                'perception': perception,
                'sequence': sequence
            })
        
        # Sort by sequence
        sorted_combatants = sort_combatants_by_sequence(combatants)
        
        # Verify property
        if verify_turn_order(sorted_combatants):
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'num_combatants': num_combatants,
                'sorted_combatants': sorted_combatants[:5]  # Keep first 5
            })
    
    print(f"=== Property Test: Combat Turn Order by Sequence ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Num combatants: {failure['num_combatants']}")
            print(f"  Turn order:")
            for c in failure['sorted_combatants']:
                print(f"    {c['name']}: Perception={c['perception']}, Sequence={c['sequence']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_combat_turn_order(100)
    exit(0 if success else 1)
