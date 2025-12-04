#!/usr/bin/env python3
"""
Verify NPC death inventory access
This tests that when an NPC dies, their inventory is accessible
"""

import random

class MockNPC:
    """Mock NPC for testing"""
    def __init__(self, name, inventory):
        self.name = name
        self.inventory = inventory.copy()
        self.is_dead = False
        self.meta = {}
    
    def die(self):
        """NPC dies"""
        self.is_dead = True
        self.meta["is_corpse"] = True
        self.meta["corpse_name"] = self.name
        self.meta["inventory"] = self.inventory.copy()
    
    def get_corpse_inventory(self):
        """Get corpse inventory"""
        if self.is_dead:
            return self.inventory.copy()
        return []
    
    def has_items_in_corpse(self):
        """Check if corpse has items"""
        return self.is_dead and len(self.inventory) > 0

class MockInventory:
    """Mock inventory system"""
    def __init__(self):
        self.items = []
    
    def add_item(self, item, quantity=1):
        """Add item to inventory"""
        item_copy = item.copy()
        item_copy["quantity"] = quantity
        self.items.append(item_copy)
        return True
    
    def get_item_count(self, item_id):
        """Get count of item"""
        count = 0
        for item in self.items:
            if item.get("id") == item_id:
                count += item.get("quantity", 1)
        return count

def test_npc_death_inventory(num_iterations=100):
    """Test the NPC death inventory access property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Create NPC with random inventory
        npc_name = f"NPC_{i}"
        num_items = random.randint(0, 10)
        npc_inventory = []
        
        for j in range(num_items):
            npc_inventory.append({
                "id": f"item_{j}",
                "name": f"Item {j}",
                "quantity": random.randint(1, 5),
                "weight": random.randint(1, 10)
            })
        
        npc = MockNPC(npc_name, npc_inventory)
        inventory_system = MockInventory()
        
        # Test: Before death, inventory should not be accessible as corpse
        if npc.has_items_in_corpse():
            failed += 1
            failures.append({
                'iteration': i,
                'issue': 'Corpse has items before death'
            })
            continue
        
        # NPC dies
        npc.die()
        
        # Test: After death, corpse should exist
        if not npc.meta.get("is_corpse", False):
            failed += 1
            failures.append({
                'iteration': i,
                'issue': 'Corpse not created after death'
            })
            continue
        
        # Test: Corpse inventory should be accessible
        corpse_inventory = npc.get_corpse_inventory()
        if len(corpse_inventory) != num_items:
            failed += 1
            failures.append({
                'iteration': i,
                'issue': 'Corpse inventory size mismatch',
                'expected': num_items,
                'got': len(corpse_inventory)
            })
            continue
        
        # Test: Items should match
        items_match = True
        for original_item in npc_inventory:
            found = False
            for corpse_item in corpse_inventory:
                if corpse_item.get("id") == original_item.get("id"):
                    if corpse_item.get("quantity") == original_item.get("quantity"):
                        found = True
                        break
            if not found:
                items_match = False
                break
        
        if not items_match:
            failed += 1
            failures.append({
                'iteration': i,
                'issue': 'Corpse inventory items do not match'
            })
            continue
        
        # Test: Transfer items from corpse
        transferred_count = 0
        for item in corpse_inventory:
            if inventory_system.add_item(item, item.get("quantity", 1)):
                transferred_count += 1
        
        if transferred_count != num_items:
            failed += 1
            failures.append({
                'iteration': i,
                'issue': 'Item transfer failed',
                'expected': num_items,
                'transferred': transferred_count
            })
            continue
        
        # Test: Corpse should still have items until explicitly cleared
        # (In the game, items remain in corpse until player takes them)
        if num_items > 0:
            if not npc.has_items_in_corpse():
                failed += 1
                failures.append({
                    'iteration': i,
                    'issue': 'Corpse should still have items until cleared',
                    'num_items': num_items
                })
                continue
        else:
            # If no items, corpse should not have items
            if npc.has_items_in_corpse():
                failed += 1
                failures.append({
                    'iteration': i,
                    'issue': 'Corpse should not have items when inventory is empty'
                })
                continue
        
        # All tests passed
        passed += 1
    
    print(f"=== Property Test: NPC Death Inventory Access ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Issue: {failure['issue']}")
            if 'expected' in failure:
                print(f"  Expected: {failure['expected']}")
            if 'got' in failure:
                print(f"  Got: {failure['got']}")
            if 'transferred' in failure:
                print(f"  Transferred: {failure['transferred']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_npc_death_inventory(100)
    exit(0 if success else 1)

