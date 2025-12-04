#!/usr/bin/env python3
"""
Verify prototype instance isolation
This tests that modifications to instances don't affect prototypes
"""

import random
import copy

def deep_copy(source):
    """Create deep copy of dictionary"""
    if isinstance(source, dict):
        return {key: deep_copy(value) for key, value in source.items()}
    elif isinstance(source, list):
        return [deep_copy(item) for item in source]
    else:
        return source

def create_instance(prototype, instance_id=""):
    """Create instance from prototype"""
    instance = deep_copy(prototype)
    if instance_id:
        instance["instance_id"] = instance_id
    else:
        instance["instance_id"] = prototype["id"] + "_inst"
    instance["prototype_id"] = prototype["id"]
    return instance

def test_prototype_isolation(num_iterations=100):
    """Test the prototype instance isolation property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Create prototype with nested structures
        prototype = {
            "id": f"proto_{i}",
            "name": f"Prototype {i}",
            "value": random.randint(10, 1000),
            "stats": {
                "strength": random.randint(1, 10),
                "perception": random.randint(1, 10),
                "nested": {
                    "level": random.randint(1, 5),
                    "data": [random.randint(1, 100) for _ in range(3)]
                }
            },
            "array": [random.randint(1, 10) for _ in range(5)]
        }
        
        # Store original prototype values
        original_value = prototype["value"]
        original_strength = prototype["stats"]["strength"]
        original_level = prototype["stats"]["nested"]["level"]
        original_array = copy.deepcopy(prototype["array"])
        
        # Create instance
        instance = create_instance(prototype, f"inst_{i}")
        
        # Modify instance
        instance["value"] = random.randint(2000, 5000)
        instance["stats"]["strength"] = random.randint(20, 30)
        instance["stats"]["nested"]["level"] = random.randint(10, 20)
        instance["array"][0] = random.randint(100, 200)
        instance["new_prop"] = "modified"
        
        # Verify isolation: prototype should be unchanged
        prototype_unchanged = (
            prototype["value"] == original_value and
            prototype["stats"]["strength"] == original_strength and
            prototype["stats"]["nested"]["level"] == original_level and
            prototype["array"] == original_array and
            "new_prop" not in prototype
        )
        
        # Verify instance was modified
        instance_modified = (
            instance["value"] != original_value and
            instance["stats"]["strength"] != original_strength and
            instance["stats"]["nested"]["level"] != original_level and
            instance["array"][0] != original_array[0] and
            "new_prop" in instance
        )
        
        if prototype_unchanged and instance_modified:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'prototype_unchanged': prototype_unchanged,
                'instance_modified': instance_modified,
                'prototype_value': prototype["value"],
                'original_value': original_value,
                'instance_value': instance["value"]
            })
    
    print(f"=== Property Test: Prototype Instance Isolation ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Prototype unchanged: {failure['prototype_unchanged']}")
            print(f"  Instance modified: {failure['instance_modified']}")
            print(f"  Prototype value: {failure['prototype_value']}")
            print(f"  Original value: {failure['original_value']}")
            print(f"  Instance value: {failure['instance_value']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_prototype_isolation(100)
    exit(0 if success else 1)

