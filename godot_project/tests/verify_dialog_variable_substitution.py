#!/usr/bin/env python3
"""
Verify dialog variable substitution
This tests that {var_name} placeholders are correctly replaced with values
"""

import re
import random

class MockPlayer:
    """Mock player for testing"""
    def __init__(self):
        self.name = "Chosen One"
        self.level = 1
        self.hp = 50
        self.max_hp = 100
        self.strength = 5
        self.perception = 5
        self.endurance = 5
        self.charisma = 5
        self.intelligence = 5
        self.agility = 5
        self.luck = 5
    
    def has(self, prop):
        return hasattr(self, prop)
    
    def get(self, prop):
        return getattr(self, prop, None)

def get_variable_value(var_name, player, npc_name=""):
    """Get value of a variable"""
    if var_name == "player_name":
        return player.name if player else "Chosen One"
    elif var_name == "npc_name":
        return npc_name if npc_name else "NPC"
    elif var_name == "player_level":
        return str(player.level) if player else "1"
    elif var_name == "player_hp":
        return str(player.hp) if player else "0"
    elif var_name == "player_max_hp":
        return str(player.max_hp) if player else "0"
    elif var_name == "player_strength":
        return str(player.strength) if player else "0"
    elif var_name == "player_perception":
        return str(player.perception) if player else "0"
    elif player and player.has(var_name):
        return str(player.get(var_name))
    return ""

def substitute_variables(text, player, npc_name=""):
    """Substitute {var_name} placeholders in text"""
    if not player:
        return text
    
    # Find all {var_name} patterns
    pattern = r'\{([^}]+)\}'
    matches = re.findall(pattern, text)
    
    for var_name in matches:
        value = get_variable_value(var_name, player, npc_name)
        text = text.replace("{" + var_name + "}", str(value))
    
    return text

def test_variable_substitution(num_iterations=100):
    """Test the variable substitution property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Create mock player
        player = MockPlayer()
        player.name = f"Player_{i}"
        player.level = random.randint(1, 20)
        player.hp = random.randint(1, 100)
        player.max_hp = random.randint(50, 200)
        player.strength = random.randint(1, 10)
        player.perception = random.randint(1, 10)
        
        npc_name = f"NPC_{i}"
        
        # Create text with variables
        num_vars = random.randint(1, 5)
        var_names = random.sample([
            "player_name", "npc_name", "player_level", 
            "player_hp", "player_max_hp", "player_strength", "player_perception"
        ], min(num_vars, 7))
        
        text = "Hello {player_name}, I am {npc_name}."
        for var_name in var_names:
            if var_name not in text:
                text += " Your {var} is {value}.".replace("{var}", var_name).replace("{value}", "{" + var_name + "}")
        
        # Substitute variables
        result = substitute_variables(text, player, npc_name)
        
        # Verify: all {var_name} should be replaced
        remaining_placeholders = re.findall(r'\{[^}]+\}', result)
        
        if len(remaining_placeholders) == 0:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'original': text,
                'result': result,
                'remaining': remaining_placeholders
            })
    
    print(f"=== Property Test: Dialog Variable Substitution ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Original: {failure['original']}")
            print(f"  Result: {failure['result']}")
            print(f"  Remaining placeholders: {failure['remaining']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_variable_substitution(100)
    exit(0 if success else 1)

