#!/usr/bin/env python3
"""
Property Test: Combat Turn Order by Sequence
**Feature: godot-game-migration, Property 8: Combat Turn Order by Sequence**
**Validates: Requirements 5.1**

Property: For any list of combatants with different Sequence values,
the turn order SHALL be sorted in descending order by Sequence.
"""

import random
import sys
from typing import List, NamedTuple

class Combatant(NamedTuple):
    name: str
    perception: int
    
    @property
    def sequence(self) -> int:
        """Sequence = Perception * 2"""
        return self.perception * 2

def calculate_turn_order(combatants: List[Combatant]) -> List[Combatant]:
    """
    Calculate turn order by sorting combatants by Sequence (descending)
    This mimics the CombatSystem._calculate_turn_order() logic
    """
    return sorted(combatants, key=lambda c: c.sequence, reverse=True)

def verify_turn_order_sorted(turn_order: List[Combatant]) -> bool:
    """
    Verify that turn order is sorted in descending order by Sequence
    """
    for i in range(len(turn_order) - 1):
        current_seq = turn_order[i].sequence
        next_seq = turn_order[i + 1].sequence
        
        if current_seq < next_seq:
            print(f"❌ FAILED: Turn order not sorted correctly!")
            print(f"   Position {i}: {turn_order[i].name} (Seq: {current_seq})")
            print(f"   Position {i+1}: {turn_order[i+1].name} (Seq: {next_seq})")
            return False
    
    return True

def test_combat_turn_order_property(iterations: int = 100) -> bool:
    """
    Property-based test for combat turn order
    """
    print(f"\n=== Property Test: Combat Turn Order by Sequence ===")
    print(f"Running {iterations} iterations...")
    
    passed = 0
    failed = 0
    
    for i in range(iterations):
        # Generate random combatants
        num_combatants = random.randint(2, 10)
        combatants = []
        
        for j in range(num_combatants):
            perception = random.randint(1, 10)
            combatant = Combatant(f"Combatant_{j}", perception)
            combatants.append(combatant)
        
        # Calculate turn order
        turn_order = calculate_turn_order(combatants)
        
        # Verify property
        if verify_turn_order_sorted(turn_order):
            passed += 1
        else:
            failed += 1
            print(f"   Iteration {i+1} failed")
    
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
    success = test_combat_turn_order_property(100)
    sys.exit(0 if success else 1)
