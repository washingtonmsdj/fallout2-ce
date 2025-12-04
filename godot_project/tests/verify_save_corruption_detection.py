#!/usr/bin/env python3
"""
Verify save corruption detection
This tests that checksum validation detects corrupted saves
"""

import random
import json

def calculate_checksum(data):
	"""Calculate checksum of save data"""
	# Remove checksum if exists
	data_copy = data.copy()
	data_copy.pop("checksum", None)
	
	# Convert to string and calculate hash
	json_string = json.dumps(data_copy, sort_keys=True)
	return str(hash(json_string))

def validate_checksum(data):
	"""Validate checksum of save data"""
	if "checksum" not in data:
		# Old saves without checksum should be allowed
		return True
	
	saved_checksum = data["checksum"]
	calculated_checksum = calculate_checksum(data)
	
	return saved_checksum == calculated_checksum

def corrupt_data(data):
	"""Corrupt save data"""
	data_copy = data.copy()
	
	# Randomly corrupt a field
	if "player" in data_copy:
		if "hp" in data_copy["player"]:
			data_copy["player"]["hp"] = random.randint(1000, 9999)  # Invalid HP
		elif "level" in data_copy["player"]:
			data_copy["player"]["level"] = -1  # Invalid level
	
	return data_copy

def test_save_corruption_detection(num_iterations=100):
	"""Test the save corruption detection property"""
	passed = 0
	failed = 0
	failures = []
	
	for i in range(num_iterations):
		# Create valid save data
		save_data = {
			"player": {
				"hp": random.randint(1, 100),
				"max_hp": random.randint(50, 200),
				"level": random.randint(1, 20)
			},
			"inventory": {
				"items": [],
				"current_weight": random.randint(0, 150)
			},
			"map": {
				"current_map": f"map_{random.randint(1, 10)}"
			}
		}
		
		# Calculate and add checksum
		save_data["checksum"] = calculate_checksum(save_data)
		
		# Test 1: Valid save should pass validation
		is_valid = validate_checksum(save_data)
		if is_valid:
			passed += 1
		else:
			failed += 1
			failures.append({
				'iteration': i,
				'test': 'valid_save',
				'is_valid': is_valid
			})
			continue
		
		# Test 2: Corrupted save should fail validation
		corrupted_data = corrupt_data(save_data)
		# Keep original checksum (simulating corruption after save)
		corrupted_data["checksum"] = save_data["checksum"]  # Original checksum, but data is corrupted
		
		is_valid_corrupted = validate_checksum(corrupted_data)
		# Should fail because checksum doesn't match corrupted data
		if not is_valid_corrupted:
			passed += 1
		else:
			failed += 1
			failures.append({
				'iteration': i,
				'test': 'corrupted_save',
				'is_valid': is_valid_corrupted,
				'should_be_invalid': True
			})
			continue
		
		# Test 3: Save without checksum should be allowed (backward compatibility)
		save_without_checksum = save_data.copy()
		save_without_checksum.pop("checksum", None)
		is_valid_no_checksum = validate_checksum(save_without_checksum)
		if is_valid_no_checksum:
			passed += 1
		else:
			failed += 1
			failures.append({
				'iteration': i,
				'test': 'save_without_checksum',
				'is_valid': is_valid_no_checksum,
				'should_be_valid': True
			})
			continue
		
		# Test 4: Modified checksum should fail
		save_with_wrong_checksum = save_data.copy()
		save_with_wrong_checksum["checksum"] = "wrong_checksum"
		is_valid_wrong = validate_checksum(save_with_wrong_checksum)
		if not is_valid_wrong:
			passed += 1
		else:
			failed += 1
			failures.append({
				'iteration': i,
				'test': 'wrong_checksum',
				'is_valid': is_valid_wrong,
				'should_be_invalid': True
			})
	
	print(f"=== Property Test: Save Corruption Detection ===")
	print(f"Passed: {passed} / {num_iterations * 4}")
	print(f"Failed: {failed} / {num_iterations * 4}")
	
	if failed > 0:
		print("\n=== Failed Cases (first 5) ===")
		for failure in failures[:5]:
			print(f"Iteration {failure['iteration']}:")
			print(f"  Test: {failure['test']}")
			print(f"  Is valid: {failure['is_valid']}")
			if 'should_be_invalid' in failure:
				print(f"  Should be invalid: {failure['should_be_invalid']}")
			if 'should_be_valid' in failure:
				print(f"  Should be valid: {failure['should_be_valid']}")
		
		if len(failures) > 5:
			print(f"... and {len(failures) - 5} more failures")
		
		print("\nPROPERTY TEST FAILED")
		return False
	else:
		print("\nPROPERTY TEST PASSED")
		return True

if __name__ == "__main__":
	success = test_save_corruption_detection(100)
	exit(0 if success else 1)

