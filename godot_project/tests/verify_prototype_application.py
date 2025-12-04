#!/usr/bin/env python3
"""
Verify prototype application correctness
This tests that instances are created correctly from prototypes
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

def create_item_instance(prototype, instance_id=""):
    """Create item instance from prototype"""
    instance = deep_copy(prototype)
    if instance_id:
        instance["instance_id"] = instance_id
    else:
        instance["instance_id"] = prototype["id"] + "_inst"
    instance["prototype_id"] = prototype["id"]
    return instance

def create_critter_instance(prototype, instance_id=""):
    """Create critter instance from prototype"""
    instance = deep_copy(prototype)
    if instance_id:
        instance["instance_id"] = instance_id
    else:
        instance["instance_id"] = prototype["id"] + "_inst"
    instance["prototype_id"] = prototype["id"]
    return instance

def test_prototype_application(num_iterations=100):
    """Test the prototype application property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Create random item prototype
        item_prototype = {
            "id": f"item_proto_{i}",
            "name": f"Item {i}",
            "weight": random.randint(1, 50),
            "value": random.randint(10, 1000),
            "damage": random.randint(1, 20) if random.random() > 0.5 else None,
            "stats": {
                "strength": random.randint(1, 10),
                "perception": random.randint(1, 10)
            }
        }
        
        # Create instance
        instance = create_item_instance(item_prototype, f"item_inst_{i}")
        
        # Verify: instance should have all prototype properties
        all_props_match = True
        for key, value in item_prototype.items():
            if key not in instance:
                all_props_match = False
                break
            if isinstance(value, dict):
                if not isinstance(instance[key], dict):
                    all_props_match = False
                    break
                for sub_key, sub_value in value.items():
                    if instance[key].get(sub_key) != sub_value:
                        all_props_match = False
                        break
            elif instance[key] != value:
                all_props_match = False
                break
        
        # Verify: instance should have instance_id and prototype_id
        has_ids = "instance_id" in instance and "prototype_id" in instance
        correct_prototype_id = instance.get("prototype_id") == item_prototype["id"]
        
        if all_props_match and has_ids and correct_prototype_id:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'all_props_match': all_props_match,
                'has_ids': has_ids,
                'correct_prototype_id': correct_prototype_id
            })
        
        # Test critter prototype
        critter_prototype = {
            "id": f"critter_proto_{i}",
            "name": f"Critter {i}",
            "hp": random.randint(20, 200),
            "max_hp": random.randint(20, 200),
            "strength": random.randint(1, 10),
            "perception": random.randint(1, 10),
            "stats": {
                "agility": random.randint(1, 10),
                "endurance": random.randint(1, 10)
            }
        }
        
        critter_instance = create_critter_instance(critter_prototype, f"critter_inst_{i}")
        
        # Verify critter instance
        critter_all_props_match = True
        for key, value in critter_prototype.items():
            if key not in critter_instance:
                critter_all_props_match = False
                break
            if isinstance(value, dict):
                if not isinstance(critter_instance[key], dict):
                    critter_all_props_match = False
                    break
                for sub_key, sub_value in value.items():
                    if critter_instance[key].get(sub_key) != sub_value:
                        critter_all_props_match = False
                        break
            elif critter_instance[key] != value:
                critter_all_props_match = False
                break
        
        critter_has_ids = "instance_id" in critter_instance and "prototype_id" in critter_instance
        critter_correct_prototype_id = critter_instance.get("prototype_id") == critter_prototype["id"]
        
        if critter_all_props_match and critter_has_ids and critter_correct_prototype_id:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'type': 'critter',
                'all_props_match': critter_all_props_match,
                'has_ids': critter_has_ids,
                'correct_prototype_id': critter_correct_prototype_id
            })
    
    print(f"=== Property Test: Prototype Application Correctness ===")
    print(f"Passed: {passed} / {num_iterations * 2}")
    print(f"Failed: {failed} / {num_iterations * 2}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            if 'type' in failure:
                print(f"  Type: {failure['type']}")
            print(f"  All props match: {failure['all_props_match']}")
            print(f"  Has IDs: {failure['has_ids']}")
            print(f"  Correct prototype ID: {failure['correct_prototype_id']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_prototype_application(100)
    exit(0 if success else 1)

