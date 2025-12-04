#!/usr/bin/env python3
"""
Verify consumable item usage effects
This tests that using consumables applies effects and reduces/removes items correctly
"""

import random

class MockPlayer:
    """Mock player for testing"""
    def __init__(self):
        self.hp = 50
        self.max_hp = 100
        self.action_points = 5
        self.max_action_points = 10
    
    def heal(self, amount):
        self.hp = min(self.hp + amount, self.max_hp)
    
    def has_method(self, method):
        return method in ["heal", "restore_action_points"]

def use_consumable(item, player, inventory):
    """
    Simulate using a consumable item
    Returns (success, hp_after, item_removed)
    """
    if not player:
        return (False, player.hp if player else 0, False)
    
    # Apply effects
    hp_restore = item.get("hp_restore", 0)
    if hp_restore > 0:
        player.heal(hp_restore)
    
    # Remove item
    item_id = item.get("id", "")
    quantity = item.get("quantity", 1)
    
    # Check if item exists in inventory
    item_found = False
    for inv_item in inventory:
        if inv_item.get("id") == item_id:
            item_found = True
            if quantity > 1:
                # Reduce quantity
                inv_item["quantity"] = quantity - 1
                return (True, player.hp, False)
            else:
                # Remove item
                inventory.remove(inv_item)
                return (True, player.hp, True)
    
    return (False, player.hp if player else 0, False)

def test_consumable_usage(num_iterations=100):
    """Test the consumable usage property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Create mock player
        player = MockPlayer()
        initial_hp = player.hp
        
        # Create inventory with consumable
        inventory = []
        hp_restore = random.randint(5, 30)
        quantity = random.randint(1, 5)
        
        consumable = {
            "id": "stimpak",
            "type": "DRUG",
            "hp_restore": hp_restore,
            "quantity": quantity
        }
        inventory.append(consumable)
        
        # Use consumable
        success, hp_after, item_removed = use_consumable(consumable, player, inventory)
        
        # Verify properties:
        # 1. Effect should be applied
        # 2. Item should be reduced or removed
        expected_hp = min(initial_hp + hp_restore, player.max_hp)
        
        hp_correct = abs(hp_after - expected_hp) < 0.1
        item_correct = (quantity > 1 and not item_removed) or (quantity == 1 and item_removed)
        
        if success and hp_correct and item_correct:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'initial_hp': initial_hp,
                'hp_after': hp_after,
                'expected_hp': expected_hp,
                'hp_restore': hp_restore,
                'quantity': quantity,
                'item_removed': item_removed,
                'hp_correct': hp_correct,
                'item_correct': item_correct
            })
    
    print(f"=== Property Test: Consumable Usage Effect ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Initial HP: {failure['initial_hp']}")
            print(f"  HP after: {failure['hp_after']}")
            print(f"  Expected HP: {failure['expected_hp']}")
            print(f"  HP restore: {failure['hp_restore']}")
            print(f"  Quantity: {failure['quantity']}")
            print(f"  Item removed: {failure['item_removed']}")
            print(f"  HP correct: {failure['hp_correct']}")
            print(f"  Item correct: {failure['item_correct']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_consumable_usage(100)
    exit(0 if success else 1)

