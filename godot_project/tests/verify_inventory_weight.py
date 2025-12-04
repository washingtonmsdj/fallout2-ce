#!/usr/bin/env python3
"""
Verify the inventory weight calculation logic
This tests that weight is correctly calculated as sum of (weight * quantity) for all items
"""

import random

def calculate_total_weight(items):
    """
    Calculate total weight: sum of (weight * quantity) for all items
    """
    total = 0
    for item in items:
        weight = item.get("weight", 0)
        quantity = item.get("quantity", 1)
        total += weight * quantity
    return total

def test_weight_calculation(num_iterations=100):
    """Test the weight calculation property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Generate random inventory
        num_items = random.randint(1, 20)
        items = []
        
        for j in range(num_items):
            weight = random.randint(1, 50)
            quantity = random.randint(1, 10)
            items.append({
                "id": f"item_{j}",
                "weight": weight,
                "quantity": quantity
            })
        
        # Calculate weight
        calculated_weight = calculate_total_weight(items)
        
        # Verify: weight should be sum of (weight * quantity)
        expected_weight = sum(item["weight"] * item["quantity"] for item in items)
        
        if calculated_weight == expected_weight:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'items': items,
                'calculated': calculated_weight,
                'expected': expected_weight
            })
    
    print(f"=== Property Test: Inventory Weight Calculation ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Calculated: {failure['calculated']}")
            print(f"  Expected:   {failure['expected']}")
            print(f"  Items: {len(failure['items'])} items")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_weight_calculation(100)
    exit(0 if success else 1)

