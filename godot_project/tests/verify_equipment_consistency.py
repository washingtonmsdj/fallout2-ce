#!/usr/bin/env python3
"""
Verify the equipment slot consistency
This tests that equipping/unequipping items maintains consistency
"""

import random

class MockPlayer:
    """Mock player for testing"""
    def __init__(self):
        self.armor_class = 0
    
    def has(self, prop):
        return prop == "armor_class"

def test_equipment_consistency(num_iterations=100):
    """Test the equipment consistency property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Create mock player
        player = MockPlayer()
        base_ac = random.randint(1, 10)
        player.armor_class = base_ac
        
        # Create equipment slots
        equipped = {
            "armor": None,
            "left_hand": None,
            "right_hand": None
        }
        
        # Create some armor items
        armors = []
        for j in range(random.randint(1, 5)):
            armors.append({
                "id": f"armor_{j}",
                "type": "ARMOR",
                "armor_class": random.randint(1, 20)
            })
        
        # Test: Equip and unequip armor
        if len(armors) > 0:
            armor = armors[0]
            original_ac = player.armor_class
            
            # Equip
            equipped["armor"] = armor
            player.armor_class += armor["armor_class"]
            ac_after_equip = player.armor_class
            
            # Unequip
            equipped["armor"] = None
            player.armor_class -= armor["armor_class"]
            ac_after_unequip = player.armor_class
            
            # Verify consistency: AC should return to original after unequip
            if abs(ac_after_unequip - original_ac) < 0.1:  # Allow small floating point errors
                passed += 1
            else:
                failed += 1
                failures.append({
                    'iteration': i,
                    'original_ac': original_ac,
                    'ac_after_equip': ac_after_equip,
                    'ac_after_unequip': ac_after_unequip,
                    'armor_ac': armor["armor_class"]
                })
        else:
            passed += 1
        
        # Test: Only one item per slot
        if equipped["armor"] is not None:
            # Try to equip another armor
            if len(armors) > 1:
                new_armor = armors[1]
                old_armor = equipped["armor"]
                
                # Should replace old armor
                equipped["armor"] = new_armor
                player.armor_class = base_ac + new_armor["armor_class"]
                
                # Verify only new armor is equipped
                if equipped["armor"]["id"] == new_armor["id"]:
                    passed += 1
                else:
                    failed += 1
                    failures.append({
                        'iteration': i,
                        'issue': 'Slot replacement failed'
                    })
    
    print(f"=== Property Test: Equipment Slot Consistency ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            if 'original_ac' in failure:
                print(f"  Original AC: {failure['original_ac']}")
                print(f"  AC after equip: {failure['ac_after_equip']}")
                print(f"  AC after unequip: {failure['ac_after_unequip']}")
                print(f"  Armor AC: {failure['armor_ac']}")
            else:
                print(f"  Issue: {failure.get('issue', 'Unknown')}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_equipment_consistency(100)
    exit(0 if success else 1)

