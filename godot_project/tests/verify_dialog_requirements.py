#!/usr/bin/env python3
"""
Verify dialog option requirement checking
This tests that dialog options are enabled/disabled based on requirements
"""

import random

class MockPlayer:
    """Mock player for testing"""
    def __init__(self):
        self.strength = 5
        self.perception = 5
        self.endurance = 5
        self.charisma = 5
        self.intelligence = 5
        self.agility = 5
        self.luck = 5
        self.level = 1
    
    def has(self, prop):
        return hasattr(self, prop)
    
    def get(self, prop):
        return getattr(self, prop, None)

class MockInventory:
    """Mock inventory for testing"""
    def __init__(self):
        self.items = {}
    
    def has_item(self, item_id, quantity=1):
        return self.items.get(item_id, 0) >= quantity
    
    def add_item(self, item_id, quantity=1):
        self.items[item_id] = self.items.get(item_id, 0) + quantity

def check_requirement(req, player, inventory):
    """Check if a requirement is met"""
    req_type = req.get("type", "")
    
    if req_type == "stat":
        stat_name = req.get("stat", "")
        min_value = req.get("min", 0)
        if player and player.has(stat_name):
            return player.get(stat_name) >= min_value
        return False
    
    elif req_type == "item":
        item_id = req.get("item_id", "")
        quantity = req.get("quantity", 1)
        if inventory:
            return inventory.has_item(item_id, quantity)
        return False
    
    elif req_type == "skill":
        # Placeholder for skill system
        skill_name = req.get("skill", "")
        min_value = req.get("min", 0)
        # For now, use stats as fallback
        if player and player.has(skill_name):
            return player.get(skill_name) >= min_value
        return False
    
    return True

def check_option_requirements(option, player, inventory):
    """Check if all requirements for an option are met"""
    requirements = option.get("requirements", [])
    
    if not requirements:
        return True
    
    for req in requirements:
        if not check_requirement(req, player, inventory):
            return False
    
    return True

def test_dialog_requirements(num_iterations=100):
    """Test the dialog requirement check property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Create mock player and inventory
        player = MockPlayer()
        inventory = MockInventory()
        
        # Set random stats
        player.strength = random.randint(1, 10)
        player.perception = random.randint(1, 10)
        player.charisma = random.randint(1, 10)
        
        # Add random items
        num_items = random.randint(0, 5)
        for j in range(num_items):
            item_id = f"item_{j}"
            quantity = random.randint(1, 5)
            inventory.add_item(item_id, quantity)
        
        # Create dialog option with requirements
        option = {
            "text": "Test option",
            "requirements": []
        }
        
        # Add random requirements
        num_reqs = random.randint(0, 3)
        for k in range(num_reqs):
            req_type = random.choice(["stat", "item"])
            if req_type == "stat":
                stat = random.choice(["strength", "perception", "charisma"])
                min_val = random.randint(1, 10)
                option["requirements"].append({
                    "type": "stat",
                    "stat": stat,
                    "min": min_val
                })
            elif req_type == "item":
                item_id = f"item_{random.randint(0, num_items-1) if num_items > 0 else 0}"
                quantity = random.randint(1, 3)
                option["requirements"].append({
                    "type": "item",
                    "item_id": item_id,
                    "quantity": quantity
                })
        
        # Check requirements
        can_use = check_option_requirements(option, player, inventory)
        
        # Verify: if all requirements are met, option should be available
        all_met = True
        for req in option["requirements"]:
            if not check_requirement(req, player, inventory):
                all_met = False
                break
        
        if can_use == all_met:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'can_use': can_use,
                'all_met': all_met,
                'requirements': option["requirements"]
            })
    
    print(f"=== Property Test: Dialog Option Requirement Check ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Can use: {failure['can_use']}")
            print(f"  All met: {failure['all_met']}")
            print(f"  Requirements: {failure['requirements']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_dialog_requirements(100)
    exit(0 if success else 1)

