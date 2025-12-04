#!/usr/bin/env python3
"""
Verify script global variable round-trip
This tests that global variables can be written and read correctly
"""

import random

class MockScriptSystem:
    """Mock script system for testing"""
    def __init__(self):
        self.global_vars = {}
    
    def set_global_var(self, name, value):
        """Set global variable"""
        self.global_vars[name] = value
    
    def get_global_var(self, name, default=None):
        """Get global variable"""
        return self.global_vars.get(name, default)
    
    def has_global_var(self, name):
        """Check if global variable exists"""
        return name in self.global_vars

def test_global_variable_roundtrip(num_iterations=100):
    """Test the global variable round-trip property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        script_system = MockScriptSystem()
        
        # Generate random variable name and value
        var_name = f"test_var_{i}"
        var_type = random.choice(["int", "float", "string", "bool"])
        
        if var_type == "int":
            var_value = random.randint(-1000, 1000)
        elif var_type == "float":
            var_value = random.uniform(-1000.0, 1000.0)
        elif var_type == "string":
            var_value = f"test_string_{random.randint(1, 1000)}"
        else:  # bool
            var_value = random.choice([True, False])
        
        # Write variable
        script_system.set_global_var(var_name, var_value)
        
        # Read variable
        read_value = script_system.get_global_var(var_name)
        
        # Verify round-trip: written value should equal read value
        if read_value == var_value:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'var_name': var_name,
                'written': var_value,
                'read': read_value,
                'type': var_type
            })
        
        # Test: Variable should exist after writing
        if not script_system.has_global_var(var_name):
            failed += 1
            failures.append({
                'iteration': i,
                'issue': 'Variable not found after writing',
                'var_name': var_name
            })
        
        # Test: Reading non-existent variable should return default
        non_existent = script_system.get_global_var("non_existent_var", "default")
        if non_existent != "default":
            failed += 1
            failures.append({
                'iteration': i,
                'issue': 'Default value not returned for non-existent variable',
                'expected': 'default',
                'got': non_existent
            })
        
        # Test: Overwriting variable
        new_value = random.randint(2000, 3000)
        script_system.set_global_var(var_name, new_value)
        overwritten_value = script_system.get_global_var(var_name)
        if overwritten_value == new_value:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'issue': 'Variable overwrite failed',
                'var_name': var_name,
                'expected': new_value,
                'got': overwritten_value
            })
    
    print(f"=== Property Test: Script Global Variable Round-Trip ===")
    print(f"Passed: {passed} / {num_iterations * 2}")
    print(f"Failed: {failed} / {num_iterations * 2}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            if 'issue' in failure:
                print(f"  Issue: {failure['issue']}")
                if 'var_name' in failure:
                    print(f"  Variable: {failure['var_name']}")
                if 'expected' in failure:
                    print(f"  Expected: {failure['expected']}")
                if 'got' in failure:
                    print(f"  Got: {failure['got']}")
            else:
                print(f"  Variable: {failure['var_name']}")
                print(f"  Type: {failure['type']}")
                print(f"  Written: {failure['written']}")
                print(f"  Read: {failure['read']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_global_variable_roundtrip(100)
    exit(0 if success else 1)

