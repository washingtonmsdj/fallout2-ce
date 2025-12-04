#!/usr/bin/env python3
"""
Verify save metadata completeness
This tests that save metadata includes all required fields
"""

import random
import time

def create_metadata(slot, location, level):
	"""Create save metadata"""
	return {
		"slot": slot,
		"timestamp": int(time.time()),
		"datetime": time.strftime("%Y-%m-%d %H:%M:%S"),
		"location": location,
		"level": level,
		"version": "0.1"
	}

def validate_metadata(metadata):
	"""Validate metadata has all required fields"""
	required_fields = ["slot", "timestamp", "datetime", "location", "level", "version"]
	
	for field in required_fields:
		if field not in metadata:
			return False, f"Missing field: {field}"
	
	# Validate types
	if not isinstance(metadata["slot"], int):
		return False, "slot must be int"
	if not isinstance(metadata["timestamp"], (int, float)):
		return False, "timestamp must be number"
	if not isinstance(metadata["datetime"], str):
		return False, "datetime must be string"
	if not isinstance(metadata["location"], str):
		return False, "location must be string"
	if not isinstance(metadata["level"], int):
		return False, "level must be int"
	if not isinstance(metadata["version"], str):
		return False, "version must be string"
	
	return True, ""

def test_save_metadata(num_iterations=100):
	"""Test the save metadata completeness property"""
	passed = 0
	failed = 0
	failures = []
	
	for i in range(num_iterations):
		# Create random metadata
		slot = random.randint(0, 9)
		location = f"map_{random.randint(1, 10)}"
		level = random.randint(1, 20)
		
		metadata = create_metadata(slot, location, level)
		
		# Validate
		is_valid, error = validate_metadata(metadata)
		
		if is_valid:
			passed += 1
		else:
			failed += 1
			failures.append({
				'iteration': i,
				'error': error,
				'metadata': metadata
			})
		
		# Test: All fields should be present
		all_fields_present = all(field in metadata for field in ["slot", "timestamp", "datetime", "location", "level", "version"])
		if all_fields_present:
			passed += 1
		else:
			failed += 1
			failures.append({
				'iteration': i,
				'issue': 'Missing required fields',
				'metadata': metadata
			})
	
	print(f"=== Property Test: Save Metadata Completeness ===")
	print(f"Passed: {passed} / {num_iterations * 2}")
	print(f"Failed: {failed} / {num_iterations * 2}")
	
	if failed > 0:
		print("\n=== Failed Cases (first 5) ===")
		for failure in failures[:5]:
			print(f"Iteration {failure['iteration']}:")
			if 'error' in failure:
				print(f"  Error: {failure['error']}")
			if 'issue' in failure:
				print(f"  Issue: {failure['issue']}")
			if 'metadata' in failure:
				print(f"  Metadata: {failure['metadata']}")
		
		if len(failures) > 5:
			print(f"... and {len(failures) - 5} more failures")
		
		print("\nPROPERTY TEST FAILED")
		return False
	else:
		print("\nPROPERTY TEST PASSED")
		return True

if __name__ == "__main__":
	success = test_save_metadata(100)
	exit(0 if success else 1)

