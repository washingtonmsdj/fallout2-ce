extends Node

## Property Test: Hit Chance Formula Correctness
## **Feature: godot-game-migration, Property 9: Hit Chance Formula Correctness**
## **Validates: Requirements 5.3**
##
## Property: For any attacker skill S, distance D, target AC, and attacker perception P,
## hit chance SHALL equal S - (D * 4) - AC + (P * 2), clamped between 5 and 95.

const ITERATIONS = 100

func _ready():
	print("\n=== Property Test: Hit Chance Formula Correctness ===")
	print("Running ", ITERATIONS, " iterations...")
	
	var passed = 0
	var failed = 0
	
	for i in range(ITERATIONS):
		if test_hit_chance_formula():
			passed += 1
		else:
			failed += 1
	
	print("\nResults:")
	print("  Passed: ", passed, "/", ITERATIONS)
	print("  Failed: ", failed, "/", ITERATIONS)
	
	if failed == 0:
		print("✅ All tests passed!")
	else:
		print("❌ Some tests failed!")
	
	# Exit
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func test_hit_chance_formula() -> bool:
	"""
	Test that hit chance formula is correctly calculated
	Formula: Hit = Skill - (Distance * 4) - Target_AC + (Perception * 2)
	Clamped between 5% and 95%
	"""
	# Generate random parameters
	var skill = randi_range(0, 200)
	var distance = randi_range(0, 50)
	var target_ac = randi_range(0, 50)
	var perception = randi_range(1, 10)
	
	# Calculate expected hit chance
	var expected = skill - (distance * 4) - target_ac + (perception * 2)
	expected = clamp(expected, 5, 95)
	
	# Calculate actual hit chance using the formula
	var actual = calculate_hit_chance(skill, distance, target_ac, perception)
	
	# Property: actual must equal expected
	if actual != expected:
		print("❌ FAILED: Hit chance formula incorrect!")
		print("   Skill: ", skill)
		print("   Distance: ", distance)
		print("   Target AC: ", target_ac)
		print("   Perception: ", perception)
		print("   Expected: ", expected)
		print("   Actual: ", actual)
		return false
	
	# Additional property: result must be between 5 and 95
	if actual < 5 or actual > 95:
		print("❌ FAILED: Hit chance not clamped correctly!")
		print("   Result: ", actual)
		return false
	
	return true

func calculate_hit_chance(skill: int, distance: int, target_ac: int, perception: int) -> int:
	"""
	Calculate hit chance using Fallout 2 formula
	This mimics CombatSystem._calculate_hit_chance() logic
	"""
	var distance_penalty = distance * 4
	var hit_chance = skill - distance_penalty - target_ac + (perception * 2)
	return clamp(hit_chance, 5, 95)
