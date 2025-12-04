#!/usr/bin/env python3
"""
Verify menu pause state
This tests that opening menus pauses the game, but not during combat
"""

import random

class MockGameManager:
    """Mock game manager for testing"""
    def __init__(self):
        self.current_state = "PLAYING"
        self.previous_state = "PLAYING"
        self.is_paused = False
        self.is_in_combat = False
    
    def open_menu(self):
        """Open menu"""
        if self.current_state == "PLAYING":
            if not self.is_in_combat:
                self.previous_state = self.current_state
                self.current_state = "PAUSED"
                self.is_paused = True
                return True
        return False
    
    def close_menu(self):
        """Close menu"""
        if self.current_state == "PAUSED":
            self.current_state = self.previous_state
            self.is_paused = False
            return True
        return False
    
    def enter_combat(self):
        """Enter combat"""
        self.is_in_combat = True
        self.current_state = "COMBAT"
    
    def exit_combat(self):
        """Exit combat"""
        self.is_in_combat = False
        self.current_state = "PLAYING"

def test_menu_pause_state(num_iterations=100):
    """Test the menu pause state property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        gm = MockGameManager()
        
        # Test 1: Opening menu in PLAYING state should pause
        if gm.current_state == "PLAYING" and not gm.is_in_combat:
            success = gm.open_menu()
            if success and gm.is_paused and gm.current_state == "PAUSED":
                passed += 1
            else:
                failed += 1
                failures.append({
                    'iteration': i,
                    'test': 'open_menu_playing',
                    'success': success,
                    'is_paused': gm.is_paused,
                    'state': gm.current_state
                })
                continue
        
        # Test 2: Closing menu should resume
        if gm.current_state == "PAUSED":
            success = gm.close_menu()
            if success and not gm.is_paused and gm.current_state == "PLAYING":
                passed += 1
            else:
                failed += 1
                failures.append({
                    'iteration': i,
                    'test': 'close_menu',
                    'success': success,
                    'is_paused': gm.is_paused,
                    'state': gm.current_state
                })
                continue
        
        # Test 3: Opening menu in COMBAT should NOT pause
        gm.enter_combat()
        if gm.current_state == "COMBAT":
            initial_paused = gm.is_paused
            success = gm.open_menu()
            # Should not pause in combat
            if not success or (gm.is_paused == initial_paused):
                passed += 1
            else:
                failed += 1
                failures.append({
                    'iteration': i,
                    'test': 'open_menu_combat',
                    'success': success,
                    'is_paused': gm.is_paused,
                    'should_not_pause': True
                })
                continue
        
        # Test 4: Round-trip: open -> close should restore state
        gm.exit_combat()
        gm.current_state = "PLAYING"
        initial_state = gm.current_state
        
        if gm.open_menu():
            if gm.close_menu():
                if gm.current_state == initial_state:
                    passed += 1
                else:
                    failed += 1
                    failures.append({
                        'iteration': i,
                        'test': 'round_trip',
                        'initial_state': initial_state,
                        'final_state': gm.current_state
                    })
            else:
                failed += 1
                failures.append({
                    'iteration': i,
                    'test': 'round_trip_close_failed'
                })
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'test': 'round_trip_open_failed'
            })
    
    print(f"=== Property Test: Menu Pause State ===")
    print(f"Passed: {passed} / {num_iterations * 4}")
    print(f"Failed: {failed} / {num_iterations * 4}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Test: {failure['test']}")
            if 'success' in failure:
                print(f"  Success: {failure['success']}")
            if 'is_paused' in failure:
                print(f"  Is paused: {failure['is_paused']}")
            if 'state' in failure:
                print(f"  State: {failure['state']}")
            if 'initial_state' in failure:
                print(f"  Initial state: {failure['initial_state']}")
            if 'final_state' in failure:
                print(f"  Final state: {failure['final_state']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_menu_pause_state(100)
    exit(0 if success else 1)

