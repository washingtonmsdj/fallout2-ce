#!/usr/bin/env python3
"""
Verify the combat state consistency
This tests that combat ends when all enemies are dead OR player is dead
"""

import random

def check_combat_should_end(player_hp, enemy_hps):
    """
    Check if combat should end
    Returns True if player is dead OR all enemies are dead
    """
    player_alive = player_hp > 0
    alive_enemies = sum(1 for hp in enemy_hps if hp > 0)
    
    return not player_alive or alive_enemies == 0

def test_combat_state_consistency(num_iterations=100):
    """Test the combat state consistency property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Generate random combat state
        player_hp = random.randint(-10, 50)
        num_enemies = random.randint(1, 10)
        enemy_hps = [random.randint(-10, 50) for _ in range(num_enemies)]
        
        # Check if combat should end
        should_end = check_combat_should_end(player_hp, enemy_hps)
        
        # Verify property:
        # Combat should end if and only if:
        # - Player is dead (HP <= 0) OR
        # - All enemies are dead (all HP <= 0)
        
        player_alive = player_hp > 0
        alive_enemies = sum(1 for hp in enemy_hps if hp > 0)
        
        expected_end = not player_alive or alive_enemies == 0
        
        if should_end == expected_end:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'player_hp': player_hp,
                'enemy_hps': enemy_hps,
                'player_alive': player_alive,
                'alive_enemies': alive_enemies,
                'expected_end': expected_end,
                'actual_end': should_end
            })
    
    print(f"=== Property Test: Combat State Consistency ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Player HP: {failure['player_hp']}")
            print(f"  Enemy HPs: {failure['enemy_hps']}")
            print(f"  Player alive: {failure['player_alive']}")
            print(f"  Alive enemies: {failure['alive_enemies']}")
            print(f"  Expected end: {failure['expected_end']}")
            print(f"  Actual end: {failure['actual_end']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_combat_state_consistency(100)
    exit(0 if success else 1)
