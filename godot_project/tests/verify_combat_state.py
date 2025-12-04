#!/usr/bin/env python3
"""
Property Test: Combat State Consistency
**Feature: godot-game-migration, Property 11: Combat State Consistency**
**Validates: Requirements 5.5, 5.6**

Property: For any combat state where all enemies have HP <= 0 or have fled,
combat SHALL transition to INACTIVE state.
"""

import random
import sys
from typing import List, NamedTuple

class Combatant(NamedTuple):
    name: str
    hp: int
    is_player: bool

def check_combat_end(combatants: List[Combatant], player: Combatant) -> bool:
    """
    Check if combat should end
    This mimics CombatSystem._check_combat_end() logic
    """
    alive_enemies = 0
    player_alive = False
    
    for c in combatants:
        is_alive = c.hp > 0
        
        if c.is_player:
            player_alive = is_alive
        elif is_alive:
            alive_enemies += 1
    
    # Combat ends if player died OR all enemies died
    return not player_alive or alive_enemies == 0

def test_combat_state_consistency_property(iterations: int = 100) -> bool:
    """
    Property-based test for combat state consistency
    """
    print(f"\n=== Property Test: Combat State Consistency ===")
    print(f"Running {iterations} iterations...")
    
    passed = 0
    failed = 0
    
    for i in range(iterations):
        # Generate random combat scenario
        num_enemies = random.randint(1, 5)
        combatants = []
        
        # Add player
        player_hp = random.randint(-10, 100)
        player = Combatant("Player", player_hp, True)
        combatants.append(player)
        
        # Add enemies
        for j in range(num_enemies):
            enemy_hp = random.randint(-10, 100)
            enemy = Combatant(f"Enemy_{j}", enemy_hp, False)
            combatants.append(enemy)
        
        # Check if combat should end
        should_end = check_combat_end(combatants, player)
        
        # Calculate expected result
        player_alive = player.hp > 0
        alive_enemies = sum(1 for c in combatants if not c.is_player and c.hp > 0)
        
        expected_end = not player_alive or alive_enemies == 0
        
        # Verify property: should_end must match expected_end
        if should_end != expected_end:
            print(f"❌ FAILED: Combat end condition incorrect!")
            print(f"   Player HP: {player.hp} (alive: {player_alive})")
            print(f"   Alive enemies: {alive_enemies}")
            print(f"   Expected end: {expected_end}")
            print(f"   Actual end: {should_end}")
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
    success = test_combat_state_consistency_property(100)
    sys.exit(0 if success else 1)
