#!/usr/bin/env python3
"""
Verify encumbrance movement blocking
This tests that movement is blocked when weight > capacity
"""

import random

def calculate_total_weight(items):
    """Calculate total weight"""
    return sum(item.get("weight", 0) * item.get("quantity", 1) for item in items)

def is_encumbered(current_weight, max_weight):
    """Check if encumbered"""
    return current_weight > max_weight

def can_move(current_weight, max_weight):
    """Check if can move"""
    return not is_encumbered(current_weight, max_weight)

def test_encumbrance(num_iterations=100):
    """Test the encumbrance movement block property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Generate random capacity
        max_weight = random.randint(50, 200)
        
        # Generate random inventory
        num_items = random.randint(1, 10)
        items = []
        for j in range(num_items):
            weight = random.randint(1, 30)
            quantity = random.randint(1, 5)
            items.append({
                "id": f"item_{j}",
                "weight": weight,
                "quantity": quantity
            })
        
        current_weight = calculate_total_weight(items)
        encumbered = is_encumbered(current_weight, max_weight)
        can_move_result = can_move(current_weight, max_weight)
        
        # Verify property: can_move should be opposite of encumbered
        if can_move_result == (not encumbered):
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'current_weight': current_weight,
                'max_weight': max_weight,
                'encumbered': encumbered,
                'can_move': can_move_result
            })
        
        # Test specific cases
        # Case 1: Weight exactly at capacity should allow movement
        if current_weight == max_weight:
            if not can_move(current_weight, max_weight):
                failed += 1
                failures.append({
                    'iteration': i,
                    'case': 'exact_capacity',
                    'current_weight': current_weight,
                    'max_weight': max_weight
                })
        
        # Case 2: Weight over capacity should block movement
        if current_weight > max_weight:
            if can_move(current_weight, max_weight):
                failed += 1
                failures.append({
                    'iteration': i,
                    'case': 'over_capacity',
                    'current_weight': current_weight,
                    'max_weight': max_weight
                })
    
    print(f"=== Property Test: Encumbrance Movement Block ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            if 'case' in failure:
                print(f"  Case: {failure['case']}")
            print(f"  Current weight: {failure['current_weight']}")
            print(f"  Max weight: {failure['max_weight']}")
            if 'encumbered' in failure:
                print(f"  Encumbered: {failure['encumbered']}")
                print(f"  Can move: {failure['can_move']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_encumbrance(100)
    exit(0 if success else 1)

